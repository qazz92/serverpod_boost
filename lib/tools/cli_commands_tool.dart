/// CLI Commands Tool
///
/// Lists and categorizes available ServerPod CLI commands from the bin/ directory.
library serverpod_boost.tools.cli_commands_tool;

import 'dart:io';
import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class CliCommandsTool extends McpToolBase {
  @override
  String get name => 'cli_commands';

  @override
  String get description => 'List available ServerPod CLI commands';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'category': {
        'type': 'string',
        'description': 'Filter by category',
      },
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final category = params['category'] as String?;
    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    try {
      // Find bin directory
      final binDirectory = Directory.fromUri(Uri.file(project.rootPath).resolve('bin/'));
      if (!await binDirectory.exists()) {
        return {'error': 'No bin/ directory found'};
      }

      // Collect .dart files in bin directory (excluding this file itself)
      final dartFiles = binDirectory.listSync()
          .where((entity) =>
            entity is File &&
            entity.uri.pathSegments.last.endsWith('.dart') &&
            !entity.uri.pathSegments.last.contains('boost.dart') // Exclude main entry point
          )
          .cast<File>();

      final commands = <Map<String, dynamic>>[];
      final categories = <String>{};

      for (final file in dartFiles) {
        final command = await _parseCommandFile(file, project);
        if (command != null) {
          if (category == null || command['category'] == category) {
            commands.add(command);
            categories.add(command['category']);
          }
        }
      }

      return {
        'commands': commands,
        'categories': categories.toList(),
        'count': commands.length,
      };
    } catch (e) {
      return {'error': 'Failed to parse CLI commands: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>?> _parseCommandFile(File file, ServerPodProject project) async {
    try {
      final content = await file.readAsString();
      final fileName = file.uri.pathSegments.last;

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
        'file': file.uri.pathSegments.join('/'),
        'relativePath': 'bin/$fileName',
        'path': file.uri.toFilePath(),
      };
    } catch (e) {
      print('Error parsing command file ${file.path}: $e');
      return null;
    }
  }

  String _extractDescription(String content) {
    // Look for doc comments /// at the beginning of the file
    final lines = content.split('\n');
    String description = '';
    bool inDocComment = false;
    int docCommentLineCount = 0;
    const maxDocLines = 5; // Only look at first 5 lines for description

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
        // Empty line in doc comment
        docCommentLineCount++;
        if (description.isNotEmpty) description += ' ';
      } else if (!line.startsWith('import') && !line.startsWith('library')) {
        // End of doc comments, start of actual code
        break;
      }
    }

    // If no description found, use a default based on command name
    if (description.isEmpty) {
      switch (_extractCommandNameFromContent(content)) {
        case 'run':
          return 'Start the ServerPod server';
        case 'build':
          return 'Build the ServerPod project';
        case 'test':
          return 'Run tests for the ServerPod project';
        case 'migrate':
          return 'Run database migrations';
        case 'generate':
          return 'Generate code from models';
        case 'serve':
          return 'Start the development server';
        default:
          return 'CLI command for ServerPod development';
      }
    }

    return description;
  }

  String _determineCategory(String fileName) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.contains('migration') || lowerName.contains('migrate')) {
      return 'migration';
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
      return 'auth';
    } else {
      return 'tools';
    }
  }

  String _extractCommandNameFromContent(String content) {
    // Try to find main function or similar command patterns
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.contains('void main(') || line.contains('Future<void> main(')) {
        // Extract after 'main('
        final mainMatch = RegExp(r'main\(\s*([^)]*)\s*\)').firstMatch(line);
        if (mainMatch != null) {
          final args = mainMatch.group(1) ?? '';
          if (args.contains('run') || args.contains('serve')) {
            return 'run';
          }
        }
        return 'run';
      }

      // Look for command definitions (simplified)
      if (line.contains('run') && line.contains('Command')) {
        return 'run';
      } else if (line.contains('build') && line.contains('Command')) {
        return 'build';
      } else if (line.contains('test') && line.contains('Command')) {
        return 'test';
      }
    }

    return 'unknown';
  }
}