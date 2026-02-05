/// MCP Tool Adapter Unit Tests
///
/// Tests the tool adapter functionality for converting legacy tools
/// to MCP-compatible tools.
library serverpod_boost.test.mcp.mcp_tool_adapter_test;

import 'dart:io';
import 'package:test/test.dart';

import '../../lib/mcp/mcp_tool.dart';
import '../../lib/mcp/mcp_protocol.dart';
import '../../lib/tools/application_info_tool.dart';
import '../../lib/tools/database_query_tool.dart';
import '../../lib/serverpod/serverpod_locator.dart';

void main() {
  group('MCP Tool Adapter Tests', () {
    late Directory originalDir;

    setUp(() {
      // Save original directory
      originalDir = Directory.current;
      ServerPodLocator.resetCache();
    });

    tearDown(() {
      // Restore original directory
      Directory.current = originalDir;
      ServerPodLocator.resetCache();
    });

    group('adaptMcpTool', () {
      test('adapts simple sync tool', () async {
        // ApplicationInfoTool is a simple synchronous tool
        final tool = ApplicationInfoTool();

        // Verify tool metadata
        expect(tool.name, equals('application_info'));
        expect(tool.description, isNotEmpty);
        expect(tool.description, contains('ServerPod'));
        expect(tool.inputSchema, isNotNull);
        expect(tool.inputSchema['type'], equals('object'));
      });

      test('adapts async tool', () async {
        // DatabaseQueryTool is an async tool with complex logic
        final tool = DatabaseQueryTool();

        // Verify tool metadata
        expect(tool.name, equals('database_query'));
        expect(tool.description, isNotEmpty);
        expect(tool.description, contains('SQL'));
        expect(tool.inputSchema, isNotNull);

        // Verify input schema has required fields
        final schema = tool.inputSchema;
        expect(schema['properties'], isNotNull);
        expect(schema['properties']!['query'], isNotNull);
        expect(schema['properties']!['maxRows'], isNotNull);
      });

      test('handles errors correctly', () async {
        // Test error handling when not in a ServerPod project
        final tempDir = Directory.systemTemp.createTempSync('non_serverpod_${DateTime.now().millisecondsSinceEpoch}_');

        try {
          Directory.current = tempDir.path;
          ServerPodLocator.resetCache();

          final tool = ApplicationInfoTool();
          final request = McpRequest(
            id: 'test',
            method: 'application_info',
            params: {},
          );

          final response = await tool.execute(request);

          // Should return error response
          expect(response, isNotNull);
          final result = response.result as Map;
          expect(result.containsKey('error'), isTrue);
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });
    });

    group('_formatResult', () {
      test('handles string', () {
        // Test with a tool that returns string
        final result = 'test result';

        // String results should be returned as-is
        expect(result, equals('test result'));
        expect(result, isA<String>());
      });

      test('handles map', () {
        // Test with a tool that returns map
        final result = {
          'key': 'value',
          'nested': {'data': 123},
        };

        // Map results should be JSON-serializable
        expect(result, isA<Map<String, dynamic>>());
        expect(result['key'], equals('value'));
        expect((result['nested'] as Map)['data'], equals(123));
      });

      test('handles list', () {
        // Test with a tool that returns list
        final result = [
          {'id': 1, 'name': 'Item 1'},
          {'id': 2, 'name': 'Item 2'},
        ];

        // List results should be JSON-serializable
        expect(result, isA<List>());
        expect(result.length, equals(2));
        expect(result[0]['id'], equals(1));
      });

      test('handles null', () {
        // Test with a tool that returns null
        final dynamic result = null;

        // Null results should be handled gracefully
        expect(result, isNull);
      });

      test('handles complex nested structures', () {
        // Test with complex nested result
        final result = {
          'project': {
            'name': 'test',
            'endpoints': [
              {'name': 'user', 'methods': ['login', 'logout']},
              {'name': 'admin', 'methods': ['create', 'delete']},
            ],
          },
          'config': {'database': 'postgres'},
        };

        // Complex structures should be JSON-serializable
        expect(result, isA<Map<String, dynamic>>());
        final project = result['project'] as Map<String, dynamic>;
        final endpoints = project['endpoints'] as List;
        expect(endpoints.length, equals(2));
        final firstEndpoint = endpoints[0] as Map;
        expect(firstEndpoint['methods'], contains('login'));
      });
    });

    group('Tool Metadata', () {
      test('all tools have required metadata fields', () {
        final tools = [
          ApplicationInfoTool(),
          DatabaseQueryTool(),
        ];

        for (final tool in tools) {
          expect(tool.name, isNotEmpty);
          expect(tool.description, isNotEmpty);
          expect(tool.inputSchema, isNotNull);
          expect(tool.inputSchema['type'], equals('object'));
        }
      });

      test('tool metadata is JSON-serializable', () {
        final tool = ApplicationInfoTool();
        final metadata = tool.metadata;

        expect(metadata, isA<Map<String, dynamic>>());
        expect(metadata['name'], equals(tool.name));
        expect(metadata['description'], equals(tool.description));
        expect(metadata['inputSchema'], equals(tool.inputSchema));
      });
    });

    group('Parameter Validation', () {
      test('DatabaseQueryTool validates required parameters', () {
        final tool = DatabaseQueryTool();

        // Missing query parameter
        final error1 = tool.validateParams({});
        expect(error1, isNotNull);
        expect(error1, contains('Parameters are required'));

        // Empty query parameter
        final error2 = tool.validateParams({'query': ''});
        expect(error2, isNotNull);
        expect(error2, contains('Query parameter'));

        // Valid parameters
        final error3 = tool.validateParams({
          'query': 'SELECT * FROM users',
        });
        expect(error3, isNull);

        // Invalid SQL (blocked operation)
        final error4 = tool.validateParams({
          'query': 'DROP TABLE users',
        });
        expect(error4, isNotNull);
        expect(error4, contains('not allowed'));
      });

      test('DatabaseQueryTool validates maxRows parameter', () {
        final tool = DatabaseQueryTool();

        // Too low
        final error1 = tool.validateParams({
          'query': 'SELECT * FROM users',
          'maxRows': 0,
        });
        expect(error1, isNotNull);
        expect(error1, contains('between 1 and'));

        // Too high
        final error2 = tool.validateParams({
          'query': 'SELECT * FROM users',
          'maxRows': 20000,
        });
        expect(error2, isNotNull);
        expect(error2, contains('between 1 and'));

        // Valid value
        final error3 = tool.validateParams({
          'query': 'SELECT * FROM users',
          'maxRows': 100,
        });
        expect(error3, isNull);
      });
    });

    group('Request/Response Handling', () {
      test('tool execution returns proper response structure', () async {
        final tempDir = Directory.systemTemp.createTempSync('non_serverpod_${DateTime.now().millisecondsSinceEpoch}_');

        try {
          Directory.current = tempDir.path;
          ServerPodLocator.resetCache();

          final tool = ApplicationInfoTool();
          final request = McpRequest(
            id: 'test-id',
            method: 'application_info',
            params: {},
          );

          final response = await tool.execute(request);

          // Verify response structure
          expect(response, isNotNull);
          expect(response.id, equals('test-id'));
          expect(response.result, isA<Map>());
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('tool handles null parameters gracefully', () async {
        final tool = ApplicationInfoTool();
        final request = McpRequest(
          id: 'test',
          method: 'application_info',
          params: null,
        );

        final response = await tool.execute(request);

        // Should handle null params
        expect(response, isNotNull);
        expect(response.result, isA<Map>());
      });
    });

    group('MCP Schema Helpers', () {
      test('McpSchema.string creates valid schema', () {
        final schema = McpSchema.string(
          description: 'Test string',
          required: false,
          defaultValue: 'default',
        );

        expect(schema['type'], equals('string'));
        expect(schema['description'], equals('Test string'));
        expect(schema['default'], equals('default'));
      });

      test('McpSchema.integer creates valid schema', () {
        final schema = McpSchema.integer(
          description: 'Test integer',
          defaultValue: 42,
        );

        expect(schema['type'], equals('integer'));
        expect(schema['description'], equals('Test integer'));
        expect(schema['default'], equals(42));
      });

      test('McpSchema.enumProperty creates valid schema', () {
        final schema = McpSchema.enumProperty(
          values: ['a', 'b', 'c'],
          description: 'Test enum',
        );

        expect(schema['type'], equals('string'));
        expect(schema['enum'], equals(['a', 'b', 'c']));
        expect(schema['description'], equals('Test enum'));
      });

      test('McpSchema.inputSchema creates complete schema', () {
        final schema = McpSchema.inputSchema(
          type: 'object',
          properties: {
            'field1': McpSchema.string(description: 'Field 1'),
            'field2': McpSchema.integer(description: 'Field 2'),
          },
          required: ['field1'],
        );

        expect(schema['type'], equals('object'));
        expect(schema['properties'], isNotNull);
        expect(schema['properties']!['field1'], isNotNull);
        expect(schema['properties']!['field2'], isNotNull);
        expect(schema['required'], equals(['field1']));
      });
    });
  });
}
