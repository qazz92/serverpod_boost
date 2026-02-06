import 'agent.dart';
import '../serverpod/serverpod_locator.dart';

/// OpenCode agent implementation
///
/// OpenCode uses a different config format than Claude Code.
/// - Config path: `.opencode/mcp_config.json`
/// - Config format: Uses `servers` instead of `mcpServers`
class OpenCodeAgent extends Agent {
  @override
  String get name => 'opencode';

  @override
  String get displayName => 'OpenCode';

  @override
  String get configPath => '.opencode/mcp_config.json';

  @override
  String? get userConfigPath => null; // OpenCode uses project-local config

  @override
  String get mcpConfigKey => 'servers';

  @override
  Map<String, dynamic> get defaultMcpConfig => {
        'servers': <String, dynamic>{},
      };

  @override
  Map<String, dynamic> generateMcpConfig(ServerPodProject project) {
    return {
      'servers': {
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
    // Check for OpenCode installation
    return await detectByCommand('which opencode');
  }

  @override
  Future<bool> isInProject(String basePath) async {
    return await detectByFiles(basePath, projectDetectionConfig());
  }

  @override
  Map<String, dynamic> systemDetectionConfig() {
    return {
      'command': 'which opencode',
    };
  }

  @override
  Map<String, dynamic> projectDetectionConfig() {
    return {
      'paths': <String>['.opencode'],
      'files': <String>['.opencode/mcp_config.json'],
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
