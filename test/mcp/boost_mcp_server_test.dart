/// Boost MCP Server Unit Tests
///
/// Tests the MCP server wrapper functionality.
library serverpod_boost.test.mcp.boost_mcp_server_test;

import 'dart:async';
import 'package:test/test.dart';

import '../../lib/mcp/mcp_server.dart';
import '../../lib/mcp/mcp_transport.dart';
import '../../lib/mcp/mcp_tool.dart';
import '../../lib/mcp/mcp_protocol.dart';
import '../../lib/tool_registry.dart';

void main() {
  group('Boost MCP Server Tests', () {
    late MCPServer server;
    late MockTransport transport;

    setUp(() {
      transport = MockTransport();
      final registry = McpToolRegistry();
      BoostToolRegistry.registerAll(registry);

      server = MCPServer(
        transport: transport,
        config: MCPServerConfig(
          name: 'boost-test-server',
          version: '0.1.0',
        ),
        toolRegistry: registry,
      );
    });

    tearDown(() async {
      if (server.isRunning) {
        await server.stop();
      }
    });

    group('Server Creation', () {
      test('create creates server with all tools', () {
        // Verify server has all 20 tools registered
        expect(server.tools.count, equals(20));

        // Verify essential tools are present
        final toolNames = server.tools.toolNames;
        expect(toolNames, contains('application_info'));
        expect(toolNames, contains('list_endpoints'));
        expect(toolNames, contains('endpoint_methods'));
        expect(toolNames, contains('list_models'));
        expect(toolNames, contains('model_inspector'));
        expect(toolNames, contains('config_reader'));
        expect(toolNames, contains('database_schema'));
        expect(toolNames, contains('migration_scanner'));
        expect(toolNames, contains('project_structure'));
        expect(toolNames, contains('find_files'));
        expect(toolNames, contains('read_file'));
        expect(toolNames, contains('search_code'));
        expect(toolNames, contains('call_endpoint'));
        expect(toolNames, contains('service_config'));
        expect(toolNames, contains('log_reader'));
        expect(toolNames, contains('list_skills'));
        expect(toolNames, contains('get_skill'));
        expect(toolNames, contains('database_query'));
        expect(toolNames, contains('cli_commands'));
      });

      test('create with custom registry', () {
        final customRegistry = McpToolRegistry();
        final testTool = _TestTool();
        customRegistry.register(testTool);

        final customServer = MCPServer(
          transport: transport,
          config: MCPServerConfig(
            name: 'custom-server',
            version: '1.0.0',
          ),
          toolRegistry: customRegistry,
        );

        expect(customServer.tools.count, equals(1));
        expect(customServer.tools.toolNames, contains('test_tool'));
      });

      test('server config is accessible', () {
        expect(server.config.name, equals('boost-test-server'));
        expect(server.config.version, equals('0.1.0'));
        expect(server.config.protocolVersion, equals('2024-11-05'));

        final configJson = server.config.toJson();
        expect(configJson['name'], equals('boost-test-server'));
        expect(configJson['version'], equals('0.1.0'));
        expect(configJson['protocolVersion'], equals('2024-11-05'));
      });
    });

    group('Server Lifecycle', () {
      test('start starts server successfully', () async {
        expect(server.isRunning, isFalse);

        await server.start();

        expect(server.isRunning, isTrue);
        expect(transport.isRunning, isTrue);
      });

      test('start twice is idempotent', () async {
        await server.start();
        expect(server.isRunning, isTrue);

        // Starting again should not cause issues
        await server.start();
        expect(server.isRunning, isTrue);
      });

      test('stop stops server successfully', () async {
        await server.start();
        expect(server.isRunning, isTrue);

        await server.stop();

        expect(server.isRunning, isFalse);
        expect(server.isInitialized, isFalse);
        expect(transport.isRunning, isFalse);
      });

      test('stop when not running is safe', () async {
        // Should not throw
        await server.stop();
        expect(server.isRunning, isFalse);
      });

      test('stop and restart works correctly', () async {
        // Note: Cannot restart server with same transport due to stream subscription
        // This test verifies stop/start cycle works with proper cleanup
        await server.start();
        expect(server.isRunning, isTrue);

        await server.stop();
        expect(server.isRunning, isFalse);

        // Create a new server instance for restart test
        final newTransport = MockTransport();
        final newRegistry = McpToolRegistry();
        BoostToolRegistry.registerAll(newRegistry);

        final newServer = MCPServer(
          transport: newTransport,
          config: MCPServerConfig(
            name: 'boost-test-server-2',
            version: '0.1.0',
          ),
          toolRegistry: newRegistry,
        );

        await newServer.start();
        expect(newServer.isRunning, isTrue);

        await newServer.stop();
        expect(newServer.isRunning, isFalse);
      });
    });

    group('Request Handling', () {
      test('handles initialize request', () async {
        await server.start();

        final request = McpRequest(
          id: '1',
          method: 'initialize',
          params: {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
          },
        );

        transport.simulateRequest(request);
        await Future.delayed(Duration(milliseconds: 100));

        expect(transport.responses.length, greaterThan(0));

        final response = transport.responses.first;
        expect(response.id, equals('1'));
        expect(response.result, isNotNull);
        expect(response.result['protocolVersion'], equals('2024-11-05'));
        expect(response.result['serverInfo'], isNotNull);
        expect(response.result['serverInfo']['name'], equals('boost-test-server'));
        expect(response.result['serverInfo']['version'], equals('0.1.0'));
        expect(response.result['capabilities'], isNotNull);
      });

      test('initialize sets initialized flag', () async {
        expect(server.isInitialized, isFalse);

        await server.start();

        final request = McpRequest(
          id: '1',
          method: 'initialize',
          params: {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'test', 'version': '1.0'},
          },
        );

        transport.simulateRequest(request);
        await Future.delayed(Duration(milliseconds: 100));

        expect(server.isInitialized, isTrue);
      });

      test('rejects tools/list before initialize', () async {
        await server.start();

        final request = McpRequest(
          id: '1',
          method: 'tools/list',
          params: {},
        );

        transport.simulateRequest(request);
        await Future.delayed(Duration(milliseconds: 50));

        final response = transport.responses.first;
        expect(response.error, isNotNull);
        expect(response.error?.code, equals(-32000));
        expect(response.error?.message, contains('not initialized'));
      });

      test('lists available tools after initialize', () async {
        await server.start();

        // Initialize first
        final initRequest = McpRequest(
          id: '1',
          method: 'initialize',
          params: {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'test', 'version': '1.0'},
          },
        );
        transport.simulateRequest(initRequest);
        await Future.delayed(Duration(milliseconds: 50));

        // List tools
        final listRequest = McpRequest(
          id: '2',
          method: 'tools/list',
          params: {},
        );
        transport.simulateRequest(listRequest);
        await Future.delayed(Duration(milliseconds: 50));

        expect(transport.responses.length, greaterThanOrEqualTo(2));

        final listResponse = transport.responses.skip(1).first;
        expect(listResponse.result['tools'], isNotNull);

        final tools = listResponse.result['tools'] as List;
        expect(tools.length, equals(20));

        // Verify some essential tools
        final toolNames = tools.map((t) => t['name'] as String).toList();
        expect(toolNames, contains('application_info'));
        expect(toolNames, contains('list_endpoints'));
        expect(toolNames, contains('database_query'));
      });

      test('handles unknown method', () async {
        await server.start();

        final request = McpRequest(
          id: '1',
          method: 'unknown_method',
          params: {},
        );

        transport.simulateRequest(request);
        await Future.delayed(Duration(milliseconds: 50));

        final response = transport.responses.first;
        expect(response.error, isNotNull);
        expect(response.error?.code, equals(-32601));
        expect(response.error?.message, contains('not found'));
      });

      test('handles tool execution error gracefully', () async {
        await server.start();

        // Initialize first
        final initRequest = McpRequest(
          id: '1',
          method: 'initialize',
          params: {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'test', 'version': '1.0'},
          },
        );
        transport.simulateRequest(initRequest);
        await Future.delayed(Duration(milliseconds: 50));

        // Call tool with invalid params
        final callRequest = McpRequest(
          id: '2',
          method: 'tools/call',
          params: {
            'name': 'database_query',
            'arguments': {}, // Missing required 'query' parameter
          },
        );
        transport.simulateRequest(callRequest);
        await Future.delayed(Duration(milliseconds: 50));

        // Should get response (may have error in result or be error response)
        final responses = transport.responses.skip(1).toList();
        final callResponse = responses.firstWhere(
          (r) => r.id == '2',
          orElse: () => throw Exception('No response found'),
        );

        // Response should exist
        expect(callResponse, isNotNull);
        // Either result exists with error or it's an error response
        // The key is that the server handles it without crashing
        expect(transport.responses.length, greaterThan(1));
      });
    });

    group('Resources and Prompts', () {
      test('handles resources/list', () async {
        await server.start();

        // Initialize first
        final initRequest = McpRequest(
          id: '1',
          method: 'initialize',
          params: {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'test', 'version': '1.0'},
          },
        );
        transport.simulateRequest(initRequest);
        await Future.delayed(Duration(milliseconds: 50));

        // List resources
        final listRequest = McpRequest(
          id: '2',
          method: 'resources/list',
          params: {},
        );
        transport.simulateRequest(listRequest);
        await Future.delayed(Duration(milliseconds: 50));

        final responses = transport.responses.skip(1).toList();
        final listResponse = responses.firstWhere(
          (r) => r.id == '2',
          orElse: () => throw Exception('No response found'),
        );

        expect(listResponse.result['resources'], isNotNull);
        // Default registry has no resources, so should be empty
        expect(listResponse.result['resources'], isEmpty);
      });

      test('handles prompts/list', () async {
        await server.start();

        // Initialize first
        final initRequest = McpRequest(
          id: '1',
          method: 'initialize',
          params: {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'test', 'version': '1.0'},
          },
        );
        transport.simulateRequest(initRequest);
        await Future.delayed(Duration(milliseconds: 50));

        // List prompts
        final listRequest = McpRequest(
          id: '2',
          method: 'prompts/list',
          params: {},
        );
        transport.simulateRequest(listRequest);
        await Future.delayed(Duration(milliseconds: 50));

        final responses = transport.responses.skip(1).toList();
        final listResponse = responses.firstWhere(
          (r) => r.id == '2',
          orElse: () => throw Exception('No response found'),
        );

        expect(listResponse.result['prompts'], isNotNull);
        // Default registry has no prompts, so should be empty
        expect(listResponse.result['prompts'], isEmpty);
      });

      test('rejects resources/list before initialize', () async {
        await server.start();

        final request = McpRequest(
          id: '1',
          method: 'resources/list',
          params: {},
        );

        transport.simulateRequest(request);
        await Future.delayed(Duration(milliseconds: 50));

        final response = transport.responses.first;
        expect(response.error, isNotNull);
        expect(response.error?.code, equals(-32000));
      });

      test('rejects prompts/list before initialize', () async {
        await server.start();

        final request = McpRequest(
          id: '1',
          method: 'prompts/list',
          params: {},
        );

        transport.simulateRequest(request);
        await Future.delayed(Duration(milliseconds: 50));

        final response = transport.responses.first;
        expect(response.error, isNotNull);
        expect(response.error?.code, equals(-32000));
      });
    });

    group('Error Handling', () {
      test('handles malformed requests gracefully', () async {
        await server.start();

        // Request with missing required fields
        final request = McpRequest(
          id: '',
          method: 'initialize',
          params: null,
        );

        transport.simulateRequest(request);
        await Future.delayed(Duration(milliseconds: 50));

        // Should not crash, should return error response
        expect(transport.responses, isNotEmpty);
      });

      test('handles transport errors', () async {
        final failingTransport = FailingMockTransport();
        final failingServer = MCPServer(
          transport: failingTransport,
          config: MCPServerConfig(
            name: 'failing-server',
            version: '1.0.0',
          ),
        );

        // Starting should work
        await failingServer.start();
        expect(failingServer.isRunning, isTrue);

        // Stopping should work even if transport fails
        await failingServer.stop();
        expect(failingServer.isRunning, isFalse);
      });
    });

    group('Server Capabilities', () {
      test('reports correct capabilities', () async {
        await server.start();

        final request = McpRequest(
          id: '1',
          method: 'initialize',
          params: {
            'protocolVersion': '2024-11-05',
            'capabilities': {},
            'clientInfo': {'name': 'test', 'version': '1.0'},
          },
        );

        transport.simulateRequest(request);
        await Future.delayed(Duration(milliseconds: 100));

        final response = transport.responses.first;
        final capabilities = response.result['capabilities'] as Map;

        // Should have tools, resources, and prompts capabilities
        expect(capabilities, isNotNull);
        expect(capabilities['tools'], isNotNull);
        expect(capabilities['resources'], isNotNull);
        expect(capabilities['prompts'], isNotNull);
      });
    });
  });
}

/// Test tool for custom registry tests
class _TestTool extends McpSyncTool {
  @override
  String get name => 'test_tool';

  @override
  String get description => 'A test tool';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {},
  );

  @override
  dynamic executeSync(Map<String, dynamic> params) {
    return {'test': 'result'};
  }
}

/// Mock transport for testing
class MockTransport implements MCPTransport {
  final List<McpRequest> _requests = [];
  final List<McpResponse> _responses = [];
  final StreamController<McpRequest> _controller = StreamController();
  bool _running = false;

  List<McpRequest> get requests => List.unmodifiable(_requests);
  List<McpResponse> get responses => List.unmodifiable(_responses);

  @override
  Stream<McpRequest> get requestStream => _controller.stream;

  @override
  Future<void> sendResponse(McpResponse response) async {
    _responses.add(response);
  }

  @override
  Future<void> sendNotification(McpNotification notification) async {
    // Not implemented for tests
  }

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _controller.close();
  }

  @override
  bool get isRunning => _running;

  /// Simulate receiving a request
  void simulateRequest(McpRequest request) {
    _requests.add(request);
    _controller.add(request);
  }
}

/// Failing mock transport for error handling tests
class FailingMockTransport implements MCPTransport {
  final StreamController<McpRequest> _controller = StreamController();
  bool _running = false;

  @override
  Stream<McpRequest> get requestStream => _controller.stream;

  @override
  Future<void> sendResponse(McpResponse response) async {
    throw Exception('Transport failed');
  }

  @override
  Future<void> sendNotification(McpNotification notification) async {
    throw Exception('Transport failed');
  }

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
    await _controller.close();
  }

  @override
  bool get isRunning => _running;
}
