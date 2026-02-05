/// Read File Tool
///
/// Read file content from the ServerPod project.
library serverpod_boost.tools.read_file_tool;

import 'dart:io';
import 'package:path/path.dart' as p;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class ReadFileTool extends McpToolBase {
  @override
  String get name => 'read_file';

  @override
  String get description => '''
Read file content from the ServerPod project.

Returns the full content of the specified file.
Useful for examining source code, config files, etc.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'file_path': McpSchema.string(
        description: 'Path to the file (can be relative to project root or absolute)',
      ),
      'encoding': McpSchema.string(
        description: 'File encoding',
        defaultValue: 'utf-8',
      ),
    },
    required: ['file_path'],
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final filePath = params['file_path'] as String? ?? '';
    final encoding = params['encoding'] as String? ?? 'utf-8';

    if (filePath.isEmpty) {
      return {
        'error': 'Invalid parameter',
        'message': 'file_path is required',
      };
    }

    final project = ServerPodLocator.getProject();
    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    // Resolve file path
    String resolvedPath = filePath;
    if (!p.isAbsolute(filePath)) {
      resolvedPath = p.normalize(p.join(project.rootPath, filePath));
    }

    final file = File(resolvedPath);
    if (!file.existsSync()) {
      return {
        'error': 'File not found',
        'path': resolvedPath,
        'relativePath': filePath,
      };
    }

    try {
      // Security check: ensure file is within project root
      final projectDir = Directory(project.rootPath);
      final projectRealPath = projectDir.resolveSymbolicLinksSync();
      final fileRealPath = file.resolveSymbolicLinksSync();

      // Normalize paths for comparison
      final normalizedProjectPath = p.normalize(projectRealPath);
      final normalizedFilePath = p.normalize(fileRealPath);

      // Check if file is within project directory
      if (!p.isWithin(normalizedProjectPath, normalizedFilePath)) {
        return {
          'error': 'Access denied',
          'message': 'File is outside the project directory',
          'requestedPath': resolvedPath,
        };
      }

      // Read file content
      final content = await file.readAsString();
      final stat = await file.stat();

      // Detect line endings and line count
      final lineCount = content.split('\n').length;
      final hasCrLf = content.contains('\r\n');

      return {
        'path': resolvedPath,
        'relativePath': p.relative(resolvedPath, from: project.rootPath),
        'content': content,
        'size': stat.size,
        'lineCount': lineCount,
        'encoding': encoding,
        'hasCrLfLineEndings': hasCrLf,
        'modified': stat.modified.toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Failed to read file',
        'path': resolvedPath,
        'message': e.toString(),
      };
    }
  }
}
