/// Application Info Tool
///
/// Get comprehensive ServerPod application information.
library serverpod_boost.tools.application_info_tool;

import 'dart:io';
import 'package:yaml/yaml.dart';

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';
import '../serverpod/method_parser.dart';

/// Application Info Tool - Get project information
class ApplicationInfoTool extends McpToolBase {
  @override
  String get name => 'application_info';

  @override
  String get description => '''
Get comprehensive ServerPod application information including:
- Dart SDK version
- ServerPod version
- Database configuration
- All endpoints with their methods
- All protocol models
- Project paths

Use this tool at the start of each conversation to understand the project.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {},
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {
        'error': 'Not a valid ServerPod project',
        'message': 'Could not detect a valid ServerPod project structure',
      };
    }

    // Get ServerPod version from pubspec.yaml
    final serverpodVersion = await _getServerpodVersion(project.serverPath!);

    // Get database config
    final dbConfig = await _getDatabaseConfig(project);

    // Get all endpoints
    final endpointFiles = project.endpointFiles;
    final endpoints = <String, dynamic>{};

    for (final file in endpointFiles) {
      final methods = await _parseEndpointMethods(file);
      // Extract endpoint name from file path
      final name = _extractEndpointName(file);
      endpoints[name] = {
        'file': file,
        'methods': methods,
      };
    }

    // Get all models
    final models = project.models;
    final modelList = models.map((m) => {
      'className': m.className,
      'namespace': m.namespace,
      'fields': m.fields.map((f) => {
        'name': f.name,
        'type': f.dartType,
      }).toList(),
    }).toList();

    return {
      'project': {
        'root': project.rootPath,
        'server': project.serverPath,
        'client': project.clientPath,
        'flutter': project.flutterPath,
        'config': project.configPath,
        'migrations': project.migrationsPath,
      },
      'versions': {
        'dart': _getDartVersion(),
        'serverpod': serverpodVersion,
      },
      'database': dbConfig,
      'endpoints': endpoints,
      'models': modelList,
      'endpointCount': endpoints.length,
      'modelCount': models.length,
    };
  }

  /// Get Dart SDK version
  String _getDartVersion() {
    return Platform.version.split(' ').first;
  }

  /// Get ServerPod version from pubspec.yaml
  Future<String> _getServerpodVersion(String serverPath) async {
    final pubspec = File('$serverPath/pubspec.yaml');
    if (pubspec.existsSync()) {
      final content = await pubspec.readAsString();
      final match = RegExp(r'serverpod:\s*\^?([\d.]+)').firstMatch(content);
      return match?.group(1) ?? 'unknown';
    }
    return 'unknown';
  }

  /// Get database configuration from config file
  Future<Map<String, dynamic>?> _getDatabaseConfig(ServerPodProject project) async {
    final configFile = project.getConfigFile('development');
    if (configFile == null) return null;

    final content = await configFile.readAsString();
    final yaml = loadYaml(content) as YamlMap?;

    final db = yaml?['database'] as YamlMap?;
    if (db == null) return null;

    return {
      'host': db['host'],
      'port': db['port'],
      'name': db['name'],
      'user': db['user'],
      'normalized': true,
    };
  }

  /// Parse endpoint methods from file
  Future<List<String>> _parseEndpointMethods(String file) async {
    final methods = MethodParser.parseFile(file);
    return methods.map((m) => m.signature).toList();
  }

  /// Extract endpoint name from file path
  String _extractEndpointName(String filePath) {
    final parts = filePath.split('/');
    final filename = parts.last;
    return filename.replaceAll('_endpoint.dart', '');
  }
}
