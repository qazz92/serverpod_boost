
import 'dart:io';
import 'package:path/path.dart' as p;

import 'agent.dart';
import '../serverpod/serverpod_locator.dart';

/// Claude Code agent implementation
///
/// Claude Code is Anthropic's official CLI for Claude.
/// - Config path: `.claude/mcp.json`
/// - Config format: Uses `mcpServers` key
class ClaudeCodeAgent extends Agent {
  @override
  String get name => 'claude-code';

  @override
  String get displayName => 'Claude Code';

  @override
  String get configPath => '.mcp.json';

  @override
  String? get userConfigPath {
    final home = Platform.environment['HOME'];
    if (home == null) return null;
    return p.join(home, '.claude', 'mcp.json');
  }

  @override
  Map<String, dynamic> get defaultMcpConfig => {
        'mcpServers': <String, dynamic>{},
      };

  @override
  Map<String, dynamic> generateMcpConfig(ServerPodProject project) {
    return {
      'mcpServers': {
        'serverpod-boost': {
          'command': _findDartExecutable(),
          'args': [
            'run',
            'serverpod_boost:boost',
            '--path=${project.rootPath}',
          ],
        },
      },
    };
  }

  @override
  Future<void> writeMcpConfig(
    ServerPodProject project,
    Map<String, dynamic> config,
  ) async {
    final configFilePath = getConfigPath(project.rootPath);
    await writeMcpConfigToFile(configFilePath, config);
  }

  @override
  Future<bool> isInstalled() async {
    // Check for Claude Code by looking for the command
    return await detectByCommand('which claude');
  }

  @override
  Future<bool> isInProject(String basePath) async {
    return await detectByFiles(basePath, projectDetectionConfig());
  }

  @override
  Map<String, dynamic> systemDetectionConfig() {
    return {
      'command': 'which claude',
    };
  }

  @override
  Map<String, dynamic> projectDetectionConfig() {
    return {
      'paths': <String>['.mcp.json'],
      'files': <String>['.mcp.json', 'CLAUDE.md'],
    };
  }

  @override
  List<String> get supportedFileTypes => ['.dart', '.yaml'];

  /// Find the Dart executable path
  ///
  /// In most cases, 'dart' in PATH will work. This could be enhanced
  /// to find the full path if needed.
  String _findDartExecutable() {
    return 'dart';
  }
}
