/// Migration Scanner Tool
///
/// List migration files and their contents.
library serverpod_boost.tools.migration_scanner_tool;

import 'package:path/path.dart' as p;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class MigrationScannerTool extends McpToolBase {
  @override
  String get name => 'migration_scanner';

  @override
  String get description => '''
List all migration files in the ServerPod project.

Returns migration file names, paths, timestamps, and table changes.
Useful for understanding database evolution history.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'table_filter': McpSchema.string(description: 'Filter by table name'),
      'include_content': McpSchema.boolean(
        description: 'Include migration file content',
        defaultValue: false,
      ),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final tableFilter = params['table_filter'] as String?;
    final includeContent = params['include_content'] as bool? ?? false;

    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    final migrationFiles = project.migrationFiles;
    final results = <Map<String, dynamic>>[];

    for (final file in migrationFiles) {
      final filename = p.basename(file.path);
      final tableName = _extractTableName(filename);

      // Apply filter if provided
      if (tableFilter != null &&
          tableName != null &&
          !tableName.toLowerCase().contains(tableFilter.toLowerCase())) {
        continue;
      }

      final stat = file.statSync();
      final content = includeContent ? await file.readAsString() : null;

      results.add({
        'filename': filename,
        'path': file.path,
        'table': tableName,
        'modified': stat.modified.toIso8601String(),
        'size': stat.size,
        if (content != null) 'content': content,
      });
    }

    return {
      'migrations': results,
      'count': results.length,
      'migrationsPath': project.migrationsPath,
    };
  }

  String? _extractTableName(String filename) {
    // Migration files are named like: 20240101000000_0000_initial.dart
    // or: 20240101000000_0001_create_users_table.dart
    final match = RegExp(r'(\d{14})_(\d{4})_(.+)\.dart').firstMatch(filename);
    if (match != null) {
      final description = match.group(3)!;
      // Extract table name from description like "create_users_table"
      final tableMatch = RegExp(r'create_(\w+)_?table?').firstMatch(description);
      return tableMatch?.group(1);
    }
    return null;
  }
}
