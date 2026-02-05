/// Find Files Tool
///
/// Find files by pattern in the ServerPod project.
library serverpod_boost.tools.find_files_tool;

import 'dart:io';
import 'package:path/path.dart' as p;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class FindFilesTool extends McpToolBase {
  @override
  String get name => 'find_files';

  @override
  String get description => '''
Find files by pattern or name in the ServerPod project.

Supports glob patterns for flexible searching.
Useful for locating specific files or file types.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'pattern': McpSchema.string(
        description: 'Glob pattern to match files (e.g., "*.dart", "**/*_endpoint.dart")',
      ),
      'path': McpSchema.string(description: 'Directory to search in (relative to project root)'),
      'exclude_patterns': McpSchema.array(
        items: McpSchema.string(description: 'Pattern to exclude'),
        description: 'Patterns to exclude (e.g., "generated", "*.g.dart")',
      ),
      'max_results': McpSchema.integer(
        description: 'Maximum number of results to return',
        defaultValue: 100,
      ),
    },
    required: ['pattern'],
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final pattern = params['pattern'] as String? ?? '';
    final path = params['path'] as String?;
    final excludePatterns = params['exclude_patterns'] as List<dynamic>?;
    final maxResults = params['max_results'] as int? ?? 100;

    final project = ServerPodLocator.getProject();
    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    // Determine search path
    String searchPath = project.rootPath;
    if (path != null && path.isNotEmpty) {
      searchPath = p.normalize(p.join(project.rootPath, path));
    }

    final searchDir = Directory(searchPath);
    if (!searchDir.existsSync()) {
      return {
        'error': 'Search path not found',
        'path': searchPath,
      };
    }

    final results = <Map<String, dynamic>>[];
    final excludeList = excludePatterns?.cast<String>();

    try {
      // Use recursive directory listing
      final entities = searchDir.list(recursive: true, followLinks: false);

      await for (final entity in entities) {
        if (results.length >= maxResults) break;

        if (entity is File) {
          final filePath = entity.path;
          final fileName = p.basename(filePath);
          final relativePath = p.relative(filePath, from: searchPath);

          // Check if pattern matches
          if (!_matchesPattern(relativePath, pattern)) {
            continue;
          }

          // Check exclusions
          if (_shouldExclude(filePath, excludeList)) {
            continue;
          }

          final stat = await entity.stat();
          final projectRelativePath = p.relative(filePath, from: project.rootPath);

          results.add({
            'name': fileName,
            'path': filePath,
            'relativePath': projectRelativePath,
            'size': stat.size,
            'modified': stat.modified.toIso8601String(),
          });
        }
      }
    } catch (e) {
      return {
        'error': 'File system error',
        'message': e.toString(),
      };
    }

    // Sort by path
    results.sort((a, b) => a['path'].compareTo(b['path']));

    return {
      'files': results,
      'count': results.length,
      'pattern': pattern,
      'searchPath': searchPath,
      'maxResults': maxResults,
      'truncated': results.length >= maxResults,
    };
  }

  /// Check if a file path matches the given glob pattern
  bool _matchesPattern(String filePath, String pattern) {
    // Convert glob pattern to regex
    String regexPattern = pattern;

    // Handle recursive wildcards **
    regexPattern = regexPattern.replaceAll('**', '___DOUBLESTAR___');
    regexPattern = regexPattern.replaceAll('*', '[^/]*');
    regexPattern = regexPattern.replaceAll('___DOUBLESTAR___', '.*');

    // Handle single character wildcard ?
    regexPattern = regexPattern.replaceAll('?', '.');

    // Handle character classes [abc]
    regexPattern = regexPattern.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]'),
      (match) => '[${match.group(1)}]',
    );

    // Escape other special regex characters and anchor
    regexPattern = '^$regexPattern\$';

    try {
      final regex = RegExp(regexPattern, caseSensitive: false);
      return regex.hasMatch(filePath);
    } catch (e) {
      // If regex fails, fall back to simple contains
      return filePath.contains(pattern.replaceAll('*', '').replaceAll('?', ''));
    }
  }

  /// Check if file should be excluded based on patterns
  bool _shouldExclude(String filePath, List<String>? patterns) {
    if (patterns == null || patterns.isEmpty) return false;

    final fileName = p.basename(filePath);

    for (final pattern in patterns) {
      // Check if path contains the pattern
      if (filePath.contains(pattern)) {
        return true;
      }

      // Check if file name matches the pattern (simple glob)
      if (_matchesPattern(fileName, pattern)) {
        return true;
      }
    }

    return false;
  }
}
