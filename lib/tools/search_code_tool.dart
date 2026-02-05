/// Search Code Tool
///
/// Search code content in the ServerPod project.
library serverpod_boost.tools.search_code_tool;

import 'dart:io';
import 'package:path/path.dart' as p;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

/// Search result match
class CodeMatch {
  /// File path
  final String filePath;

  /// Relative path from project root
  final String relativePath;

  /// Line number (1-based)
  final int lineNumber;

  /// Line content
  final String line;

  /// Match start position
  final int start;

  /// Match end position
  final int end;

  CodeMatch({
    required this.filePath,
    required this.relativePath,
    required this.lineNumber,
    required this.line,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'relativePath': relativePath,
      'lineNumber': lineNumber,
      'line': line.trim(),
      'start': start,
      'end': end,
      'match': line.substring(start, end),
    };
  }
}

class SearchCodeTool extends McpToolBase {
  @override
  String get name => 'search_code';

  @override
  String get description => '''
Search for text patterns in source code files.

Supports case-sensitive/insensitive search with regex patterns.
Returns matching lines with context.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'query': McpSchema.string(
        description: 'Text or regex pattern to search for',
        required: true,
      ),
      'file_pattern': McpSchema.string(
        description: 'Glob-style pattern to filter files (e.g., "*.dart", "**/*_endpoint.dart")',
        defaultValue: '*.dart',
      ),
      'path': McpSchema.string(description: 'Directory to search in (relative to project root)'),
      'case_sensitive': McpSchema.boolean(
        description: 'Whether search is case-sensitive',
        defaultValue: false,
      ),
      'use_regex': McpSchema.boolean(
        description: 'Treat query as regular expression',
        defaultValue: false,
      ),
      'max_results': McpSchema.integer(
        description: 'Maximum number of results to return',
        defaultValue: 50,
      ),
      'context_lines': McpSchema.integer(
        description: 'Number of context lines to include',
        defaultValue: 0,
      ),
      'exclude_patterns': McpSchema.array(
        items: McpSchema.string(description: 'File pattern to exclude'),
        description: 'Patterns to exclude (e.g., "*.g.dart", "generated")',
      ),
    },
    required: ['query'],
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final query = params['query'] as String;
    final filePattern = params['file_pattern'] as String? ?? '*.dart';
    final searchPath = params['path'] as String?;
    final caseSensitive = params['case_sensitive'] as bool? ?? false;
    final useRegex = params['use_regex'] as bool? ?? false;
    final maxResults = params['max_results'] as int? ?? 50;
    // TODO: Implement context_lines feature
    // final contextLines = params['context_lines'] as int? ?? 0;
    final excludePatterns = params['exclude_patterns'] as List<String>?;

    final project = ServerPodLocator.getProject();
    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    // Determine search directory
    String basePath = project.rootPath;
    if (searchPath != null && searchPath.isNotEmpty) {
      basePath = p.normalize(p.join(project.rootPath, searchPath));
    }

    final baseDir = Directory(basePath);
    if (!baseDir.existsSync()) {
      return {
        'error': 'Search path not found',
        'path': basePath,
      };
    }

    // Build regex for matching
    RegExp searchRegex;
    try {
      if (useRegex) {
        searchRegex = RegExp(query, caseSensitive: caseSensitive);
      } else {
        searchRegex = RegExp(
          RegExp.escape(query),
          caseSensitive: caseSensitive,
        );
      }
    } catch (e) {
      return {
        'error': 'Invalid query pattern',
        'message': e.toString(),
      };
    }

    // Search files
    final results = <CodeMatch>[];
    final filesSearched = <String>[];

    await for (final entity in _findFiles(baseDir, filePattern, excludePatterns)) {
      if (results.length >= maxResults) break;

      final file = entity as File;
      filesSearched.add(file.path);

      final matches = await _searchInFile(
        file,
        project.rootPath,
        searchRegex,
        maxResults - results.length,
      );

      results.addAll(matches);
    }

    return {
      'query': query,
      'filePattern': filePattern,
      'searchPath': basePath,
      'caseSensitive': caseSensitive,
      'useRegex': useRegex,
      'results': results.map((m) => m.toJson()).toList(),
      'resultCount': results.length,
      'filesSearched': filesSearched.length,
      'truncated': results.length >= maxResults,
    };
  }

  Stream<FileSystemEntity> _findFiles(
    Directory dir,
    String pattern,
    List<String>? excludePatterns,
  ) async* {
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: dir.path);

        // Check file pattern
        if (!_matchesPattern(relativePath, pattern)) {
          continue;
        }

        // Check exclusions
        if (_shouldExclude(entity.path, excludePatterns)) {
          continue;
        }

        yield entity;
      }
    }
  }

  bool _matchesPattern(String path, String pattern) {
    // Simple glob matching
    final regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');

    final regex = RegExp('^$regexPattern\$');
    return regex.hasMatch(path);
  }

  bool _shouldExclude(String filePath, List<String>? patterns) {
    if (patterns == null || patterns.isEmpty) return false;

    for (final pattern in patterns) {
      if (filePath.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  Future<List<CodeMatch>> _searchInFile(
    File file,
    String projectRoot,
    RegExp regex,
    int maxResults,
  ) async {
    final matches = <CodeMatch>[];

    try {
      final lines = await file.readAsLines();
      final relativePath = p.relative(file.path, from: projectRoot);

      for (var i = 0; i < lines.length && matches.length < maxResults; i++) {
        final line = lines[i];

        for (final match in regex.allMatches(line)) {
          matches.add(CodeMatch(
            filePath: file.path,
            relativePath: relativePath,
            lineNumber: i + 1,
            line: line,
            start: match.start,
            end: match.end,
          ));
        }
      }
    } catch (e) {
      // Skip files that can't be read
    }

    return matches;
  }
}
