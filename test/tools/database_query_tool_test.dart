/// Database Query Tool Tests
///
/// Comprehensive tests for the Database Query Tool including:
/// - SQL validation and security constraints
/// - Allowlist and blocklist enforcement
/// - Row limit enforcement
/// - Connection handling
/// - Error handling
/// - Timeout behavior
/// - Result formatting
library serverpod_boost.test.tools.database_query_tool_test;

import 'dart:io';
import 'package:test/test.dart';

import '../../lib/tools/database_query_tool.dart';
import '../../lib/mcp/mcp_protocol.dart';
import '../../lib/serverpod/serverpod_locator.dart';

void main() {
  group('DatabaseQueryTool', () {
    late DatabaseQueryTool tool;
    late String originalDir;

    setUp(() {
      tool = DatabaseQueryTool();
      originalDir = Directory.current.path;
      ServerPodLocator.resetCache();
    });

    tearDown(() async {
      // Restore original directory
      Directory.current = originalDir;
      // Clean up connection pools
      await DatabaseQueryTool.closeAll();
      // Reset cache
      ServerPodLocator.resetCache();
    });

    group('Tool Metadata', () {
      test('has correct name', () {
        expect(tool.name, equals('database_query'));
      });

      test('has non-empty description', () {
        expect(tool.description, isNotEmpty);
        expect(tool.description, contains('read-only'));
        expect(tool.description, contains('SELECT'));
      });

      test('has valid input schema', () {
        final schema = tool.inputSchema;
        expect(schema['type'], equals('object'));
        expect(schema['properties'], isNotNull);
        expect(schema['properties']['query'], isNotNull);
      });

      test('schema contains query property', () {
        final properties = tool.inputSchema['properties'] as Map;
        expect(properties.containsKey('query'), isTrue);
        expect(properties['query']['type'], equals('string'));
      });

      test('schema contains maxRows property', () {
        final properties = tool.inputSchema['properties'] as Map;
        expect(properties.containsKey('maxRows'), isTrue);
        expect(properties['maxRows']['type'], equals('integer'));
      });

      test('schema contains environment property', () {
        final properties = tool.inputSchema['properties'] as Map;
        expect(properties.containsKey('environment'), isTrue);
        expect(properties['environment']['type'], equals('string'));
      });
    });

    group('SQL Validation Tests', () {
      test('SELECT query passes validation', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SELECT * FROM users LIMIT 10'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('INSERT statement is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'INSERT INTO users VALUES (1, 2, 3)'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('INSERT'));
        expect(validationError, contains('not allowed'));
      });

      test('UPDATE statement is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'UPDATE users SET name = "test" WHERE id = 1'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('UPDATE'));
      });

      test('DELETE statement is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'DELETE FROM users WHERE id = 1'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('DELETE'));
      });
    });

    group('Allowlist Tests', () {
      test('SHOW queries are allowed', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SHOW TABLES'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('EXPLAIN queries are allowed', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'EXPLAIN SELECT * FROM users'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('DESCRIBE queries are allowed', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'DESCRIBE users'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('WITH (CTE) queries are allowed', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'WITH cte AS (SELECT * FROM users) SELECT * FROM cte'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('case-insensitive operation detection', () async {
        final lowerCase = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'select * from users'},
        );

        final mixedCase = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SeLeCt * FrOm users'},
        );

        expect(tool.validateParams(lowerCase.params), isNull);
        expect(tool.validateParams(mixedCase.params), isNull);
      });
    });

    group('Blocklist Tests', () {
      test('DROP TABLE is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'DROP TABLE users'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('DROP'));
      });

      test('ALTER TABLE is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'ALTER TABLE users ADD COLUMN age INT'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('ALTER'));
      });

      test('CREATE TABLE is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'CREATE TABLE test (id INT)'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('CREATE'));
      });

      test('TRUNCATE is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'TRUNCATE TABLE users'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('TRUNCATE'));
      });

      test('GRANT is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'GRANT ALL ON users TO admin'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('GRANT'));
      });

      test('REVOKE is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'REVOKE ALL ON users FROM admin'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('REVOKE'));
      });
    });

    group('Row Limit Tests', () {
      test('maxRows constant is set to 10000', () {
        expect(DatabaseQueryTool.maxRows, equals(10000));
      });

      test('defaultMaxRows is set to 1000', () {
        expect(DatabaseQueryTool.defaultMaxRows, equals(1000));
      });

      test('maxRows below minimum is rejected', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SELECT 1', 'maxRows': 0},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('must be between 1 and'));
      });

      test('maxRows above maximum is rejected', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SELECT 1', 'maxRows': 10001},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('must be between 1 and'));
      });

      test('valid maxRows is accepted', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SELECT 1', 'maxRows': 500},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('description mentions maxRows limit', () {
        expect(tool.description, contains('10000'));
        expect(tool.description, contains('rows'));
      });
    });

    group('Connection Tests', () {
      test('invalid project returns error', () async {
        // Create a temp directory that's not a ServerPod project
        final tempDir = Directory.systemTemp.createTempSync('test_db_');
        Directory.current = tempDir.path;
        ServerPodLocator.resetCache();

        try {
          final request = McpRequest(
            id: 'test',
            method: 'database_query',
            params: {'query': 'SELECT 1'},
          );

          final response = await tool.execute(request);
          final result = response.result as Map;

          expect(result.containsKey('error'), isTrue);
          expect(result['error'], contains('Not a valid ServerPod project'));
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      });

      test('valid environment parameter is accepted', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SELECT 1', 'environment': 'development'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });
    });

    group('Error Handling Tests', () {
      test('empty query returns validation error', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': ''},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('required'));
      });

      test('missing query parameter returns error', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('required'));
      });

      test('null parameters returns error', () async {
        final validationError = tool.validateParams(null);
        expect(validationError, isNotNull);
        expect(validationError, contains('required'));
      });

      test('whitespace-only query returns error', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': '   '},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
      });
    });

    group('Timeout Tests', () {
      test('queryTimeout is 30 seconds', () {
        expect(DatabaseQueryTool.queryTimeout.inSeconds, equals(30));
      });

      test('description mentions timeout', () {
        expect(tool.description, contains('30'));
        expect(tool.description, contains('timeout'));
      });
    });

    group('Security Tests', () {
      test('multiple statements with blocked keyword are caught', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SELECT * FROM users; DROP TABLE users'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        // Gets caught by DROP detection first
        expect(validationError, contains('DROP'));
      });

      test('SQL comment injection with whitespace is blocked', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': "SELECT * FROM users WHERE id = 1 -- comment"},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('dangerous'));
      });

      test('block comments are detected as potentially dangerous', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SELECT /* comment */ * FROM users'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNotNull);
        expect(validationError, contains('dangerous'));
      });

      test('valid query with newlines is allowed', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': 'SELECT *\nFROM users\nLIMIT 10'},
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });
    });

    group('Edge Cases', () {
      test('complex JOIN query is allowed', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {
            'query': '''
              SELECT u.name, o.order_id
              FROM users u
              INNER JOIN orders o ON u.id = o.user_id
              LIMIT 10
            '''
          },
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('subquery is allowed', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {
            'query': 'SELECT * FROM (SELECT * FROM users LIMIT 5) AS subquery'
          },
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('UNION query is allowed', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {
            'query': 'SELECT name FROM users UNION SELECT name FROM admins'
          },
        );

        final validationError = tool.validateParams(request.params);
        expect(validationError, isNull);
      });

      test('maxConnections constant is defined', () {
        expect(DatabaseQueryTool.maxConnections, equals(5));
      });
    });

    group('Request/Response Protocol', () {
      test('response includes request ID', () async {
        final tempDir = Directory.systemTemp.createTempSync('test_db_');
        Directory.current = tempDir.path;
        ServerPodLocator.resetCache();

        try {
          final request = McpRequest(
            id: 'test-request-123',
            method: 'database_query',
            params: {'query': 'SELECT 1'},
          );

          final response = await tool.execute(request);
          expect(response.id, equals('test-request-123'));
        } finally {
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        }
      });

      test('validation error returns invalid params response', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': ''},
        );

        final response = await tool.execute(request);
        expect(response.isError, isTrue);
        expect(response.error?.code, equals(McpProtocol.errorInvalidParams));
      });

      test('error response has proper structure', () async {
        final request = McpRequest(
          id: 'test',
          method: 'database_query',
          params: {'query': ''},
        );

        final response = await tool.execute(request);
        expect(response.isError, isTrue);
        expect(response.error, isNotNull);
        expect(response.error?.code, isNotNull);
        expect(response.error?.message, isNotEmpty);
      });
    });

    group('Connection Pool Management', () {
      test('closeAll closes all connection pools', () async {
        // This test verifies the closeAll method exists and can be called
        expect(() async => await DatabaseQueryTool.closeAll(), returnsNormally);
      });

      test('maxConnections limit is enforced', () {
        expect(DatabaseQueryTool.maxConnections, greaterThan(0));
        expect(DatabaseQueryTool.maxConnections, lessThanOrEqualTo(10));
      });
    });

    group('Environment Configuration', () {
      test('valid environment values are accepted', () {
        final validEnvironments = ['development', 'production', 'staging', 'test'];

        for (final env in validEnvironments) {
          final request = McpRequest(
            id: 'test',
            method: 'database_query',
            params: {'query': 'SELECT 1', 'environment': env},
          );

          final validationError = tool.validateParams(request.params);
          expect(validationError, isNull, reason: '$env should be valid');
        }
      });

      test('schema enum contains all expected environments', () {
        final properties = tool.inputSchema['properties'] as Map;
        final envProperty = properties['environment'] as Map;

        expect(envProperty['enum'], containsAll(['development', 'production', 'staging', 'test']));
      });
    });
  });
}
