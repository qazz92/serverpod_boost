/// List Endpoints Tool
library serverpod_boost.tools.list_endpoints_tool;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';
import '../serverpod/method_parser.dart';

/// List Endpoints Tool - List all endpoints in the project
class ListEndpointsTool extends McpToolBase {
  @override
  String get name => 'list_endpoints';

  @override
  String get description => '''
List all endpoints in the ServerPod project.

Returns endpoint names, file paths, and method counts.
Use filter parameter to search for specific endpoints.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'filter': McpSchema.string(description: 'Filter endpoints by name pattern'),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final filter = params['filter'] as String?;
    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    final endpointFiles = project.endpointFiles;
    final results = <Map<String, dynamic>>[];

    for (final file in endpointFiles) {
      final name = _extractEndpointName(file);

      // Apply filter if provided
      if (filter != null && !name.toLowerCase().contains(filter.toLowerCase())) {
        continue;
      }

      final methods = MethodParser.parseFile(file);

      results.add({
        'name': name,
        'file': file,
        'methodCount': methods.length,
        'methods': methods.map((m) => {
          'name': m.name,
          'returnType': m.returnType,
          'parameters': m.userParameters.map((p) => {
            'type': p.type,
            'name': p.name,
          }).toList(),
        }).toList(),
      });
    }

    return {
      'endpoints': results,
      'count': results.length,
    };
  }

  /// Extract endpoint name from file path
  String _extractEndpointName(String filePath) {
    final parts = filePath.split('/');
    final filename = parts.last;
    return filename.replaceAll('_endpoint.dart', '');
  }
}
