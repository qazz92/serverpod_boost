/// Unit tests for TemplateRenderer
library serverpod_boost.test.skills.template_renderer_test;

import 'package:test/test.dart';

import 'package:serverpod_boost/skills/template_renderer.dart';
import 'package:serverpod_boost/project_context.dart';

void main() {
  group('TemplateRenderer', () {
    late ProjectContext context;
    late TemplateRenderer renderer;

    setUp(() {
      context = const ProjectContext(
        projectName: 'test_project',
        serverpodVersion: '3.2.3',
        rootPath: '/path/to/project',
        databaseType: DatabaseType.postgres,
        hasEndpoints: true,
        hasModels: true,
        hasMigrations: true,
        usesRedis: false,
        endpoints: [
          EndpointInfo(name: 'user', file: 'lib/src/endpoints/user_endpoint.dart'),
          EndpointInfo(name: 'product', file: 'lib/src/endpoints/product_endpoint.dart'),
        ],
        models: [
          ModelInfo(name: 'User', file: 'lib/src/models/user.dart'),
          ModelInfo(name: 'Product', file: 'lib/src/models/product.dart'),
        ],
        migrations: [
          MigrationInfo(name: '0001_initial.dart', file: 'migrations/0001_initial.dart'),
        ],
      );

      renderer = TemplateRenderer(context: context);
    });

    test('renders simple variable substitution', () {
      final template = 'Project: {{project_name}}';
      final result = renderer.render(template);

      expect(result, equals('Project: test_project'));
    });

    test('renders multiple variables', () {
      final template = '''
Project: {{project_name}}
Version: {{serverpod_version}}
Database: {{database_type}}
''';

      final result = renderer.render(template);

      expect(result, contains('Project: test_project'));
      expect(result, contains('Version: 3.2.3'));
      expect(result, contains('Database: postgres'));
    });

    test('renders boolean conditionals', () {
      final template = '''
{{#has_endpoints}}
This project has endpoints.
{{/has_endpoints}}

{{#uses_redis}}
This project uses Redis.
{{/uses_redis}}

{{^uses_redis}}
This project does not use Redis.
{{/uses_redis}}
''';

      final result = renderer.render(template);

      expect(result, contains('This project has endpoints.'));
      expect(result, contains('This project does not use Redis.'));
      expect(result, isNot(contains('This project uses Redis.')));
    });

    test('renders loops', () {
      final template = '''
Endpoints:
{{#endpoints}}
- {{name}} ({{file}})
{{/endpoints}}
''';

      final result = renderer.render(template);

      expect(result, contains('- user (lib/src/endpoints/user_endpoint.dart)'));
      expect(result, contains('- product (lib/src/endpoints/product_endpoint.dart)'));
    });

    test('renders nested structures', () {
      final template = '''
{{#has_models}}
Models: {{model_count}}
{{#models}}
- {{class_name}}: {{file}}
{{/models}}
{{/has_models}}
''';

      final result = renderer.render(template);

      expect(result, contains('Models: 2'));
      expect(result, contains('- User: lib/src/models/user.dart'));
      expect(result, contains('- Product: lib/src/models/product.dart'));
    });

    test('renders inverted conditionals', () {
      final template = '''
{{#has_endpoints}}
Has endpoints: {{endpoint_count}}
{{/has_endpoints}}

{{^has_endpoints}}
No endpoints found
{{/has_endpoints}}
''';

      final result = renderer.render(template);

      expect(result, contains('Has endpoints: 2'));
      expect(result, isNot(contains('No endpoints found')));
    });

    test('withVars creates new renderer with custom vars', () {
      final customRenderer = renderer.withVars({'custom_var': 'custom_value'});

      final template = '{{project_name}} - {{custom_var}}';
      final result = customRenderer.render(template);

      expect(result, equals('test_project - custom_value'));
    });

    test('extraVars override context vars', () {
      final template = '{{project_name}}';
      final result = renderer.render(template, {'project_name': 'override'});

      expect(result, equals('override'));
    });

    test('renders complex template with all features', () {
      final template = '''
# {{project_name}}

ServerPod {{serverpod_version}} project.

{{#uses_postgres}}
Uses PostgreSQL database.
{{/uses_postgres}}

{{#has_endpoints}}
## Endpoints ({{endpoint_count}})

{{#endpoints}}
### {{name}}
File: {{file}}

{{/endpoints}}
{{/has_endpoints}}

{{#has_models}}
## Models ({{model_count}})

{{#models}}
- {{class_name}}
{{/models}}
{{/has_models}}
''';

      final result = renderer.render(template);

      expect(result, contains('# test_project'));
      expect(result, contains('ServerPod 3.2.3 project'));
      expect(result, contains('Uses PostgreSQL database'));
      expect(result, contains('## Endpoints (2)'));
      expect(result, contains('### user'));
      expect(result, contains('### product'));
      expect(result, contains('## Models (2)'));
      expect(result, contains('- User'));
      expect(result, contains('- Product'));
    });

    test('templateVars returns context variables', () {
      final vars = renderer.templateVars;

      expect(vars['project_name'], equals('test_project'));
      expect(vars['serverpod_version'], equals('3.2.3'));
      expect(vars['has_endpoints'], isTrue);
      expect(vars['endpoint_count'], equals(2));
    });

    test('handles missing variables gracefully', () {
      final template = '{{nonexistent_var}}';
      final result = renderer.render(template);

      // Mustache should leave empty or render as-is depending on implementation
      expect(result, isNotNull);
    });

    test('handles empty lists', () {
      final emptyContext = const ProjectContext(
        projectName: 'empty',
        serverpodVersion: '3.2.3',
        rootPath: '/path',
        endpoints: [],
      );

      final emptyRenderer = TemplateRenderer(context: emptyContext);

      final template = '''
{{#endpoints}}
- {{name}}
{{/endpoints}}

{{^endpoints}}
No endpoints
{{/endpoints}}
''';

      final result = emptyRenderer.render(template);

      expect(result, contains('No endpoints'));
    });

    test('renders template with special characters', () {
      final template = '''
{{project_name}} & Partners
"{{serverpod_version}}"
<test>
''';

      final result = renderer.render(template);

      expect(result, contains('test_project & Partners'));
      expect(result, contains('"3.2.3"'));
      expect(result, contains('<test>'));
    });
  });

  group('ProjectContext', () {
    test('creates context from serverpod project', () {
      final context = const ProjectContext(
        projectName: 'myapp',
        serverpodVersion: '3.2.0',
        rootPath: '/path/to/myapp',
        databaseType: DatabaseType.sqlite,
        hasEndpoints: false,
        hasModels: false,
        hasMigrations: false,
        usesRedis: true,
      );

      final vars = context.toTemplateVars();

      expect(vars['project_name'], equals('myapp'));
      expect(vars['serverpod_version'], equals('3.2.0'));
      expect(vars['database_type'], equals('sqlite'));
      expect(vars['uses_sqlite'], isTrue);
      expect(vars['uses_postgres'], isFalse);
      expect(vars['has_endpoints'], isFalse);
      expect(vars['uses_redis'], isTrue);
    });

    test('endpointCount returns count', () {
      final context = const ProjectContext(
        projectName: 'test',
        serverpodVersion: '3.2.3',
        rootPath: '/path',
        endpoints: [
          EndpointInfo(name: 'a', file: 'a.dart'),
          EndpointInfo(name: 'b', file: 'b.dart'),
          EndpointInfo(name: 'c', file: 'c.dart'),
        ],
      );

      expect(context.endpointCount, equals(3));
    });
  });

  group('EndpointInfo', () {
    test('toJson converts to map', () {
      const info = EndpointInfo(
        name: 'test',
        file: 'test.dart',
        methodCount: 5,
      );

      final json = info.toJson();

      expect(json['name'], equals('test'));
      expect(json['file'], equals('test.dart'));
      expect(json['method_count'], equals(5));
      expect(json['methods'], isEmpty);
    });
  });

  group('ModelInfo', () {
    test('toJson converts to map', () {
      const info = ModelInfo(
        name: 'User',
        file: 'user.dart',
        namespace: 'models',
        fields: [
          FieldInfo(name: 'id', type: 'int'),
          FieldInfo(name: 'name', type: 'String'),
        ],
      );

      final json = info.toJson();

      expect(json['class_name'], equals('User'));
      expect(json['file'], equals('user.dart'));
      expect(json['namespace'], equals('models'));
      expect(json['fields'], hasLength(2));
    });
  });

  group('MigrationInfo', () {
    test('toJson converts to map', () {
      const info = MigrationInfo(
        name: '0001_initial.dart',
        file: 'migrations/0001_initial.dart',
      );

      final json = info.toJson();

      expect(json['name'], equals('0001_initial.dart'));
      expect(json['file'], equals('migrations/0001_initial.dart'));
    });
  });
}
