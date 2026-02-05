/// Call Endpoint Tool
///
/// Call endpoint method for testing (placeholder).
library serverpod_boost.tools.call_endpoint_tool;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';
import '../serverpod/method_parser.dart';

class CallEndpointTool extends McpToolBase {
  @override
  String get name => 'call_endpoint';

  @override
  String get description => '''
Call an endpoint method for testing purposes.

NOTE: This is a placeholder for future implementation.
Currently returns method signature information without actual execution.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'endpoint': McpSchema.string(
        description: 'Endpoint name (e.g., "greeting")',
        required: true,
      ),
      'method': McpSchema.string(
        description: 'Method name (e.g., "hello")',
        required: true,
      ),
      'parameters': McpSchema.object(
        description: 'Method parameters (excluding Session)',
      ),
    },
    required: ['endpoint', 'method'],
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final endpoint = params['endpoint'] as String;
    final method = params['method'] as String;
    final parameters = params['parameters'] as Map<String, dynamic>?;

    final project = ServerPodLocator.getProject();
    if (project == null || !project.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    // Find the endpoint
    String? endpointFile;
    for (final file in project.endpointFiles) {
      final name = _extractEndpointName(file);
      if (name == endpoint) {
        endpointFile = file;
        break;
      }
    }

    if (endpointFile == null) {
      return {
        'error': 'Endpoint not found',
        'endpoint': endpoint,
        'available': project.endpointFiles.map(_extractEndpointName).toList(),
      };
    }

    // Parse methods
    final methods = MethodParser.parseFile(endpointFile);
    final targetMethod = methods.firstWhere(
      (m) => m.name == method,
      orElse: () => throw Exception('Method not found'),
    );

    // Validate parameters
    final userParams = targetMethod.userParameters;
    final paramErrors = <String>[];

    for (final param in userParams) {
      if (parameters != null && !parameters.containsKey(param.name)) {
        paramErrors.add('Missing required parameter: ${param.name}');
      }
    }

    if (paramErrors.isNotEmpty) {
      return {
        'error': 'Parameter validation failed',
        'errors': paramErrors,
        'expectedParameters': userParams.map((p) => {
          'name': p.name,
          'type': p.type,
        }).toList(),
      };
    }

    // Return method info (placeholder for actual execution)
    return {
      'status': 'placeholder',
      'message': 'Endpoint calling not yet implemented',
      'endpoint': endpoint,
      'method': method,
      'signature': targetMethod.signature,
      'returnType': targetMethod.returnType,
      'parameters': parameters,
      'note': 'This would call the endpoint method in a future implementation',
    };
  }

  String _extractEndpointName(String filePath) {
    final parts = filePath.split('/');
    final filename = parts.last;
    return filename.replaceAll('_endpoint.dart', '');
  }
}
