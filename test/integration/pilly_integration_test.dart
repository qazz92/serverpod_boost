/// Pilly Project Integration Tests
///
/// Tests ServerPod Boost against the real Pilly project.
library serverpod_boost.test.integration.pilly_integration_test;

import 'dart:io';

import 'package:test/test.dart';

import '../../lib/tool_registry.dart';
import '../../lib/mcp/mcp_tool.dart';
import '../../lib/mcp/mcp_protocol.dart';
import '../../lib/serverpod/serverpod_locator.dart';

void main() {
  group('Pilly Project Integration Tests', () {
    late McpToolRegistry registry;
    late String originalDir;

    setUp(() {
      registry = McpToolRegistry();
      BoostToolRegistry.registerAll(registry);

      // Save original directory
      originalDir = Directory.current.path;

      // Change to Pilly project root
      Directory.current = '/Users/musinsa/always_summer/pilly';

      // Reset cache to pick up new project
      ServerPodLocator.resetCache();
    });

    tearDown(() {
      // Restore original directory
      Directory.current = originalDir;

      // Reset cache
      ServerPodLocator.resetCache();
    });

    test('detects Pilly as valid ServerPod project', () {
      final project = ServerPodLocator.getProject();

      expect(project, isNotNull);
      expect(project!.isValid, isTrue);

      // Verify package structure
      expect(project.rootPath, contains('pilly'));
      expect(project.serverPath, contains('pilly_server'));
      expect(project.clientPath, contains('pilly_client'));
      expect(project.flutterPath, contains('pilly_flutter'));
    });

    test('application_info returns Pilly project info', () async {
      final tool = registry.getTool('application_info')!;
      final request = McpRequest(
        id: 'test',
        method: 'application_info',
        params: {},
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      expect(result.containsKey('project'), isTrue);
      expect(result['project']['root'], contains('pilly'));
      expect(result['endpointCount'], greaterThan(0));
      expect(result['modelCount'], greaterThan(0));
    });

    test('list_endpoints finds greeting endpoint', () async {
      final tool = registry.getTool('list_endpoints')!;
      final request = McpRequest(
        id: 'test',
        method: 'list_endpoints',
        params: {},
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      final endpoints = result['endpoints'] as List;

      // Check for greeting endpoint
      final greeting = endpoints.firstWhere(
        (e) => e['name'] == 'greeting',
        orElse: () => <String, dynamic>{},
      );

      expect(greeting, isNotNull);
      expect(greeting, isNotEmpty);
      expect(greeting['methodCount'], greaterThan(0));
    });

    test('endpoint_methods returns greeting methods', () async {
      final tool = registry.getTool('endpoint_methods')!;
      final request = McpRequest(
        id: 'test',
        method: 'endpoint_methods',
        params: {'endpoint_name': 'greeting'},
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      final methods = result['methods'] as List;

      expect(methods, isNotEmpty);
      // Should have 'hello' method
      final helloMethod = methods.firstWhere(
        (m) => m['name'] == 'hello',
        orElse: () => <String, Object>{},
      );
      expect(helloMethod, isNotNull);
      expect(helloMethod, isNotEmpty);
    });

    test('list_models finds Greeting model', () async {
      final tool = registry.getTool('list_models')!;
      final request = McpRequest(
        id: 'test',
        method: 'list_models',
        params: {},
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      final models = result['models'] as List;

      // Check for Greeting model
      final greeting = models.firstWhere(
        (m) => m['className'] == 'Greeting',
        orElse: () => <String, dynamic>{},
      );

      expect(greeting, isNotNull);
      expect(greeting, isNotEmpty);
      expect(greeting['fields'], isNotEmpty);
      expect(greeting['namespace'], contains('greetings'));
    });

    test('model_inspector returns Greeting field details', () async {
      final tool = registry.getTool('model_inspector')!;
      final request = McpRequest(
        id: 'test',
        method: 'model_inspector',
        params: {'model_name': 'Greeting'},
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      expect(result['className'], equals('Greeting'));
      expect(result['fields'], isNotEmpty);

      // Should have message, author, timestamp fields
      final fieldNames = result['fields'].map((f) => f['name']).toList();
      expect(fieldNames, contains('message'));
      expect(fieldNames, contains('author'));
    });

    test('config_reader reads development config', () async {
      final tool = registry.getTool('config_reader')!;
      final request = McpRequest(
        id: 'test',
        method: 'config_reader',
        params: {'environment': 'development'},
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      expect(result.containsKey('config'), isTrue);
      expect(result['environment'], equals('development'));
    });

    test('project_structure returns file tree', () async {
      final tool = registry.getTool('project_structure')!;
      final request = McpRequest(
        id: 'test',
        method: 'project_structure',
        params: {'depth': 2},
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      expect(result.containsKey('root'), isTrue);
      expect(result['root']['type'], equals('directory'));
      expect(result['root']['children'], isNotEmpty);
    });

    test('find_files locates endpoint files', () async {
      final tool = registry.getTool('find_files')!;
      final request = McpRequest(
        id: 'test',
        method: 'find_files',
        params: {
          'pattern': '**/*_endpoint.dart',
          'max_results': 10,
        },
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      final files = result['files'] as List;

      expect(files, isNotEmpty);
      // Should find greeting_endpoint.dart
      final greetingEndpoint = files.firstWhere(
        (f) => f['name'].contains('greeting'),
        orElse: () => <String, dynamic>{},
      );
      expect(greetingEndpoint, isNotNull);
      expect(greetingEndpoint, isNotEmpty);
    });

    test('search_code finds hello method', () async {
      final tool = registry.getTool('search_code')!;
      final request = McpRequest(
        id: 'test',
        method: 'search_code',
        params: {
          'query': 'Future<Greeting> hello',
          'file_pattern': '*.dart',
          'max_results': 10,
        },
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      final results = result['results'] as List;

      expect(results, isNotEmpty);
      // Should find in greeting_endpoint.dart
      final match = results.firstWhere(
        (r) => (r['relativePath'] as String).contains('greeting'),
        orElse: () => <String, dynamic>{},
      );
      expect(match, isNotNull);
      expect(match, isNotEmpty);
      expect(match['line'], contains('hello'));
    });

    test('service_config reads database config', () async {
      final tool = registry.getTool('service_config')!;
      final request = McpRequest(
        id: 'test',
        method: 'service_config',
        params: {
          'service': 'database',
          'environment': 'development',
        },
      );

      final response = await tool.execute(request);

      expect(response.isError, isFalse);

      final result = response.result as Map;
      expect(result['service'], equals('database'));
      expect(result.containsKey('config'), isTrue);
    });
  });
}
