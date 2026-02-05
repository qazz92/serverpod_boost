/// Config Reader Tool
///
/// Read ServerPod YAML configuration files.
library serverpod_boost.tools.config_reader_tool;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class ConfigReaderTool extends McpToolBase {
  @override
  String get name => 'config_reader';

  @override
  String get description => '''
Read ServerPod YAML configuration files (development.yaml, production.yaml, etc.)

Returns parsed configuration as JSON. Useful for understanding service setup,
database connections, Redis configuration, and server ports.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'environment': McpSchema.enumProperty(
        values: ['development', 'production', 'staging', 'test'],
        description: 'Environment to read config for',
        defaultValue: 'development',
      ),
      'section': McpSchema.string(description: 'Specific config section (optional)'),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final env = params['environment'] as String? ?? 'development';
    final section = params['section'] as String?;

    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    final configFile = project.getConfigFile(env);
    if (configFile == null) {
      return {
        'error': 'Config file not found',
        'environment': env,
        'available_configs': _listAvailableConfigs(project),
      };
    }

    final content = await configFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml == null) {
      return {
        'error': 'Failed to parse config file',
        'file': configFile.path,
      };
    }

    // Return full config or specific section
    if (section != null && yaml.containsKey(section)) {
      return {
        'environment': env,
        'section': section,
        'config': _yamlToDynamic(yaml[section]),
      };
    }

    return {
      'environment': env,
      'file': configFile.path,
      'config': _yamlToDynamic(yaml),
    };
  }

  List<String> _listAvailableConfigs(ServerPodProject project) {
    final configPath = project.configPath;
    if (configPath == null) return [];

    final dir = Directory(configPath);
    if (!dir.existsSync()) return [];

    return dir.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml') && !f.path.contains('passwords'))
        .map((f) => p.basenameWithoutExtension(f.path))
        .toList();
  }

  dynamic _yamlToDynamic(dynamic value) {
    if (value is YamlMap) {
      return Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), _yamlToDynamic(v))),
      );
    }
    if (value is YamlList) {
      return value.map(_yamlToDynamic).toList();
    }
    return value;
  }
}
