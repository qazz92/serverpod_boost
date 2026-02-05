/// Dart Tinker Tool
///
/// Execute Dart code in an isolated context for safe code execution.
/// Similar to Laravel's tinker, but with sandboxed execution.
library serverpod_boost.tools.tinker_tool;

import 'dart:async';
import 'dart:isolate';
import 'dart:io';

import '../mcp/mcp_tool.dart';

/// Security configuration for TinkerTool
class TinkerSecurityConfig {
  /// Maximum timeout in seconds
  static const int maxTimeoutSeconds = 30;

  /// Default timeout in seconds
  static const int defaultTimeoutSeconds = 5;

  /// Maximum memory usage in bytes (512MB)
  static const int maxMemoryBytes = 512 * 1024 * 1024;

  /// Environment variable to enable tinker
  static const String enabledEnvVar = 'SERVERPOD_BOOST_TINKER_ENABLED';

  /// Blocked imports that could be dangerous
  static const List<String> blockedImports = [
    'dart:io',
    'dart:html',
    'dart:mirrors',
    'dart:js',
    'dart:js_interop',
  ];

  /// Check if tinker is enabled via environment variable
  static bool isEnabled() {
    final enabled = Platform.environment[enabledEnvVar];
    return enabled?.toLowerCase() == 'true';
  }

  /// Validate code doesn't contain blocked imports
  static String? validateCode(String code) {
    for (final blocked in blockedImports) {
      if (code.contains("import '$blocked'") ||
          code.contains('import "$blocked"') ||
          code.contains("export '$blocked'") ||
          code.contains('export "$blocked"')) {
        return 'Import of $blocked is not allowed for security reasons';
      }
    }
    return null;
  }

  /// Validate timeout parameter
  static String? validateTimeout(int? timeout) {
    if (timeout != null && timeout > maxTimeoutSeconds) {
      return 'Timeout cannot exceed $maxTimeoutSeconds seconds';
    }
    if (timeout != null && timeout < 1) {
      return 'Timeout must be at least 1 second';
    }
    return null;
  }
}

/// Message sent to isolate for execution
class TinkerExecutionMessage {
  const TinkerExecutionMessage({
    required this.code,
    required this.sendPort,
  });

  final String code;
  final String sendPort;

  Map<String, dynamic> toJson() => {
    'code': code,
    'sendPort': sendPort,
  };
}

/// Result from isolate execution
class TinkerExecutionResult {
  const TinkerExecutionResult({
    required this.result,
    required this.output,
    this.error,
    required this.executionTime,
    required this.memoryUsed,
  });

  final dynamic result;
  final String output;
  final String? error;
  final int executionTime;
  final int memoryUsed;

  Map<String, dynamic> toJson() => {
    'result': result?.toString(),
    'output': output,
    if (error != null) 'error': error,
    'executionTime': executionTime,
    'memoryUsed': memoryUsed,
  };
}

/// Isolate entry point for code execution
void _tinkerIsolateEntry(SendPort mainSendPort) {
  // Receive port for this isolate
  final receivePort = ReceivePort();

  // Send send port back to main
  mainSendPort.send(receivePort.sendPort);

  // Listen for execution messages
  receivePort.listen((message) async {
    if (message is Map<String, dynamic>) {
      final code = message['code'] as String;
      final responsePort = message['responsePort'] as SendPort;

      // Capture print output using StringBuffer
      final outputBuffer = StringBuffer();

      dynamic result;
      String? error;
      final stopwatch = Stopwatch()..start();
      int memoryUsed = 0;

      try {
        // Evaluate code using basic evaluation
        // For more complex evaluation, we'd need a proper Dart runtime
        result = await _evaluateCode(code, outputBuffer);

        // Get memory usage
        memoryUsed = ProcessInfo.currentRss;

        stopwatch.stop();

        // Send success result
        responsePort.send(TinkerExecutionResult(
          result: result,
          output: outputBuffer.toString(),
          executionTime: stopwatch.elapsedMilliseconds,
          memoryUsed: memoryUsed,
        ).toJson());
      } catch (e, stackTrace) {
        stopwatch.stop();
        error = '$e\n$stackTrace';
        memoryUsed = ProcessInfo.currentRss;

        // Send error result
        responsePort.send(TinkerExecutionResult(
          result: null,
          output: outputBuffer.toString(),
          error: error,
          executionTime: stopwatch.elapsedMilliseconds,
          memoryUsed: memoryUsed,
        ).toJson());
      }

      // Close receive port after execution
      receivePort.close();
    }
  });
}

/// Evaluate Dart code safely
Future<dynamic> _evaluateCode(String code, StringBuffer output) async {
  // Basic expression evaluation
  // Note: This is a simplified implementation. For full Dart code execution,
  // you would need to use the Dart VM's compile APIs or a similar approach.

  // For now, support basic mathematical and string operations
  try {
    // Try to evaluate as an expression
    if (code.contains('return') || code.contains(';')) {
      // It's a statement, we can't safely eval without a compiler
      throw UnsupportedError(
        'Complex statements not supported in safe mode. '
        'Use simple expressions instead.',
      );
    }

    // For basic arithmetic, we can use eval-like logic
    // This is intentionally limited for security
    if (RegExp(r'^[\d\s\+\-\*\/\(\)\.]+$').hasMatch(code)) {
      // Safe mathematical expression
      return _evalMath(code);
    }

    // For string operations
    if (code.startsWith('"') || code.startsWith("'")) {
      // String literal
      return code.substring(1, code.length - 1);
    }

    // List literal
    if (code.startsWith('[') && code.endsWith(']')) {
      return code; // Return as-is for display
    }

    // Map literal
    if (code.startsWith('{') && code.endsWith('}')) {
      return code; // Return as-is for display
    }

    // Default: return the code as a string representation
    return code;
  } catch (e) {
    throw UnsupportedError(
      'Cannot evaluate code: $e\n'
      'Tinker supports basic arithmetic and string literals. '
      'For complex code, use the ServerPod console directly.',
    );
  }
}

/// Simple math expression evaluator
num _evalMath(String expression) {
  // Remove whitespace
  expression = expression.replaceAll(' ', '');

  // Simple recursive descent parser for basic arithmetic
  return _parseExpression(expression);
}

int _pos = 0;
String _expr = '';

num _parseExpression(String expr) {
  _pos = 0;
  _expr = expr;
  final result = _parseAddSub();
  if (_pos < _expr.length) {
    throw FormatException('Unexpected character at position $_pos');
  }
  return result;
}

num _parseAddSub() {
  var left = _parseMulDiv();
  while (_pos < _expr.length) {
    final char = _expr[_pos];
    if (char == '+') {
      _pos++;
      left = left + _parseMulDiv();
    } else if (char == '-') {
      _pos++;
      left = left - _parseMulDiv();
    } else {
      break;
    }
  }
  return left;
}

num _parseMulDiv() {
  var left = _parseFactor();
  while (_pos < _expr.length) {
    final char = _expr[_pos];
    if (char == '*') {
      _pos++;
      left = left * _parseFactor();
    } else if (char == '/') {
      _pos++;
      left = left / _parseFactor();
    } else {
      break;
    }
  }
  return left;
}

num _parseFactor() {
  if (_pos >= _expr.length) {
    throw const FormatException('Unexpected end of expression');
  }

  // Handle parentheses
  if (_expr[_pos] == '(') {
    _pos++;
    final result = _parseAddSub();
    if (_pos >= _expr.length || _expr[_pos] != ')') {
      throw const FormatException('Missing closing parenthesis');
    }
    _pos++;
    return result;
  }

  // Handle negative numbers
  if (_expr[_pos] == '-') {
    _pos++;
    return -_parseFactor();
  }

  // Parse number
  final start = _pos;
  while (_pos < _expr.length &&
      (_expr[_pos].contains(RegExp(r'\d')) || _expr[_pos] == '.')) {
    _pos++;
  }

  if (_pos == start) {
    throw FormatException('Expected number at position $_pos');
  }

  final numStr = _expr.substring(start, _pos);
  return double.parse(numStr);
}

/// Dart Tinker Tool
///
/// Execute Dart code in an isolated context with safety constraints.
class TinkerTool extends McpToolBase {
  @override
  String get name => 'tinker';

  @override
  String get description => '''
Execute Dart code in an isolated context for quick calculations and testing.

Security features:
- Code runs in a separate isolate
- Timeout enforcement (default 5s, max 30s)
- Memory limits (512MB max)
- Blocked dangerous imports (dart:io, dart:html, dart:mirrors)

Supported operations:
- Basic arithmetic: 2 + 2, 10 * 5, etc.
- String literals: "Hello, World!"
- List literals: [1, 2, 3]
- Map literals: {"key": "value"}

Note: This is a safe evaluation environment, not a full Dart REPL.
For complex operations, use the ServerPod console directly.
  ''';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'code': {
        'type': 'string',
        'description': 'Dart code to execute',
      },
      'timeout': {
        'type': 'number',
        'description':
            'Timeout in seconds (max ${TinkerSecurityConfig.maxTimeoutSeconds}, default ${TinkerSecurityConfig.defaultTimeoutSeconds})',
      },
    },
    'required': ['code'],
  };

  @override
  String? validateParams(Map<String, dynamic>? params) {
    if (params == null) {
      return 'Parameters are required';
    }

    final code = params['code'] as String?;
    if (code == null || code.isEmpty) {
      return 'Code parameter is required';
    }

    // Validate code for blocked imports
    final codeError = TinkerSecurityConfig.validateCode(code);
    if (codeError != null) {
      return codeError;
    }

    // Validate timeout
    final timeout = params['timeout'] as int?;
    final timeoutError = TinkerSecurityConfig.validateTimeout(timeout);
    if (timeoutError != null) {
      return timeoutError;
    }

    return null;
  }

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final code = params['code'] as String;
    final timeoutSec = params['timeout'] as int? ??
        TinkerSecurityConfig.defaultTimeoutSeconds;

    // Check memory before execution
    final initialMemory = ProcessInfo.currentRss;
    if (initialMemory > TinkerSecurityConfig.maxMemoryBytes) {
      return {
        'error': 'Memory limit exceeded',
        'message':
            'Current memory usage (${_formatBytes(initialMemory)}) exceeds limit (${_formatBytes(TinkerSecurityConfig.maxMemoryBytes)})',
        'result': null,
        'output': '',
        'executionTime': 0,
        'memoryUsed': initialMemory,
      };
    }

    try {
      // Execute in isolate with timeout
      final result = await _executeInIsolate(
        code,
        timeoutSec,
      );

      // Check memory after execution
      final finalMemory = ProcessInfo.currentRss;
      if (finalMemory > TinkerSecurityConfig.maxMemoryBytes) {
        return {
          ...result,
          'error': 'Memory limit exceeded during execution',
          'message': 'Execution exceeded memory limit',
        };
      }

      return result;
    } on TimeoutException {
      return {
        'error': 'Execution timeout',
        'message': 'Code execution exceeded $timeoutSec seconds',
        'result': null,
        'output': '',
        'executionTime': timeoutSec * 1000,
        'memoryUsed': ProcessInfo.currentRss,
      };
    } catch (e) {
      return {
        'error': 'Execution failed',
        'message': e.toString(),
        'result': null,
        'output': '',
        'executionTime': 0,
        'memoryUsed': ProcessInfo.currentRss,
      };
    }
  }

  /// Execute code in isolate with timeout
  Future<Map<String, dynamic>> _executeInIsolate(
    String code,
    int timeoutSec,
  ) async {
    final receivePort = ReceivePort();
    final timeout = Duration(seconds: timeoutSec);

    try {
      // Spawn isolate
      await Isolate.spawn(
        _tinkerIsolateEntry,
        receivePort.sendPort,
      );

      // Get the isolate's send port
      final sendPortCompleter = Completer<SendPort>();
      StreamSubscription? subscription;
      subscription = receivePort.listen((message) {
        if (message is SendPort) {
          sendPortCompleter.complete(message);
          subscription?.cancel();
        }
      });

      final isolateSendPort =
          await sendPortCompleter.future.timeout(timeout);
      subscription.cancel();

      // Create response port for the result
      final responsePort = ReceivePort();

      // Send code to isolate
      isolateSendPort.send({
        'code': code,
        'responsePort': responsePort.sendPort,
      });

      // Wait for result with timeout
      final result = await responsePort.first
          .timeout(timeout, onTimeout: () => throw TimeoutException('Execution timed out after $timeoutSec seconds', timeout));

      responsePort.close();

      return Map<String, dynamic>.from(result);
    } on TimeoutException {
      rethrow;
    } finally {
      receivePort.close();
    }
  }

  /// Format bytes to human readable
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Register this tool with the registry
  static void registerAll(McpToolRegistry registry) {
    registry.register(TinkerTool());
  }
}
