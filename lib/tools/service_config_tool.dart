/// Service Config Tool
///
/// Get service configuration (Redis, Database, etc).
library serverpod_boost.tools.service_config_tool;

import 'package:yaml/yaml.dart';

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class ServiceConfigTool extends McpToolBase {
  @override
  String get name => 'service_config';

  @override
  String get description => '''
Get service configuration (Redis, Database, etc).

Reads service configuration from the config files.
Returns connection parameters and settings.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'service': McpSchema.enumProperty(
        values: ['database', 'redis', 'apiServer', 'insightsServer', 'webServer'],
        description: 'Service to get config for',
        required: true,
      ),
      'environment': McpSchema.enumProperty(
        values: ['development', 'production', 'staging', 'test'],
        description: 'Environment to read config for',
        defaultValue: 'development',
      ),
    },
    required: ['service'],
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final service = params['service'] as String;
    final environment = params['environment'] as String? ?? 'development';

    final project = ServerPodLocator.getProject();
    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    final configFile = project.getConfigFile(environment);
    if (configFile == null) {
      return {
        'error': 'Config file not found',
        'environment': environment,
      };
    }

    try {
      final content = await configFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;

      if (yaml == null) {
        return {
          'error': 'Failed to parse config',
          'file': configFile.path,
        };
      }

      final serviceConfig = yaml[service];
      if (serviceConfig == null) {
        return {
          'error': 'Service not found in config',
          'service': service,
          'availableServices': yaml.keys.toList(),
        };
      }

      return {
        'service': service,
        'environment': environment,
        'config': _yamlToDynamic(serviceConfig),
        'file': configFile.path,
      };
    } catch (e) {
      return {
        'error': 'Failed to read config',
        'message': e.toString(),
      };
    }
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
