import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../serverpod/serverpod_locator.dart';

/// Abstract base class for AI editor agents
abstract class Agent {
  /// Agent name (e.g., 'claude-code', 'opencode')
  String get name;

  /// Display name for UI
  String get displayName;

  /// Config file path relative to project root
  String get configPath;

  /// Config file path relative to user home (optional)
  String? get userConfigPath;

  /// Get key for MCP configuration (usually 'mcpServers')
  String get mcpConfigKey => 'mcpServers';

  /// Get default MCP configuration structure
  Map<String, dynamic> get defaultMcpConfig => {};

  /// Generate MCP config for this agent
  Map<String, dynamic> generateMcpConfig(ServerPodProject project);

  /// Write MCP config to project
  Future<void> writeMcpConfig(
    ServerPodProject project,
    Map<String, dynamic> config,
  );

  /// Check if agent is installed on the system
  Future<bool> isInstalled();

  /// Check if agent is used in the current project
  Future<bool> isInProject(String basePath);

  /// List supported file types
  List<String> get supportedFileTypes;

  /// Get detection config for system-wide installation
  Map<String, dynamic> systemDetectionConfig();

  /// Get detection config for project-specific detection
  Map<String, dynamic> projectDetectionConfig();

  /// Detect if agent is installed on system using command
  Future<bool> detectByCommand(String command) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'cmd' : 'sh',
        Platform.isWindows ? ['/c', command] : ['-c', command],
        runInShell: true,
      );

      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Detect if agent is in project by checking files/directories
  Future<bool> detectByFiles(String basePath, Map<String, dynamic> config) async {
    final paths = config['paths'] as List<dynamic>?;
    final files = config['files'] as List<dynamic>?;

    // Check paths
    if (paths != null) {
      for (final path in paths) {
        final dir = Directory(p.join(basePath, path as String));
        if (await dir.exists()) {
          return true;
        }
      }
    }

    // Check files
    if (files != null) {
      for (final file in files) {
        final f = File(p.join(basePath, file as String));
        if (await f.exists()) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get absolute path to config file
  String getConfigPath(String projectRoot) {
    return p.join(projectRoot, configPath);
  }

  /// Get absolute path to user config file (if applicable)
  String? getUserConfigPath() {
    if (userConfigPath == null) return null;
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return null;
    return p.join(home, userConfigPath!);
  }

  /// Write MCP configuration to file
  Future<void> writeMcpConfigToFile(
    String configFilePath,
    Map<String, dynamic> config,
  ) async {
    final configFile = File(configFilePath);
    Map<String, dynamic> existingConfig = {};

    // Read existing config if it exists
    if (await configFile.exists()) {
      try {
        final content = await configFile.readAsString();
        if (content.isNotEmpty) {
          existingConfig = jsonDecode(content) as Map<String, dynamic>;
        } else {
          existingConfig = defaultMcpConfig;
        }
      } catch (e) {
        // If parsing fails, start with default config
        existingConfig = defaultMcpConfig;
      }
    } else {
      existingConfig = defaultMcpConfig;
    }

    // Merge configs
    final mergedConfig = mergeConfig(existingConfig, config);

    // Create parent directory if it doesn't exist
    final parentDir = configFile.parent;
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    // Write config file with proper formatting
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(mergedConfig);
    await configFile.writeAsString(jsonString);
  }

  /// Merge new config with existing config
  Map<String, dynamic> mergeConfig(
    Map<String, dynamic> existing,
    Map<String, dynamic> generated,
  ) {
    final key = mcpConfigKey;
    final existingServersRaw = existing[key] as Map? ?? {};
    final generatedServersRaw = generated[key] as Map? ?? {};

    // Convert to Map<String, dynamic>
    final existingServers = existingServersRaw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
            existingServersRaw.cast<String, dynamic>(),
          );
    final generatedServers = generatedServersRaw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
            generatedServersRaw.cast<String, dynamic>(),
          );

    final mergedServers = Map<String, dynamic>.from(existingServers);
    mergedServers.addAll(generatedServers);

    return {
      ...existing,
      key: mergedServers,
    };
  }
}
