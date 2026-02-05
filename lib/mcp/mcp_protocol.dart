/// MCP Protocol implementation based on JSON-RPC 2.0
///
/// This file contains the core type definitions for the Model Context Protocol (MCP),
/// which follows the JSON-RPC 2.0 specification.
library;

/// JSON-RPC 2.0 protocol constants
class McpProtocol {
  static const String jsonRpcVersion = '2.0';
  static const String contentType = 'application/json';

  // Error codes (as per JSON-RPC 2.0 spec)
  static const int errorParseError = -32700;
  static const int errorInvalidRequest = -32600;
  static const int errorMethodNotFound = -32601;
  static const int errorInvalidParams = -32602;
  static const int errorInternalError = -32603;

  // Server error start
  static const int serverErrorStart = -32099;
  static const int serverErrorEnd = -32000;
}

/// MCP Request wrapper
///
/// Represents a JSON-RPC 2.0 request object with an ID, method name, and optional parameters.
class McpRequest {
  /// Unique request identifier (string for simplicity)
  final String id;

  /// Method name to invoke
  final String method;

  /// Optional parameters object
  final Map<String, dynamic>? params;

  McpRequest({
    required this.id,
    required this.method,
    this.params,
  });

  /// Create request from JSON map
  factory McpRequest.fromJson(Map<String, dynamic> json) {
    return McpRequest(
      id: json['id'] as String,
      method: json['method'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  /// Create request for a method call
  factory McpRequest.call(String method, {Map<String, dynamic>? params}) {
    return McpRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      params: params,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': McpProtocol.jsonRpcVersion,
      'id': id,
      'method': method,
      if (params != null) 'params': params,
    };
  }

  /// Convert to JSON string
  String toJsonString() {
    return toJson().toString();
  }

  @override
  String toString() {
    return 'McpRequest(id: $id, method: $method, params: $params)';
  }
}

/// MCP Response wrapper
///
/// Represents a JSON-RPC 2.0 response object with either a result or an error.
class McpResponse {
  /// Request ID this response corresponds to
  final String id;

  /// Successful result data (null if error)
  final dynamic result;

  /// Error data (null if successful)
  final McpError? error;

  McpResponse({
    required this.id,
    this.result,
    this.error,
  }) : assert(result != null || error != null, 'Either result or error must be provided');

  /// Create a successful response
  factory McpResponse.result(String id, dynamic result) {
    return McpResponse(
      id: id,
      result: result,
    );
  }

  /// Create a response with data and default ID
  factory McpResponse.fromData(dynamic result) {
    return McpResponse(
      id: '1', // default ID
      result: result,
    );
  }

  /// Create an error response
  factory McpResponse.error(String id, int code, String message, {String? data}) {
    return McpResponse(
      id: id,
      error: McpError(code: code, message: message, data: data),
    );
  }

  /// Create a parse error response
  factory McpResponse.parseError(String id) {
    return McpResponse.error(
      id,
      McpProtocol.errorParseError,
      'Parse error',
    );
  }

  /// Create an invalid request error response
  factory McpResponse.invalidRequest(String id) {
    return McpResponse.error(
      id,
      McpProtocol.errorInvalidRequest,
      'Invalid Request',
    );
  }

  /// Create a method not found error response
  factory McpResponse.methodNotFound(String id) {
    return McpResponse.error(
      id,
      McpProtocol.errorMethodNotFound,
      'Method not found',
    );
  }

  /// Create an invalid params error response
  factory McpResponse.invalidParams(String id, String detail) {
    return McpResponse.error(
      id,
      McpProtocol.errorInvalidParams,
      'Invalid params: $detail',
    );
  }

  /// Create an internal error response
  factory McpResponse.internalError(String id, String message) {
    return McpResponse.error(
      id,
      McpProtocol.errorInternalError,
      'Internal error: $message',
    );
  }

  /// Check if response is successful
  bool get isSuccess => error == null;

  /// Check if response is an error
  bool get isError => error != null;

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    if (error != null) {
      return {
        'jsonrpc': McpProtocol.jsonRpcVersion,
        'id': id,
        'error': error!.toJson(),
      };
    }
    return {
      'jsonrpc': McpProtocol.jsonRpcVersion,
      'id': id,
      'result': result,
    };
  }

  /// Create response from JSON map
  factory McpResponse.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final errorJson = json['error'] as Map<String, dynamic>?;

    if (errorJson != null) {
      return McpResponse(
        id: id,
        error: McpError.fromJson(errorJson),
      );
    }

    return McpResponse(
      id: id,
      result: json['result'],
    );
  }

  @override
  String toString() {
    if (error != null) {
      return 'McpResponse(id: $id, error: $error)';
    }
    return 'McpResponse(id: $id, result: $result)';
  }
}

/// MCP Error
///
/// Represents a JSON-RPC 2.0 error object with code, message, and optional data.
class McpError {
  /// Error code (integer)
  final int code;

  /// Error message (human-readable)
  final String message;

  /// Additional error data (optional)
  final String? data;

  McpError({
    required this.code,
    required this.message,
    this.data,
  });

  /// Create error from JSON map
  factory McpError.fromJson(Map<String, dynamic> json) {
    return McpError(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'] as String?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      if (data != null) 'data': data,
    };
  }

  @override
  String toString() {
    if (data != null) {
      return 'McpError(code: $code, message: $message, data: $data)';
    }
    return 'McpError(code: $code, message: $message)';
  }
}

/// MCP Notification (request without ID)
///
/// Represents a JSON-RPC notification - a request that doesn't expect a response.
class McpNotification {
  /// Method name
  final String method;

  /// Optional parameters
  final Map<String, dynamic>? params;

  McpNotification({
    required this.method,
    this.params,
  });

  /// Create notification from JSON map
  factory McpNotification.fromJson(Map<String, dynamic> json) {
    return McpNotification(
      method: json['method'] as String,
      params: json['params'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'jsonrpc': McpProtocol.jsonRpcVersion,
      'method': method,
      if (params != null) 'params': params,
    };
  }

  @override
  String toString() {
    return 'McpNotification(method: $method, params: $params)';
  }
}
