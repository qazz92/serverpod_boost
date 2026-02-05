/// MCP Tool interface and base implementations
library;

import 'mcp_protocol.dart';

/// Base interface for all MCP tools
///
/// All tools must implement this interface to be registered with an MCP server.
abstract class McpTool {
  /// Tool name (must be unique across all tools)
  String get name;

  /// Tool description for AI agents
  ///
  /// Should clearly explain what the tool does and when to use it.
  String get description;

  /// Input schema (JSON Schema format)
  ///
  /// Defines the structure of parameters that this tool accepts.
  /// Follows JSON Schema specification (draft-07 or later).
  Map<String, dynamic> get inputSchema;

  /// Execute the tool with given request
  ///
  /// [request] contains the method call with parameters
  /// Returns a response with the result or error
  Future<McpResponse> execute(McpRequest request);

  /// Get tool metadata as a map (for tool listing)
  Map<String, dynamic> get metadata => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
  };

  @override
  String toString() => 'McpTool(name: $name)';
}

/// Base class for tools that simplify implementation
///
/// Provides a template method pattern for easier tool creation.
abstract class McpToolBase implements McpTool {
  @override
  Map<String, dynamic> get metadata => {
    'name': name,
    'description': description,
    'inputSchema': inputSchema,
  };

  @override
  Future<McpResponse> execute(McpRequest request) async {
    try {
      // Validate parameters
      final validationError = validateParams(request.params);
      if (validationError != null) {
        return McpResponse.invalidParams(
          request.id,
          validationError,
        );
      }

      // Execute the tool logic
      final result = await executeImpl(request.params ?? {});

      return McpResponse.result(request.id, result);
    } catch (e) {
      return McpResponse.internalError(
        request.id,
        e.toString(),
      );
    }
  }

  /// Validate parameters before execution
  ///
  /// Return null if valid, or error message if invalid.
  /// Override to provide custom validation logic.
  String? validateParams(Map<String, dynamic>? params) {
    // Default: no validation
    return null;
  }

  /// Implement the actual tool logic
  ///
  /// [params] are the validated parameters (never null here)
  /// Returns the result data to send in the response
  Future<dynamic> executeImpl(Map<String, dynamic> params);
}

/// Simple synchronous tool (for operations that don't need async)
abstract class McpSyncTool extends McpToolBase {
  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    return executeSync(params);
  }

  /// Implement synchronous tool logic
  dynamic executeSync(Map<String, dynamic> params);
}

/// Tool registry for managing multiple tools
class McpToolRegistry {
  final Map<String, McpTool> _tools = {};

  /// Register a tool
  void register(McpTool tool) {
    if (_tools.containsKey(tool.name)) {
      throw ArgumentError('Tool ${tool.name} is already registered');
    }
    _tools[tool.name] = tool;
  }

  /// Unregister a tool by name
  void unregister(String name) {
    _tools.remove(name);
  }

  /// Get a tool by name
  McpTool? getTool(String name) => _tools[name];

  /// Check if a tool exists
  bool hasTool(String name) => _tools.containsKey(name);

  /// List all registered tool names
  List<String> get toolNames => _tools.keys.toList();

  /// List all tool metadata
  List<Map<String, dynamic>> get toolMetadata =>
      _tools.values.map((tool) => tool.metadata).toList();

  /// Execute a tool by name
  Future<McpResponse> execute(String name, McpRequest request) async {
    final tool = getTool(name);
    if (tool == null) {
      return McpResponse.methodNotFound(request.id);
    }
    return tool.execute(request);
  }

  /// Clear all registered tools
  void clear() => _tools.clear();

  /// Get number of registered tools
  int get count => _tools.length;
}

/// Common JSON Schema helpers for tool input schemas
class McpSchema {
  /// Create a string property schema
  static Map<String, dynamic> string({
    String? description,
    bool required = false,
    String? defaultValue,
  }) {
    final schema = <String, dynamic>{
      'type': 'string',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    return schema;
  }

  /// Create a number property schema
  static Map<String, dynamic> number({
    String? description,
    bool required = false,
    num? defaultValue,
  }) {
    final schema = <String, dynamic>{
      'type': 'number',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    return schema;
  }

  /// Create an integer property schema
  static Map<String, dynamic> integer({
    String? description,
    bool required = false,
    int? defaultValue,
  }) {
    final schema = <String, dynamic>{
      'type': 'integer',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    return schema;
  }

  /// Create a boolean property schema
  static Map<String, dynamic> boolean({
    String? description,
    bool required = false,
    bool? defaultValue,
  }) {
    final schema = <String, dynamic>{
      'type': 'boolean',
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    return schema;
  }

  /// Create an object property schema
  static Map<String, dynamic> object({
    String? description,
    Map<String, dynamic>? properties,
    List<String>? required,
    bool additionalProperties = false,
  }) {
    final schema = <String, dynamic>{
      'type': 'object',
      if (description != null) 'description': description,
      if (properties != null) 'properties': properties,
      if (required != null && required.isNotEmpty) 'required': required,
      'additionalProperties': additionalProperties,
    };
    return schema;
  }

  /// Create an array property schema
  static Map<String, dynamic> array({
    String? description,
    required Map<String, dynamic> items,
    bool required = false,
  }) {
    final schema = <String, dynamic>{
      'type': 'array',
      if (description != null) 'description': description,
      'items': items,
    };
    return schema;
  }

  /// Create a complete input schema for a tool
  static Map<String, dynamic> inputSchema({
    required String type,
    Map<String, dynamic>? properties,
    List<String>? required,
    String? description,
  }) {
    final schema = <String, dynamic>{
      'type': type,
      if (description != null) 'description': description,
      if (properties != null) 'properties': properties,
      if (required != null && required.isNotEmpty) 'required': required,
    };
    return schema;
  }

  /// Create an enum property schema
  static Map<String, dynamic> enumProperty({
    required List<String> values,
    String? description,
    bool required = false,
    String? defaultValue,
  }) {
    final schema = <String, dynamic>{
      'type': 'string',
      'enum': values,
      if (description != null) 'description': description,
      if (defaultValue != null) 'default': defaultValue,
    };
    return schema;
  }
}
