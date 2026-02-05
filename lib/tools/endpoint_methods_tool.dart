/// Endpoint Methods Tool
///
/// Get detailed information about an endpoint's methods.
library serverpod_boost.tools.endpoint_methods_tool;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';
import '../serverpod/method_parser.dart';

class EndpointMethodsTool extends McpToolBase {
  @override
  String get name => 'endpoint_methods';

  @override
  String get description => '''
Get detailed information about an endpoint's methods:
- Method names
- Parameter types and names
- Return types

Pass the endpoint name (e.g., 'greeting', 'emailIdp').
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'endpoint_name': McpSchema.string(
        description: 'Name of the endpoint (e.g., "greeting")',
      ),
    },
    required: ['endpoint_name'],
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final endpointName = params['endpoint_name'] as String;
    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    // Find the endpoint file
    String? endpointFile;
    for (final file in project.endpointFiles) {
      final name = _extractEndpointName(file);
      if (name == endpointName) {
        endpointFile = file;
        break;
      }
    }

    if (endpointFile == null) {
      return {
        'error': 'Endpoint not found',
        'endpoint_name': endpointName,
        'available_endpoints': project.endpointFiles.map(_extractEndpointName).toList(),
      };
    }

    final methods = MethodParser.parseFile(endpointFile);

    return {
      'endpoint': endpointName,
      'file': endpointFile,
      'methods': methods.map((m) => {
        'name': m.name,
        'returnType': m.returnType,
        'signature': m.signature,
        'parameters': m.parameters.map((p) => {
          'type': p.type,
          'name': p.name,
          'isSession': p.isSession,
        }).toList(),
        'userParameters': m.userParameters.map((p) => {
          'type': p.type,
          'name': p.name,
        }).toList(),
      }).toList(),
      'methodCount': methods.length,
    };
  }

  String _extractEndpointName(String filePath) {
    final parts = filePath.split('/');
    final filename = parts.last;
    return filename.replaceAll('_endpoint.dart', '');
  }
}
