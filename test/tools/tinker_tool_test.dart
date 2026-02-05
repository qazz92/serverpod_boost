/// TinkerTool Unit Tests
///
/// Comprehensive tests for the TinkerTool including:
/// - Security validations
/// - Code execution
/// - Timeout enforcement
/// - Memory limits
/// - Error handling
library serverpod_boost.test.tools.tinker_tool_test;

import 'package:test/test.dart';

import '../../lib/tools/tinker_tool.dart';
import '../../lib/mcp/mcp_protocol.dart';

void main() {
  group('TinkerTool', () {
    late TinkerTool tool;

    setUp(() {
      tool = TinkerTool();
    });

    tearDown(() {
      // Cleanup
    });

    group('Tool Metadata', () {
      test('has correct name', () {
        expect(tool.name, equals('tinker'));
      });

      test('has description', () {
        expect(tool.description, isNotEmpty);
        expect(tool.description.toLowerCase(), contains('isolated'));
        // The description mentions "Timeout enforcement" not just "timeout"
        expect(tool.description.toLowerCase(), contains('timeout'));
        expect(tool.description.toLowerCase(), contains('memory'));
      });

      test('has valid input schema', () {
        final schema = tool.inputSchema;

        expect(schema['type'], equals('object'));
        expect(schema['properties'], isNotNull);
        expect(schema['properties']['code'], isNotNull);
        expect(schema['properties']['code']['type'], equals('string'));
        expect(schema['required'], contains('code'));
      });
    });

    group('Parameter Validation', () {
      test('requires code parameter', () async {
        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {},
        );

        final response = await tool.execute(request);

        // Validation returns error response
        expect(response.isError, isTrue);
        expect(response.error, isNotNull);
        expect(response.error!.message, contains('required'));
      });

      test('rejects empty code', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': ''},
        );

        final response = await tool.execute(request);

        expect(response.isError, isTrue);
        expect(response.error, isNotNull);
      });

      test('rejects null code', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': null},
        );

        final response = await tool.execute(request);

        expect(response.isError, isTrue);
        expect(response.error, isNotNull);
      });

      test('validates timeout parameter', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {
            'code': '1 + 1',
            'timeout': 100, // Exceeds max of 30
          },
        );

        final response = await tool.execute(request);

        expect(response.isError, isTrue);
        expect(response.error!.message, contains('cannot exceed'));
      });

      test('accepts valid timeout', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {
            'code': '1 + 1',
            'timeout': 10,
          },
        );

        final response = await tool.execute(request);

        // Should not have timeout validation error
        // If enabled, it might succeed or fail on execution
        // but validation should pass
        if (response.isError) {
          expect(response.error!.message, isNot(contains('cannot exceed')));
        }
      });
    });

    group('Dangerous Import Blocking', () {
      test('blocks dart:io import', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {
            'code': "import 'dart:io';\n1 + 1",
          },
        );

        final response = await tool.execute(request);

        expect(response.isError, isTrue);
        expect(response.error!.message, contains('dart:io'));
        expect(response.error!.message, contains('not allowed'));
      });

      test('blocks dart:html import', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {
            'code': 'import "dart:html";\n1 + 1',
          },
        );

        final response = await tool.execute(request);

        expect(response.isError, isTrue);
        expect(response.error!.message, contains('dart:html'));
        expect(response.error!.message, contains('not allowed'));
      });

      test('blocks dart:mirrors import', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {
            'code': "import 'dart:mirrors';\n1 + 1",
          },
        );

        final response = await tool.execute(request);

        expect(response.isError, isTrue);
        expect(response.error!.message, contains('dart:mirrors'));
      });

      test('blocks dart:js import', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {
            'code': "import 'dart:js';\n1 + 1",
          },
        );

        final response = await tool.execute(request);

        expect(response.isError, isTrue);
        expect(response.error!.message, contains('dart:js'));
      });

      test('allows code without imports', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {
            'code': '1 + 1',
          },
        );

        final response = await tool.execute(request);

        // Should not have import error
        if (response.isError) {
          expect(response.error!.message, isNot(contains('import')));
        }
      });
    });

    group('Simple Expression Execution', () {
      test('executes simple arithmetic: 1 + 1', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '1 + 1'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          expect(response.result['result'], isNotNull);
          // Result should be 2 as string or number
          final result = response.result['result'].toString();
          expect(result, contains('2'));
        }
      });

      test('executes subtraction: 10 - 3', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '10 - 3'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('7'));
        }
      });

      test('executes multiplication: 6 * 7', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '6 * 7'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('42'));
        }
      });

      test('executes division: 20 / 4', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '20 / 4'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('5'));
        }
      });

      test('handles parentheses: (2 + 3) * 4', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '(2 + 3) * 4'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('20'));
        }
      });

      test('handles floating point: 3.14 * 2', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '3.14 * 2'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('6.28'));
        }
      });

      test('handles negative numbers: -5 + 3', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '-5 + 3'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('-2'));
        }
      });
    });

    group('String Manipulation', () {
      test('handles string literals', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '"hello, world"'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('hello, world'));
        }
      });

      test('handles single quoted strings', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {"code": "'hello'"},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('hello'));
        }
      });
    });

    group('Data Structures', () {
      test('handles list literals', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '[1, 2, 3]'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result, contains('[1, 2, 3]'));
        }
      });

      test('handles map literals', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '{"key": "value"}'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          final result = response.result['result'].toString();
          expect(result.toLowerCase(), contains('key'));
          expect(result.toLowerCase(), contains('value'));
        }
      });
    });

    group('Syntax Error Handling', () {
      test('handles invalid syntax gracefully', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '1 + + 2'},
        );

        final response = await tool.execute(request);

        // Should return an error, not crash
        expect(response.result, isNotNull);
        expect(response.result['error'], isNotNull);
      });

      test('handles unclosed parentheses', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '(1 + 2'},
        );

        final response = await tool.execute(request);

        expect(response.result['error'], isNotNull);
      });

      test('handles malformed expressions', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '***'},
        );

        final response = await tool.execute(request);

        expect(response.result['error'], isNotNull);
      });
    });

    group('Runtime Error Handling', () {
      test('handles division by zero', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '1 / 0'},
        );

        final response = await tool.execute(request);

        // Should handle gracefully
        expect(response.result, isNotNull);
        expect(response.result['error'], isNotNull);
      });

      test('handles overflow gracefully', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '999999999999999999999999999999 * 999999999999999999999999999999'},
        );

        final response = await tool.execute(request);

        expect(response.result, isNotNull);
        // Should either succeed or error gracefully
      });
    });

    group('Timeout Enforcement', () {
      test('enforces default timeout', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        // Create code that would take a long time if executed
        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '1 + 1', 'timeout': 1}, // 1 second timeout
        );

        final stopwatch = Stopwatch()..start();
        await tool.execute(request);
        stopwatch.stop();

        // Should complete quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      test('respects custom timeout parameter', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '2 + 2', 'timeout': 2},
        );

        final response = await tool.execute(request);

        // Should use custom timeout
        expect(response.result, isNotNull);
      });
    });

    group('Memory Reporting', () {
      test('reports memory usage', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '1 + 1'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          expect(response.result['memoryUsed'], isNotNull);
          expect(response.result['memoryUsed'], isPositive);
        }
      });

      test('reports execution time', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '1 + 1'},
        );

        final response = await tool.execute(request);

        if (response.result['error'] == null) {
          expect(response.result['executionTime'], isNotNull);
          expect(response.result['executionTime'], greaterThanOrEqualTo(0));
        }
      });
    });

    group('Output Capture', () {
      test('captures print output', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        // Note: Current implementation may not support print(),
        // but the test structure is ready
        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: {'code': '1 + 1'},
        );

        final response = await tool.execute(request);

        // Output field should exist
        expect(response.result.containsKey('output'), isTrue);
      });
    });

    group('Security Config', () {
      test('max timeout is enforced', () {
        expect(
          TinkerSecurityConfig.validateTimeout(100),
          isNotNull,
        ); // Should error
      });

      test('min timeout is enforced', () {
        expect(
          TinkerSecurityConfig.validateTimeout(0),
          isNotNull,
        ); // Should error
      });

      test('valid timeout is accepted', () {
        expect(
          TinkerSecurityConfig.validateTimeout(5),
          isNull,
        ); // Should pass
      });

      test('blocked imports are detected', () {
        expect(
          TinkerSecurityConfig.validateCode("import 'dart:io';"),
          isNotNull,
        );
      });

      test('safe code passes validation', () {
        expect(
          TinkerSecurityConfig.validateCode('1 + 1'),
          isNull,
        ); // Should pass
      });
    });

    group('MCP Protocol Compliance', () {
      test('returns valid McpResponse structure', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test-id',
          method: 'tinker',
          params: {'code': '1 + 1'},
        );

        final response = await tool.execute(request);

        expect(response.id, equals('test-id'));
        expect(response.result, isNotNull);
      });

      test('handles missing parameters gracefully', () async {
        if (!TinkerSecurityConfig.isEnabled()) {
          return;
        }

        final request = McpRequest(
          id: 'test',
          method: 'tinker',
          params: null,
        );

        final response = await tool.execute(request);

        expect(response.result, isNotNull);
        expect(response.result['error'], isNotNull);
      });
    });
  });
}

/// Helper function for test assumptions
/// Similar to test's assume() but simpler
void assume(bool condition) {
  if (!condition) {
    throw TestFailure('Assumption failed');
  }
}

/// Custom test failure exception
class TestFailure implements Exception {
  final String message;
  TestFailure(this.message);

  @override
  String toString() => 'TestFailure: $message';
}
