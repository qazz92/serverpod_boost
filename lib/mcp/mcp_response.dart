/// MCP Response - Response types and builders
///
/// This file defines response-specific types and helpers for building MCP responses.
library serverpod_boost.mcp.mcp_response;

/// Tool result response
///
/// Represents the result of a tool execution
class ToolResultResponse {
  final String content;
  final bool isError;

  ToolResultResponse({
    required this.content,
    this.isError = false,
  });

  /// Convert to JSON map for MCP response
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'isError': isError,
    };
  }

  /// Create a successful tool result
  factory ToolResultResponse.success(String content) {
    return ToolResultResponse(content: content);
  }

  /// Create an error tool result
  factory ToolResultResponse.error(String message) {
    return ToolResultResponse(content: message, isError: true);
  }
}

/// Tools list response
///
/// Represents the list of available tools
class ToolsListResponse {
  final List<ToolDescription> tools;

  ToolsListResponse({required this.tools});

  /// Convert to JSON map for MCP response
  Map<String, dynamic> toJson() {
    return {
      'tools': tools.map((t) => t.toJson()).toList(),
    };
  }
}

/// Description of a tool
class ToolDescription {
  final String name;
  final String description;
  final Map<String, ToolParameter> inputSchema;

  ToolDescription({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'inputSchema': inputSchema,
    };
  }
}

/// Tool parameter description
class ToolParameter {
  final String type;
  final String description;
  final bool required;

  ToolParameter({
    required this.type,
    required this.description,
    this.required = false,
  });

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'required': required,
    };
  }
}

/// Initialize response
///
/// Represents the response to an initialize request
class InitializeResponse {
  final String protocolVersion;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic>? serverInfo;

  InitializeResponse({
    required this.protocolVersion,
    required this.capabilities,
    this.serverInfo,
  });

  /// Convert to JSON map for MCP response
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'protocolVersion': protocolVersion,
      'capabilities': capabilities,
    };

    if (serverInfo != null) {
      json['serverInfo'] = serverInfo!;
    }

    return json;
  }

  /// Create a standard initialize response
  factory InitializeResponse.standard({
    Map<String, dynamic>? additionalCapabilities,
    Map<String, dynamic>? serverInfo,
  }) {
    final capabilities = {
      'tools': {},
      if (additionalCapabilities != null) ...additionalCapabilities,
    };

    return InitializeResponse(
      protocolVersion: '2024-11-05',
      capabilities: capabilities,
      serverInfo: serverInfo,
    );
  }
}
