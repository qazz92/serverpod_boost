/// MCP Logger
///
/// Provides structured logging for MCP server operations with configurable
/// log levels and colored output support.
library serverpod_boost.mcp.mcp_logger;

import 'dart:io';

/// Log levels for MCP logger
enum McpLogLevel { debug, info, warning, error }

/// MCP Logger with configurable levels and colored output
class McpLogger {
  /// Current log level
  final McpLogLevel level;

  /// Whether to use colored output
  final bool useColors;

  /// Output sink for logs
  final IOSink output;

  McpLogger({
    this.level = McpLogLevel.info,
    this.useColors = true,
    IOSink? output,
  }) : output = output ?? stderr;

  /// Get ANSI color code for log level
  String _getLevelColor(McpLogLevel level) {
    switch (level) {
      case McpLogLevel.debug:
        return '\x1B[36m'; // Cyan
      case McpLogLevel.info:
        return '\x1B[32m'; // Green
      case McpLogLevel.warning:
        return '\x1B[33m'; // Yellow
      case McpLogLevel.error:
        return '\x1B[31m'; // Red
    }
  }

  /// Log a message at the specified level
  void log(McpLogLevel level, String message) {
    if (level.index < this.level.index) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final color = _getLevelColor(level);

    if (useColors) {
      output.writeln('$color[$timestamp] [$levelStr] $message\x1B[0m');
    } else {
      output.writeln('[$timestamp] [$levelStr] $message');
    }
  }

  /// Log a debug message
  void debug(String message) => log(McpLogLevel.debug, message);

  /// Log an info message
  void info(String message) => log(McpLogLevel.info, message);

  /// Log a warning message
  void warning(String message) => log(McpLogLevel.warning, message);

  /// Log an error message
  void error(String message) => log(McpLogLevel.error, message);

  /// Create a logger from environment variables
  ///
  /// Reads configuration from:
  /// - SERVERPOD_BOOST_LOG_LEVEL: debug, info, warning, error (default: info)
  /// - SERVERPOD_BOOST_NO_COLOR: set to 'true' to disable colors
  static McpLogger create() {
    final levelStr = Platform.environment['SERVERPOD_BOOST_LOG_LEVEL'] ?? 'info';
    McpLogLevel level;

    switch (levelStr.toLowerCase()) {
      case 'debug':
        level = McpLogLevel.debug;
        break;
      case 'info':
        level = McpLogLevel.info;
        break;
      case 'warning':
        level = McpLogLevel.warning;
        break;
      case 'error':
        level = McpLogLevel.error;
        break;
      default:
        level = McpLogLevel.info;
    }

    return McpLogger(
      level: level,
      useColors: Platform.environment['SERVERPOD_BOOST_NO_COLOR'] != 'true',
    );
  }
}
