/// Model Inspector Tool
///
/// Get detailed model field information.
library serverpod_boost.tools.model_inspector_tool;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';
import '../serverpod/spy_yaml_parser.dart';

class ModelInspectorTool extends McpToolBase {
  @override
  String get name => 'model_inspector';

  @override
  String get description => '''
Get detailed information about a protocol model:
- All fields with types
- Field nullability
- Model namespace
- Source file location

Pass the model class name (e.g., 'Greeting', 'User').
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'model_name': McpSchema.string(
        description: 'Name of the model class (e.g., "Greeting", "User")',
      ),
    },
    required: ['model_name'],
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final modelName = params['model_name'] as String;
    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    // Find the model
    final models = project.models;
    SpyYamlModel? targetModel;

    for (final model in models) {
      if (model.className == modelName) {
        targetModel = model;
        break;
      }
    }

    if (targetModel == null) {
      return {
        'error': 'Model not found',
        'model_name': modelName,
        'available_models': models.map((m) => m.className).toList(),
      };
    }

    return {
      'className': targetModel.className,
      'namespace': targetModel.namespace,
      'sourceFile': targetModel.filePath,
      'fieldCount': targetModel.fields.length,
      'fields': targetModel.fields.map((f) => {
        'name': f.name,
        'type': f.type,
        'dartType': f.dartType,
        'isOptional': f.isOptional,
        'isScalar': _isScalarType(f.type),
        'isRelation': _isRelationType(f.type),
      }).toList(),
    };
  }

  bool _isScalarType(String type) {
    const scalars = {
      'String', 'int', 'double', 'bool', 'num', 'DateTime',
      'Duration', 'ByteData', 'Uri', 'BigInt',
    };
    return scalars.contains(type);
  }

  bool _isRelationType(String type) {
    // Relations are models that don't match scalar types
    return !_isScalarType(type) && !type.startsWith('List<') && !type.startsWith('Map<');
  }
}
