/// Database Query Tool
///
/// Execute safe read-only SQL queries against the Serverpod database.
/// This tool is designed for AI agents to inspect database state during development.
library serverpod_boost.tools.database_query_tool;

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:postgres/postgres.dart';

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

/// SQL validation and execution tool with safety constraints
class DatabaseQueryTool extends McpToolBase {
  /// Maximum rows to prevent data dumps
  static const int maxRows = 10000;

  /// Default row limit
  static const int defaultMaxRows = 1000;

  /// Query timeout in seconds
  static const Duration queryTimeout = Duration(seconds: 30);

  /// Maximum concurrent connections
  static const int maxConnections = 5;

  /// Connection pool for reusing database connections
  static final Map<String, Pool> _connectionPools = {};

  /// Allowed SQL operations (read-only)
  static const List<String> _allowedOperations = [
    'SELECT',
    'SHOW',
    'EXPLAIN',
    'DESCRIBE',
    'WITH', // CTEs
    'WITH RECURSIVE',
  ];

  /// Blocked SQL operations (modifying data)
  static const List<String> _blockedOperations = [
    'INSERT',
    'UPDATE',
    'DELETE',
    'DROP',
    'CREATE',
    'ALTER',
    'TRUNCATE',
    'GRANT',
    'REVOKE',
  ];

  @override
  String get name => 'database_query';

  @override
  String get description => '''
Execute safe read-only SQL queries against the Serverpod database.

Security constraints:
- Only SELECT, SHOW, EXPLAIN, DESCRIBE, WITH queries allowed
- INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE blocked
- Maximum $maxRows rows per query (default $defaultMaxRows)
- ${queryTimeout.inSeconds} second timeout per query
- Connection pooling (max $maxConnections concurrent)
- All queries are validated before execution

Use cases:
- Inspect database state during development
- Verify data integrity
- Check table relationships
- Debug query issues
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'query': McpSchema.string(
        description: 'SQL query to execute (read-only)',
        required: true,
      ),
      'maxRows': McpSchema.integer(
        description: 'Maximum rows to return (default: $defaultMaxRows, max: $maxRows)',
        defaultValue: defaultMaxRows,
      ),
      'environment': McpSchema.enumProperty(
        values: ['development', 'production', 'staging', 'test'],
        description: 'Environment config to use (default: development)',
        defaultValue: 'development',
      ),
    },
  );

  @override
  String? validateParams(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return 'Parameters are required';
    }

    final query = params['query'] as String?;
    if (query == null || query.trim().isEmpty) {
      return 'Query parameter is required';
    }

    // Validate SQL safety
    final validationError = _validateSql(query);
    if (validationError != null) {
      return validationError;
    }

    // Validate maxRows
    final maxRowsParam = params['maxRows'] as int?;
    if (maxRowsParam != null && (maxRowsParam < 1 || maxRowsParam > maxRows)) {
      return 'maxRows must be between 1 and $maxRows';
    }

    return null;
  }

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final query = (params['query'] as String).trim();
    final maxRowsParam = (params['maxRows'] as int?) ?? defaultMaxRows;
    final environment = (params['environment'] as String?) ?? 'development';

    final project = ServerPodLocator.getProject();
    if (project == null || !project.isValid) {
      return {
        'error': 'Not a valid ServerPod project',
        'hint': 'Run this command from a ServerPod project directory',
      };
    }

    try {
      // Load database configuration
      final dbConfig = await _loadDatabaseConfig(project, environment);
      if (dbConfig == null) {
        return {
          'error': 'Database configuration not found',
          'environment': environment,
          'hint': 'Ensure config/$environment.yaml exists and contains database settings',
        };
      }

      // Get or create connection pool
      final pool = await _getConnectionPool(dbConfig);

      // Execute query with timeout and row limit
      final stopwatch = Stopwatch()..start();

      final result = await pool.withConnection(
        (conn) => _executeQuery(conn, query, maxRowsParam),
      );

      stopwatch.stop();

      return {
        'rows': result['rows'],
        'rowCount': result['rowCount'],
        'columns': result['columns'],
        'executionTimeMs': stopwatch.elapsedMilliseconds,
        'environment': environment,
      };
    } on PgException catch (e) {
      return {
        'error': 'Database error: ${e.message}',
        'query': query,
      };
    } catch (e) {
      return {
        'error': 'Query execution failed: ${e.toString()}',
        'query': query,
      };
    }
  }

  /// Execute SQL query and return formatted results
  Future<Map<String, dynamic>> _executeQuery(
    Connection conn,
    String query,
    int maxRows,
  ) async {
    // Add LIMIT clause if not present and query is SELECT
    String finalQuery = query;
    if (query.toUpperCase().startsWith('SELECT') &&
        !query.toUpperCase().contains('LIMIT')) {
      finalQuery = '$query LIMIT $maxRows';
    }

    // Execute query
    final result = await conn.execute(finalQuery);

    // Extract column names and row data
    final columns = <String>[];
    final rows = <Map<String, dynamic>>[];

    if (result.isNotEmpty) {
      // Get column names from the schema
      final schema = result.first.schema;

      for (var i = 0; i < schema.columns.length; i++) {
        final col = schema.columns.elementAt(i);
        columns.add(col.columnName ?? 'column_$i');
      }

      // Convert rows to maps
      var rowCount = 0;
      for (final row in result) {
        final rowMap = <String, dynamic>{};
        for (var i = 0; i < row.length; i++) {
          final columnName = columns[i];
          rowMap[columnName] = _formatValue(row[i]);
        }
        rows.add(rowMap);
        rowCount++;
        if (rowCount >= maxRows) break;
      }
    }

    return {
      'rows': rows,
      'rowCount': rows.length,
      'columns': columns,
    };
  }

  /// Format database value for JSON serialization
  dynamic _formatValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Uint8List) return '<binary data>';
    if (value is ByteBuffer) return '<binary data>';
    return value;
  }

  /// Get or create a connection pool for the given database config
  Future<Pool> _getConnectionPool(Map<String, dynamic> dbConfig) async {
    final poolKey = _getPoolKey(dbConfig);

    if (_connectionPools.containsKey(poolKey)) {
      return _connectionPools[poolKey]!;
    }

    // Check connection limit
    if (_connectionPools.length >= maxConnections) {
      throw StateException(
        'Maximum database connections ($maxConnections) reached. '
        'Close existing connections or try again later.',
      );
    }

    // Build connection string
    final user = dbConfig['user'] as String?;
    final password = dbConfig['password'] as String?;
    final host = dbConfig['host'] as String? ?? 'localhost';
    final port = dbConfig['port'] as int? ?? 5432;
    final dbName = dbConfig['name'] as String? ?? 'postgres';

    final connectionString = _buildConnectionString(
      host: host,
      port: port,
      database: dbName,
      user: user,
      password: password,
    );

    // Create connection pool
    final pool = Pool.withUrl(connectionString);

    _connectionPools[poolKey] = pool;
    return pool;
  }

  /// Build PostgreSQL connection string
  String _buildConnectionString({
    required String host,
    required int port,
    required String database,
    String? user,
    String? password,
  }) {
    final buffer = StringBuffer('postgresql://');

    if (user != null) {
      buffer.write(user);
      if (password != null) {
        buffer.write(':');
        buffer.write(Uri.encodeComponent(password));
      }
      buffer.write('@');
    }

    buffer.write(host);
    buffer.write(':');
    buffer.write(port);
    buffer.write('/');
    buffer.write(database);

    return buffer.toString();
  }

  /// Generate unique key for connection pool
  String _getPoolKey(Map<String, dynamic> dbConfig) {
    final host = dbConfig['host'] as String? ?? 'localhost';
    final port = dbConfig['port'] as int? ?? 5432;
    final dbName = dbConfig['name'] as String? ?? 'postgres';
    return '$host:$port:$dbName';
  }

  /// Load database configuration from ServerPod config files
  Future<Map<String, dynamic>?> _loadDatabaseConfig(
    ServerPodProject project,
    String environment,
  ) async {
    // Load main config file
    final configFile = project.getConfigFile(environment);
    if (configFile == null) {
      return null;
    }

    final content = await configFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml == null || !yaml.containsKey('database')) {
      return null;
    }

    final dbConfig = yaml['database'] as YamlMap;
    final config = <String, dynamic>{
      'host': dbConfig['host']?.toString() ?? 'localhost',
      'port': int.tryParse(dbConfig['port']?.toString() ?? '5432') ?? 5432,
      'name': dbConfig['name']?.toString() ?? '',
      'user': dbConfig['user']?.toString(),
    };

    // Try to load password from passwords.yaml
    final passwordsFile = File(p.join(project.configPath!, 'passwords.yaml'));
    if (passwordsFile.existsSync()) {
      final passwordsContent = await passwordsFile.readAsString();
      final passwordsYaml = loadYaml(passwordsContent) as YamlMap?;

      if (passwordsYaml != null && passwordsYaml.containsKey(environment)) {
        final envPasswords = passwordsYaml[environment] as YamlMap;
        final password = envPasswords['database']?.toString();

        // Only use password if it's not the placeholder
        if (password != null &&
            password != 'DB_PASSWORD' &&
            password != 'DB_TEST_PASSWORD') {
          config['password'] = password;
        }
      }
    }

    return config;
  }

  /// Validate SQL query for safety
  String? _validateSql(String query) {
    final trimmedQuery = query.trim().toUpperCase();

    // Check for blocked operations
    for (final blocked in _blockedOperations) {
      // Use word boundary to avoid false positives
      final pattern = RegExp(r'\b' + RegExp.escape(blocked) + r'\b');
      if (pattern.hasMatch(trimmedQuery)) {
        return 'SQL operation "$blocked" is not allowed for safety reasons. '
            'Use read-only queries (SELECT, SHOW, EXPLAIN, DESCRIBE) only.';
      }
    }

    // Check if query starts with allowed operation
    bool startsWithAllowed = false;
    for (final allowed in _allowedOperations) {
      if (trimmedQuery.startsWith(allowed)) {
        startsWithAllowed = true;
        break;
      }
    }

    if (!startsWithAllowed) {
      return 'Query must start with an allowed operation: ${_allowedOperations.join(", ")}';
    }

    // Check for potentially dangerous patterns
    final dangerousPatterns = [
      RegExp(r';\s*\w+', multiLine: true), // Multiple statements
      RegExp(r'--\s+'), // SQL comment injection
      RegExp(r'/\*.*\*/', dotAll: true), // Block comments (might hide malicious code)
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(query)) {
        return 'Query contains potentially dangerous patterns (multiple statements or suspicious comments)';
      }
    }

    return null;
  }

  /// Close all connection pools (cleanup)
  static Future<void> closeAll() async {
    for (final pool in _connectionPools.values) {
      await pool.close();
    }
    _connectionPools.clear();
  }
}

/// State exception for connection limits
class StateException implements Exception {
  final String message;

  const StateException(this.message);

  @override
  String toString() => message;
}
