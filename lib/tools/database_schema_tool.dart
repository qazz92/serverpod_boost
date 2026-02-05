/// Database Schema Tool
///
/// Get database schema from migration files.
library serverpod_boost.tools.database_schema_tool;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class DatabaseSchemaTool extends McpToolBase {
  @override
  String get name => 'database_schema';

  @override
  String get description => '''
Get database schema information by parsing migration files.

Returns table definitions, columns, indexes, and foreign keys found in migration files.
Note: This parses migration files but does not connect to the actual database.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'table_filter': McpSchema.string(description: 'Filter tables by name pattern'),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final tableFilter = params['table_filter'] as String?;
    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    final migrationFiles = project.migrationFiles;
    final tables = <String, Map<String, dynamic>>{};

    for (final file in migrationFiles) {
      final content = await file.readAsString();
      _parseMigrationFile(content, tables);
    }

    // Apply filter if provided
    var filteredTables = tables;
    if (tableFilter != null) {
      filteredTables = Map.fromEntries(
        tables.entries.where((e) =>
          e.key.toLowerCase().contains(tableFilter.toLowerCase())
        ),
      );
    }

    return {
      'tables': filteredTables.entries.map((e) => {
        'name': e.key,
        ...e.value,
      }).toList(),
      'tableCount': filteredTables.length,
      'migrationCount': migrationFiles.length,
    };
  }

  void _parseMigrationFile(String content, Map<String, Map<String, dynamic>> tables) {
    // Parse CREATE TABLE statements
    // Note: Using regular strings instead of raw strings to properly escape quotes
    final createTablePattern = RegExp(
      'createTable\\s*\\(\\s*[\'"](\\w+)[\'"]\\s*,\\s*\\((.*?)\\)\\s*\\)',
      dotAll: true,
    );

    for (final match in createTablePattern.allMatches(content)) {
      final tableName = match.group(1)!;
      final columnsDef = match.group(2)!;

      final columns = <Map<String, dynamic>>[];
      final indexes = <Map<String, dynamic>>[];

      // Parse columns
      final lines = columnsDef.split(',');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // Check for index
        if (trimmed.contains('index(')) {
          indexes.add(_parseIndex(trimmed));
          continue;
        }

        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          final columnName = parts[0].replaceAll("'", '').replaceAll('"', '');
          columns.add({
            'name': columnName,
            'type': parts[1],
            'nullable': !trimmed.contains('notNull'),
            'primaryKey': trimmed.contains('primaryKey'),
          });
        }
      }

      tables[tableName] = {
        'columns': columns,
        'columnCount': columns.length,
        if (indexes.isNotEmpty) 'indexes': indexes,
      };
    }
  }

  Map<String, dynamic> _parseIndex(String definition) {
    // Note: Using regular string for proper escaping
    final nameMatch = RegExp('[\'"](\\w+)[\'"]').firstMatch(definition);
    final columnsMatch = RegExp('\\((.*?)\\)').firstMatch(definition);

    return {
      'name': nameMatch?.group(1) ?? 'unknown',
      'columns': columnsMatch?.group(1)?.split(',') ?? [],
      'unique': definition.contains('unique'),
    };
  }
}
