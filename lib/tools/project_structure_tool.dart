/// Project Structure Tool
///
/// Get file tree structure of the ServerPod project.
library serverpod_boost.tools.project_structure_tool;

import 'dart:io';
import 'package:path/path.dart' as p;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

/// File tree node
class FileTreeNode {
  FileTreeNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    List<FileTreeNode>? children,
  }) : children = children ?? [];

  /// Node name (file or directory name)
  final String name;

  /// Full path
  final String path;

  /// Whether this is a directory
  final bool isDirectory;

  /// File size (bytes) - null for directories
  final int? size;

  /// Children (for directories)
  final List<FileTreeNode> children;

  /// Convert to JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'type': isDirectory ? 'directory' : 'file',
      if (size != null) 'size': size,
      if (isDirectory && children.isNotEmpty) 'children': children.map((c) => c.toJson()).toList(),
    };
  }
}

class ProjectStructureTool extends McpToolBase {
  @override
  String get name => 'project_structure';

  @override
  String get description => '''
Get file tree structure of the ServerPod project.

Returns a hierarchical tree of files and directories.
Useful for understanding project organization and finding files.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'directory': McpSchema.string(description: 'Directory to scan (relative to project root)'),
      'depth': McpSchema.integer(
        description: 'Maximum depth to scan',
        defaultValue: 3,
      ),
      'include_files': McpSchema.boolean(
        description: 'Include files in output (not just directories)',
        defaultValue: true,
      ),
      'exclude_patterns': McpSchema.array(
        items: McpSchema.string(description: 'File or directory pattern to exclude'),
        description: 'Patterns to exclude (e.g., "node_modules", ".git")',
      ),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final project = ServerPodLocator.getProject();
    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    final directory = params['directory'] as String?;
    final depth = params['depth'] as int? ?? 3;
    final includeFiles = params['include_files'] as bool? ?? true;
    final excludePatterns = params['exclude_patterns'] as List<String>?;

    // Determine scan path
    String scanPath = project.rootPath;
    if (directory != null && directory.isNotEmpty) {
      scanPath = p.join(project.rootPath, directory);
    }

    final scanDir = Directory(scanPath);
    if (!scanDir.existsSync()) {
      return {
        'error': 'Directory not found',
        'path': scanPath,
      };
    }

    // Build file tree
    final tree = await _buildTree(
      scanDir,
      depth,
      includeFiles,
      excludePatterns ?? _getDefaultExcludes(),
      0,
    );

    return {
      'root': tree.toJson(),
      'path': scanPath,
      'relativePath': directory ?? '.',
      'depth': depth,
      'excludedPatterns': excludePatterns ?? _getDefaultExcludes(),
    };
  }

  List<String> _getDefaultExcludes() {
    return [
      'node_modules',
      '.git',
      '.dart_tool',
      'build',
      '.flutter-plugins',
      '.flutter-plugins-dependencies',
      '*.g.dart',
      '*.freezed.dart',
    ];
  }

  Future<FileTreeNode> _buildTree(
    Directory dir,
    int maxDepth,
    bool includeFiles,
    List<String> excludePatterns,
    int currentDepth,
  ) async {
    if (currentDepth >= maxDepth) {
      return FileTreeNode(
        name: p.basename(dir.path),
        path: dir.path,
        isDirectory: true,
        children: [],
      );
    }

    final entities = await dir.list().toList();
    final children = <FileTreeNode>[];

    for (final entity in entities) {
      final name = p.basename(entity.path);

      // Check exclusion patterns
      if (_shouldExclude(name, excludePatterns)) {
        continue;
      }

      if (entity is Directory) {
        final subtree = await _buildTree(
          entity,
          maxDepth,
          includeFiles,
          excludePatterns,
          currentDepth + 1,
        );
        children.add(subtree);
      } else if (includeFiles && entity is File) {
        final stat = await entity.stat();
        children.add(FileTreeNode(
          name: name,
          path: entity.path,
          isDirectory: false,
          size: stat.size,
        ));
      }
    }

    // Sort: directories first, then alphabetically
    children.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) return -1;
      if (!a.isDirectory && b.isDirectory) return 1;
      return a.name.compareTo(b.name);
    });

    return FileTreeNode(
      name: p.basename(dir.path),
      path: dir.path,
      isDirectory: true,
      children: children,
    );
  }

  bool _shouldExclude(String name, List<String> patterns) {
    for (final pattern in patterns) {
      if (pattern.contains('*')) {
        // Wildcard matching
        final regex = RegExp('^${pattern.replaceAll('*', '.*')}\$');
        if (regex.hasMatch(name)) return true;
      } else {
        // Exact match
        if (name == pattern) return true;
      }
    }
    return false;
  }
}
