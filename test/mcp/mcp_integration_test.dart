/// MCP Server Integration Tests
library serverpod_boost.test.mcp.mcp_integration_test;

import 'dart:async';
import 'package:test/test.dart';

import '../../lib/mcp/mcp_server.dart';
import '../../lib/mcp/mcp_transport.dart';
import '../../lib/mcp/mcp_tool.dart';
import '../../lib/mcp/mcp_protocol.dart';
import '../../lib/tool_registry.dart';

void main() {
  group('MCP Server Integration', () {
    late MCPServer server;
    late MockTransport transport;

    setUp(() {
      transport = MockTransport();
      final registry = McpToolRegistry();
      BoostToolRegistry.registerAll(registry);

      server = MCPServer(
        transport: transport,
        config: MCPServerConfig(
          name: 'test-server',
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

    test('starts and stops correctly', () async {
      expect(server.isRunning, false);
      await server.start();
      expect(server.isRunning, true);
      await server.stop();
      expect(server.isRunning, false);
    });

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
      expect(response.result['protocolVersion'], isNotNull);
      expect(response.result['serverInfo'], isNotNull);
    });

    test('lists available tools', () async {
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

      final listResponse = transport.responses.skip(1).first;
      expect(listResponse.result['tools'], isNotNull);

      final tools = listResponse.result['tools'] as List;
      expect(tools.length, greaterThan(0));

      // Verify essential tools exist
      final toolNames = tools.map((t) => t['name'] as String).toList();
      expect(toolNames, contains('application_info'));
      expect(toolNames, contains('list_endpoints'));
      expect(toolNames, contains('list_models'));
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
    });
  });
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
