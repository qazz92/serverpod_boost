/// MCP Transport layer for stdio communication
library serverpod_boost.mcp.mcp_transport;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'mcp_protocol.dart';

/// Transport interface for MCP communication
abstract class MCPTransport {
  /// Stream of incoming requests
  Stream<McpRequest> get requestStream;

  /// Send a response
  Future<void> sendResponse(McpResponse response);

  /// Send a notification
  Future<void> sendNotification(McpNotification notification);

  /// Start the transport
  Future<void> start();

  /// Stop the transport
  Future<void> stop();

  /// Check if transport is running
  bool get isRunning;
}

/// Stdio transport implementation for MCP
///
/// Reads JSON-RPC messages from stdin and writes to stdout.
/// This is the standard transport for MCP server implementations.
class StdioTransport implements MCPTransport {
  final StreamController<McpRequest> _requestController = StreamController.broadcast();
  StreamSubscription<String>? _stdinSubscription;
  bool _running = false;

  StdioTransport();

  @override
  Stream<McpRequest> get requestStream => _requestController.stream;

  @override
  Future<void> start() async {
    if (_running) return;
    _running = true;

    // Listen to stdin line by line
    _stdinSubscription = stdin
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _handleLine,
          onError: (error) {
            if (_running) {
              stderr.writeln('Stdin error: $error');
            }
          },
          onDone: () {
            if (_running) {
              stop();
            }
          },
          cancelOnError: false,
        );
  }

  void _handleLine(String line) {
    if (!_running || line.trim().isEmpty) return;

    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final request = McpRequest.fromJson(json);
      _requestController.add(request);
    } catch (e) {
      stderr.writeln('Error parsing request: $e');
      // Could send error response here if we had a message ID
    }
  }

  @override
  Future<void> sendResponse(McpResponse response) async {
    if (!_running) {
      throw StateError('Transport is not running');
    }

    final json = response.toJson();
    final line = jsonEncode(json);
    stdout.writeln(line);
  }

  @override
  Future<void> sendNotification(McpNotification notification) async {
    if (!_running) {
      throw StateError('Transport is not running');
    }

    final json = notification.toJson();
    final line = jsonEncode(json);
    stdout.writeln(line);
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    _running = false;

    await _stdinSubscription?.cancel();
    await _requestController.close();
  }

  @override
  bool get isRunning => _running;
}

/// Buffered stdio transport with message queue
///
/// Buffers outgoing messages and handles backpressure.
class BufferedStdioTransport extends StdioTransport {
  final List<Future<void>> _messageQueue = [];
  bool _flushing = false;

  @override
  Future<void> sendResponse(McpResponse response) async {
    final future = super.sendResponse(response);
    _messageQueue.add(future);
    _flushIfNeeded();
  }

  @override
  Future<void> sendNotification(McpNotification notification) async {
    final future = super.sendNotification(notification);
    _messageQueue.add(future);
    _flushIfNeeded();
  }

  void _flushIfNeeded() {
    if (_flushing || _messageQueue.isEmpty) return;

    _flushing = true;
    _flushQueue().whenComplete(() {
      _flushing = false;
    });
  }

  Future<void> _flushQueue() async {
    while (_messageQueue.isNotEmpty) {
      final future = _messageQueue.removeAt(0);
      await future;
    }
  }

  /// Flush all pending messages
  Future<void> flush() => _flushQueue();
}
