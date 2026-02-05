/// ServerPod Boost exceptions
///
/// Custom exceptions for Boost-specific errors.
library serverpod_boost.boost_exception;

/// Base exception for all Boost-related errors
class BoostException implements Exception {
  const BoostException(this.message, [this.cause]);

  final String message;
  final dynamic cause;

  @override
  String toString() => 'BoostException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception for tool execution errors
class ToolException extends BoostException {
  const ToolException(super.message, [super.cause]);
}

/// Exception for MCP protocol errors
class MCPException extends BoostException {
  const MCPException(super.message, [super.cause]);
}

/// Exception for configuration errors
class ConfigurationException extends BoostException {
  const ConfigurationException(super.message, [super.cause]);
}

/// Exception for validation errors
class ValidationException extends BoostException {
  const ValidationException(super.message, [super.cause]);
}
