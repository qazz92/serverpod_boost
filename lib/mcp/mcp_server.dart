/// MCP Server - Main server implementation
///
/// This class implements the MCP server that handles incoming requests
/// and manages the tool registry.
library serverpod_boost.mcp.mcp_server;

import 'dart:async';

import 'mcp_protocol.dart';
import 'mcp_prompt.dart';
import 'mcp_resource.dart';
import 'mcp_transport.dart';
import 'mcp_tool.dart';
import 'mcp_logger.dart';

/// Server configuration for MCP
class MCPServerConfig {
  /// Server name
  final String name;

  /// Server version
  final String version;

  /// Server protocol version
  final String protocolVersion;

  MCPServerConfig({
    required this.name,
    required this.version,
    this.protocolVersion = '2024-11-05',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'protocolVersion': protocolVersion,
    };
  }
}

/// Main MCP server implementation
class MCPServer {
  final MCPTransport _transport;
  final McpToolRegistry _toolRegistry;
  final McpResourceRegistry _resourceRegistry;
  final McpPromptRegistry _promptRegistry;
  final MCPServerConfig _config;
  final McpLogger _logger;
  bool _running = false;
  bool _initialized = false;
  StreamSubscription<McpRequest>? _requestSubscription;

  MCPServer({
    required MCPTransport transport,
    required MCPServerConfig config,
    McpToolRegistry? toolRegistry,
    McpResourceRegistry? resourceRegistry,
    McpPromptRegistry? promptRegistry,
    McpLogger? logger,
  })  : _transport = transport,
        _config = config,
        _toolRegistry = toolRegistry ?? McpToolRegistry(),
        _resourceRegistry = resourceRegistry ?? McpResourceRegistry(),
        _promptRegistry = promptRegistry ?? McpPromptRegistry(),
        _logger = logger ?? McpLogger.create();

  /// Get the tool registry for adding tools
  McpToolRegistry get tools => _toolRegistry;

  /// Get the resource registry for adding resources
  McpResourceRegistry get resources => _resourceRegistry;

  /// Get the prompt registry for adding prompts
  McpPromptRegistry get prompts => _promptRegistry;

  /// Get server config
  MCPServerConfig get config => _config;

  /// Check if server is running
  bool get isRunning => _running;

  /// Check if server is initialized
  bool get isInitialized => _initialized;

  /// Start the MCP server
  ///
  /// Begins listening for incoming requests and processing them
  Future<void> start() async {
    if (_running) {
      _logger.warning('Server already running');
      return;
    }

    _logger.info('Starting ${_config.name} v${_config.version}...');
    _running = true;

    await _transport.start();
    _logger.debug('Transport started');

    // Listen for incoming requests
    _requestSubscription = _transport.requestStream.listen(
      _handleRequest,
      onError: (error) {
        _logger.error('Request handling error: $error');
      },
      cancelOnError: false,
    );

    _logger.info('Server started with ${_toolRegistry.count} tools, ${_resourceRegistry.count} resources, ${_promptRegistry.count} prompts');
  }

  /// Stop the MCP server
  ///
  /// Gracefully shuts down the server
  Future<void> stop() async {
    if (!_running) {
      _logger.warning('Server not running');
      return;
    }

    _logger.info('Stopping server...');
    _running = false;
    _initialized = false;

    await _requestSubscription?.cancel();
    await _transport.stop();

    _logger.info('Server stopped');
  }

  /// Handle an incoming MCP request
  ///
  /// Parameters:
  /// - [request]: The incoming MCP request to process
  ///
  /// Returns the response for the request
  Future<void> _handleRequest(McpRequest request) async {
    _logger.debug('Received request: ${request.method}');

    McpResponse response;

    try {
      switch (request.method) {
        case 'initialize':
          _logger.debug('Processing initialize');
          response = await _initialize(request);
          break;
        case 'tools/list':
          _logger.debug('Processing tools/list');
          response = await _listTools(request);
          break;
        case 'tools/call':
          final toolName = request.params?['name'] ?? 'unknown';
          _logger.debug('Processing tools/call: $toolName');
          response = await _callTool(request);
          break;
        case 'resources/list':
          _logger.debug('Processing resources/list');
          response = await _listResources(request);
          break;
        case 'resources/read':
          final uri = request.params?['uri'] ?? 'unknown';
          _logger.debug('Processing resources/read: $uri');
          response = await _readResource(request);
          break;
        case 'prompts/list':
          _logger.debug('Processing prompts/list');
          response = await _listPrompts(request);
          break;
        case 'prompts/get':
          final name = request.params?['name'] ?? 'unknown';
          _logger.debug('Processing prompts/get: $name');
          response = await _getPrompt(request);
          break;
        default:
          _logger.warning('Unknown method: ${request.method}');
          response = McpResponse.methodNotFound(request.id);
      }
    } catch (e, stackTrace) {
      _logger.error('Error handling request: $e');
      _logger.debug('Stack trace: $stackTrace');
      response = McpResponse.internalError(request.id, e.toString());
    }

    try {
      await _transport.sendResponse(response);
      _logger.debug('Response sent for ${request.method}');
    } catch (e) {
      _logger.error('Failed to send response: $e');
    }
  }

  /// Initialize the MCP server
  ///
  /// Handles the initialize method from the MCP protocol
  Future<McpResponse> _initialize(McpRequest request) async {
    _logger.info('Initializing server');

    _initialized = true;

    final result = {
      'protocolVersion': _config.protocolVersion,
      'serverInfo': _config.toJson(),
      'capabilities': _getCapabilities(),
    };

    _logger.debug('Server initialized with protocol version ${_config.protocolVersion}');

    return McpResponse.result(request.id, result);
  }

  /// List available tools
  ///
  /// Handles the tools/list method from the MCP protocol
  Future<McpResponse> _listTools(McpRequest request) async {
    if (!_initialized) {
      _logger.warning('Tools/list called before initialization');
      return McpResponse.error(
        request.id,
        -32000,
        'Server not initialized',
      );
    }

    _logger.debug('Listing ${_toolRegistry.count} tools');

    return McpResponse.result(request.id, {
      'tools': _toolRegistry.toolMetadata,
    });
  }

  /// Call a tool
  ///
  /// Handles the tools/call method from the MCP protocol
  Future<McpResponse> _callTool(McpRequest request) async {
    if (!_initialized) {
      _logger.warning('Tool call attempted before initialization');
      return McpResponse.error(
        request.id,
        -32000,
        'Server not initialized',
      );
    }

    final params = request.params;
    if (params == null || !params.containsKey('name')) {
      _logger.warning('Tool call missing tool name parameter');
      return McpResponse.invalidParams(request.id, 'Missing tool name');
    }

    final toolName = params['name'] as String;
    final toolParams = params['arguments'] as Map<String, dynamic>?;

    _logger.debug('Executing tool: $toolName');

    // Create a new request for the tool
    final toolRequest = McpRequest(
      id: request.id,
      method: toolName,
      params: toolParams,
    );

    try {
      final response = await _toolRegistry.execute(toolName, toolRequest);
      _logger.debug('Tool $toolName executed successfully');
      return response;
    } catch (e) {
      _logger.error('Error executing tool $toolName: $e');
      rethrow;
    }
  }

  /// Get server capabilities
  ///
  /// Returns the capabilities supported by this server
  Map<String, dynamic> _getCapabilities() {
    return {
      'tools': {},
      'resources': {},
      'prompts': {},
    };
  }

  /// List available resources
  ///
  /// Handles the resources/list method from the MCP protocol
  Future<McpResponse> _listResources(McpRequest request) async {
    if (!_initialized) {
      _logger.warning('Resources/list called before initialization');
      return McpResponse.error(request.id, -32000, 'Server not initialized');
    }

    _logger.debug('Listing ${_resourceRegistry.count} resources');

    return McpResponse.result(request.id, {
      'resources': _resourceRegistry.resourceMetadata,
    });
  }

  /// Read a resource
  ///
  /// Handles the resources/read method from the MCP protocol
  Future<McpResponse> _readResource(McpRequest request) async {
    if (!_initialized) {
      _logger.warning('Resource read attempted before initialization');
      return McpResponse.error(request.id, -32000, 'Server not initialized');
    }

    final params = request.params;
    if (params == null || !params.containsKey('uri')) {
      _logger.warning('Resource read missing URI parameter');
      return McpResponse.invalidParams(request.id, 'Missing resource URI');
    }

    final uri = params['uri'] as String;

    try {
      _logger.debug('Reading resource: $uri');
      final content = await _resourceRegistry.read(uri);
      return McpResponse.result(request.id, {
        'contents': [
          {
            'uri': uri,
            'text': content,
          }
        ]
      });
    } catch (e) {
      _logger.error('Error reading resource $uri: $e');
      return McpResponse.error(request.id, -32001, 'Resource read failed: $e');
    }
  }

  /// List available prompts
  ///
  /// Handles the prompts/list method from the MCP protocol
  Future<McpResponse> _listPrompts(McpRequest request) async {
    if (!_initialized) {
      _logger.warning('Prompts/list called before initialization');
      return McpResponse.error(request.id, -32000, 'Server not initialized');
    }

    _logger.debug('Listing ${_promptRegistry.count} prompts');

    return McpResponse.result(request.id, {
      'prompts': _promptRegistry.promptMetadata,
    });
  }

  /// Get a prompt
  ///
  /// Handles the prompts/get method from the MCP protocol
  Future<McpResponse> _getPrompt(McpRequest request) async {
    if (!_initialized) {
      _logger.warning('Prompt get attempted before initialization');
      return McpResponse.error(request.id, -32000, 'Server not initialized');
    }

    final params = request.params;
    if (params == null || !params.containsKey('name')) {
      _logger.warning('Prompt get missing name parameter');
      return McpResponse.invalidParams(request.id, 'Missing prompt name');
    }

    final name = params['name'] as String;
    final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

    try {
      _logger.debug('Generating prompt: $name');
      final prompt = await _promptRegistry.generate(name, arguments);
      final promptDef = _promptRegistry.getPrompt(name);

      return McpResponse.result(request.id, {
        'description': promptDef?.description ?? '',
        'messages': [
          {
            'role': 'user',
            'content': {
              'type': 'text',
              'text': prompt,
            }
          }
        ]
      });
    } catch (e) {
      _logger.error('Error generating prompt $name: $e');
      return McpResponse.error(
          request.id, -32002, 'Prompt generation failed: $e');
    }
  }
}
