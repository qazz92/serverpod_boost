/// MCP Request - Request types and validation
///
/// This file defines request-specific types and validation for MCP requests.
library serverpod_boost.mcp.mcp_request;

import 'mcp_protocol.dart';
import '../boost_exception.dart';

/// Base class for typed MCP requests
abstract class MCPRequest<T> {
  /// The raw MCP request
  final McpRequest rawRequest;

  MCPRequest(this.rawRequest);

  /// Validate the request parameters
  ///
  /// Throws [ValidationException] if parameters are invalid
  void validate();

  /// Parse the request parameters into the typed result
  T parse();
}

/// Initialize request
///
/// Represents the initialize method call from the MCP protocol
class InitializeRequest extends MCPRequest<InitializeResult> {
  InitializeRequest(super.rawRequest);

  @override
  void validate() {
    // TODO: Implement validation for initialize request
    if (rawRequest.params == null) {
      throw const ValidationException('Initialize request requires params');
    }
  }

  @override
  InitializeResult parse() {
    // TODO: Implement parsing of initialize request
    throw UnimplementedError('Parse initialize request not yet implemented');
  }
}

/// Result of parsing an initialize request
class InitializeResult {
  final String protocolVersion;
  final Map<String, dynamic> capabilities;
  final Map<String, dynamic>? clientInfo;

  InitializeResult({
    required this.protocolVersion,
    required this.capabilities,
    this.clientInfo,
  });
}

/// List tools request
///
/// Represents the tools/list method call from the MCP protocol
class ListToolsRequest extends MCPRequest<void> {
  ListToolsRequest(super.rawRequest);

  @override
  void validate() {
    // List tools typically has no parameters to validate
  }

  @override
  void parse() {
    // No parsing needed for list tools
  }
}

/// Call tool request
///
/// Represents the tools/call method call from the MCP protocol
class CallToolRequest extends MCPRequest<CallToolParams> {
  CallToolRequest(super.rawRequest);

  @override
  void validate() {
    if (rawRequest.params == null) {
      throw const ValidationException('Tool call requires params');
    }

    final params = rawRequest.params!;
    if (!params.containsKey('name')) {
      throw const ValidationException('Tool call requires "name" parameter');
    }
  }

  @override
  CallToolParams parse() {
    // TODO: Implement parsing of tool call request
    throw UnimplementedError('Parse tool call request not yet implemented');
  }
}

/// Parameters for a tool call
class CallToolParams {
  final String name;
  final Map<String, dynamic> arguments;

  CallToolParams({
    required this.name,
    required this.arguments,
  });
}
