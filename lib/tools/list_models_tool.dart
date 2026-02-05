/// List Models Tool
///
/// List all protocol models in the project.
library serverpod_boost.tools.list_models_tool;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

class ListModelsTool extends McpToolBase {
  @override
  String get name => 'list_models';

  @override
  String get description => '''
List all protocol models defined in the ServerPod project.

Models are defined in .spy.yaml files and include all field definitions.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'filter': McpSchema.string(description: 'Filter models by name pattern'),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final filter = params['filter'] as String?;
    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    final models = project.models;
    final results = <Map<String, dynamic>>[];

    for (final model in models) {
      // Apply filter if provided
      if (filter != null && !model.className.toLowerCase().contains(filter.toLowerCase())) {
        continue;
      }

      results.add({
        'className': model.className,
        'namespace': model.namespace,
        'fieldCount': model.fields.length,
        'fields': model.fields.map((f) => {
          'name': f.name,
          'type': f.type,
          'dartType': f.dartType,
          'isOptional': f.isOptional,
        }).toList(),
        'sourceFile': model.filePath,
      });
    }

    return {
      'models': results,
      'count': results.length,
    };
  }
}
