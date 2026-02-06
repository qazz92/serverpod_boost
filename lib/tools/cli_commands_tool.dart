/// CLI Commands Tool
///
/// Lists and categorizes available ServerPod CLI commands.
/// Returns both ServerPod built-in commands and project-specific bin/ scripts.
library serverpod_boost.tools.cli_commands_tool;

import 'dart:io';
import 'package:path/path.dart' as p;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class CliCommandsTool extends McpToolBase {
  /// ServerPod built-in commands (always available)
  static const List<Map<String, dynamic>> _serverpodBuiltInCommands = [
    {
      'name': 'run',
      'description': 'Start the ServerPod server in development mode',
      'category': 'server',
      'usage': 'dart run serverpod run',
      'isBuiltIn': true,
    },
    {
      'name': 'migrate',
      'description': 'Create and apply database migrations',
      'category': 'database',
      'usage': 'dart run serverpod migrate',
      'isBuiltIn': true,
    },
    {
      'name': 'generate',
      'description': 'Generate protocol buffers and model classes from YAML definitions',
      'category': 'build',
      'usage': 'dart run serverpod generate',
      'isBuiltIn': true,
    },
    {
      'name': 'test',
      'description': 'Run tests for the ServerPod project',
      'category': 'test',
      'usage': 'dart run serverpod test',
      'isBuiltIn': true,
    },
    {
      'name': 'docker',
      'description': 'Manage Docker containers for development',
      'category': 'deployment',
      'usage': 'dart run serverpod docker',
      'isBuiltIn': true,
    },
    {
      'name': 'cloud',
      'description': 'Deploy and manage Serverpod Cloud services',
      'category': 'deployment',
      'usage': 'dart run serverpod cloud',
      'isBuiltIn': true,
    },
    {
      'name': 'analyze',
      'description': 'Analyze code quality and find potential issues',
      'category': 'tools',
      'usage': 'dart analyze',
      'isBuiltIn': true,
    },
    {
      'name': 'format',
      'description': 'Format Dart code according to Dart style guidelines',
      'category': 'tools',
      'usage': 'dart format .',
      'isBuiltIn': true,
    },
  ];

  @override
  String get name => 'cli_commands';

  @override
  String get description => '''
List available ServerPod CLI commands.

Returns both:
- ServerPod built-in commands (run, migrate, generate, test, docker, cloud, analyze, format)
- Project-specific commands from the bin/ directory (if any)

Each command includes its name, description, category, and usage example.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'category': McpSchema.string(
        description: 'Filter by category (e.g., "server", "database", "build", "test", "deployment", "tools")',
      ),
      'source': McpSchema.enumProperty(
        values: ['all', 'built-in', 'custom'],
        description: 'Filter by command source (default: all)',
        defaultValue: 'all',
      ),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final category = params['category'] as String?;
    final source = params['source'] as String? ?? 'all';

    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {
        'error': 'Not a valid ServerPod project',
        'hint': 'Run this command from a ServerPod project directory',
      };
    }

    try {
      // Start with built-in commands
      var commands = <Map<String, dynamic>>[
        ..._serverpodBuiltInCommands,
      ];

      // Add custom commands from bin/ if exists
      final customCommands = await _loadCustomCommands(project);
      commands.addAll(customCommands);

      // Apply category filter
      if (category != null) {
        commands = commands
            .where((cmd) => cmd['category'] == category)
            .toList();
      }

      // Apply source filter
      if (source == 'built-in') {
        commands = commands.where((cmd) => cmd['isBuiltIn'] == true).toList();
      } else if (source == 'custom') {
        commands = commands.where((cmd) => cmd['isBuiltIn'] == false).toList();
      }

      // Group by category
      final categories = <String, int>{};
      for (final cmd in commands) {
        final cat = cmd['category'] as String;
        categories[cat] = (categories[cat] ?? 0) + 1;
      }

      final builtInCount = commands.where((cmd) => cmd['isBuiltIn'] == true).length;
      final customCount = commands.where((cmd) => cmd['isBuiltIn'] == false).length;

      return {
        'commands': commands,
        'categories': categories,
        'count': commands.length,
        'builtInCount': builtInCount,
        'customCount': customCount,
        'serverpodVersion': await _getServerpodVersion(project),
      };
    } catch (e) {
      return {
        'error': 'Failed to list CLI commands: ${e.toString()}',
      };
    }
  }

  /// Load custom commands from project's bin/ directory
  Future<List<Map<String, dynamic>>> _loadCustomCommands(ServerPodProject project) async {
    final commands = <Map<String, dynamic>>[];

    try {
      // Find bin directory
      final binDirectory = Directory(p.join(project.rootPath, 'bin'));
      if (!await binDirectory.exists()) {
        return commands;
      }

      // Collect .dart files in bin directory
      final dartFiles = binDirectory.listSync()
          .where((entity) =>
            entity is File &&
            entity.uri.pathSegments.last.endsWith('.dart') &&
            !entity.uri.pathSegments.last.contains('main.dart') // Exclude main entry point
          )
          .cast<File>();

      for (final file in dartFiles) {
        final command = await _parseCommandFile(file, project);
        if (command != null) {
          commands.add(command);
        }
      }
    } catch (e) {
      // Silently ignore errors when loading custom commands
    }

    return commands;
  }

  /// Parse a command file to extract metadata
  Future<Map<String, dynamic>?> _parseCommandFile(File file, ServerPodProject project) async {
    try {
      final content = await file.readAsString();
      final fileName = p.basename(file.path);

      // Extract command name from filename
      final commandName = fileName.replaceFirst('.dart', '');

      // Extract description from doc comments
      final description = _extractDescription(content);

      // Determine category based on filename patterns
      final category = _determineCategory(fileName);

      return {
        'name': commandName,
        'description': description,
        'category': category,
        'file': fileName,
        'relativePath': 'bin/$fileName',
        'path': file.path,
        'isBuiltIn': false,
      };
    } catch (e) {
      return null;
    }
  }

  /// Extract description from doc comments
  String _extractDescription(String content) {
    final lines = content.split('\n');
    String description = '';
    bool inDocComment = false;
    int docCommentLineCount = 0;
    const maxDocLines = 5;

    for (int i = 0; i < lines.length && docCommentLineCount < maxDocLines; i++) {
      final line = lines[i].trim();

      if (line.startsWith('///')) {
        inDocComment = true;
        docCommentLineCount++;
        final commentText = line.substring(3).trim();
        if (commentText.isNotEmpty) {
          if (description.isNotEmpty) description += ' ';
          description += commentText;
        }
      } else if (inDocComment && line.trim().isEmpty) {
        docCommentLineCount++;
        if (description.isNotEmpty) description += ' ';
      } else if (!line.startsWith('import') && !line.startsWith('library')) {
        break;
      }
    }

    if (description.isEmpty) {
      return 'Custom CLI command';
    }

    return description;
  }

  /// Determine category from filename patterns
  String _determineCategory(String fileName) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.contains('migration') || lowerName.contains('migrate')) {
      return 'database';
    } else if (lowerName.contains('db') || lowerName.contains('database')) {
      return 'database';
    } else if (lowerName.contains('server') || lowerName.contains('run') || lowerName.contains('serve')) {
      return 'server';
    } else if (lowerName.contains('build') || lowerName.contains('generate')) {
      return 'build';
    } else if (lowerName.contains('test')) {
      return 'test';
    } else if (lowerName.contains('deploy') || lowerName.contains('prod')) {
      return 'deployment';
    } else if (lowerName.contains('auth') || lowerName.contains('user')) {
      return 'authentication';
    } else {
      return 'tools';
    }
  }

  /// Get ServerPod version from pubspec.yaml
  Future<String> _getServerpodVersion(ServerPodProject project) async {
    final serverPath = project.serverPath;
    if (serverPath == null) return 'unknown';

    try {
      final pubspec = File(p.join(serverPath, 'pubspec.yaml'));
      if (await pubspec.exists()) {
        final content = await pubspec.readAsString();
        final match = RegExp(r'serverpod:\s*\^?([\d.]+)').firstMatch(content);
        return match?.group(1) ?? 'unknown';
      }
    } catch (e) {
      // Ignore
    }

    return 'unknown';
  }
}
