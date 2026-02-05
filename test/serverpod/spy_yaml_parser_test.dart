import 'dart:io';
import 'package:test/test.dart';
import 'package:serverpod_boost/serverpod/spy_yaml_parser.dart';

void main() {
  group('SpyYamlParser', () {
    late Directory tempDir;
    late String testFilePath;

    setUp(() {
      // Create a temporary directory for test files
      tempDir = Directory.systemTemp.createTempSync('spy_yaml_test_');
      testFilePath = '${tempDir.path}/test_model.spy.yaml';
    });

    tearDown(() {
      // Clean up temporary directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('parseFile', () {
      test('should parse a valid .spy.yaml file', () {
        final yamlContent = '''
# Test model
class: Greeting
fields:
  message: String
  author: String
  timestamp: DateTime
''';
        File(testFilePath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(testFilePath);

        expect(model, isNotNull);
        expect(model!.className, equals('Greeting'));
        expect(model.fields.length, equals(3));

        expect(model.fields[0].name, equals('message'));
        expect(model.fields[0].type, equals('String'));
        expect(model.fields[0].isOptional, isFalse);
        expect(model.fields[0].dartType, equals('String'));

        expect(model.fields[1].name, equals('author'));
        expect(model.fields[1].type, equals('String'));

        expect(model.fields[2].name, equals('timestamp'));
        expect(model.fields[2].type, equals('DateTime'));
      });

      test('should parse optional fields with ? suffix', () {
        final yamlContent = '''
class: User
fields:
  name: String
  age: int?
  email: String?
  bio: String?
''';
        File(testFilePath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(testFilePath);

        expect(model, isNotNull);
        expect(model!.className, equals('User'));
        expect(model.fields.length, equals(4));

        expect(model.fields[0].name, equals('name'));
        expect(model.fields[0].isOptional, isFalse);
        expect(model.fields[0].type, equals('String'));

        expect(model.fields[1].name, equals('age'));
        expect(model.fields[1].isOptional, isTrue);
        expect(model.fields[1].type, equals('int'));
        expect(model.fields[1].dartType, equals('int?'));

        expect(model.fields[2].name, equals('email'));
        expect(model.fields[2].isOptional, isTrue);
        expect(model.fields[2].dartType, equals('String?'));
      });

      test('should parse model with no fields', () {
        final yamlContent = '''
class: EmptyModel
fields: {}
''';
        File(testFilePath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(testFilePath);

        expect(model, isNotNull);
        expect(model!.className, equals('EmptyModel'));
        expect(model.fields, isEmpty);
      });

      test('should return null for non-existent file', () {
        final model = SpyYamlParser.parseFile('/nonexistent/path/file.spy.yaml');

        expect(model, isNull);
      });

      test('should return null for empty file', () {
        File(testFilePath).writeAsStringSync('');

        final model = SpyYamlParser.parseFile(testFilePath);

        expect(model, isNull);
      });

      test('should return null when class name is missing', () {
        final yamlContent = '''
fields:
  name: String
''';
        File(testFilePath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(testFilePath);

        expect(model, isNull);
      });

      test('should return null when class name is empty', () {
        final yamlContent = '''
class:
fields:
  name: String
''';
        File(testFilePath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(testFilePath);

        expect(model, isNull);
      });

      test('should parse complex types', () {
        final yamlContent = '''
class: ComplexModel
fields:
  id: String
  count: int
  ratio: double
  isActive: bool
  createdAt: DateTime
  metadata: Map
  items: List
''';
        File(testFilePath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(testFilePath);

        expect(model, isNotNull);
        expect(model!.className, equals('ComplexModel'));
        expect(model.fields.length, equals(7));

        expect(model.fields[1].type, equals('int'));
        expect(model.fields[2].type, equals('double'));
        expect(model.fields[3].type, equals('bool'));
        expect(model.fields[4].type, equals('DateTime'));
        expect(model.fields[5].type, equals('Map'));
        expect(model.fields[6].type, equals('List'));
      });
    });

    group('SpyYamlModel.namespace', () {
      test('should extract namespace from path with src directory', () {
        final yamlContent = '''
class: TestModel
fields:
  id: String
''';

        // Create path: /tmp/.../lib/src/greetings/models/test_model.spy.yaml
        final modelDir = Directory('${tempDir.path}/lib/src/greetings/models')
          ..createSync(recursive: true);
        final modelPath = '${modelDir.path}/test_model.spy.yaml';
        File(modelPath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(modelPath);

        expect(model, isNotNull);
        expect(model!.namespace, equals('greetings/models'));
      });

      test('should extract namespace from direct src subdirectory', () {
        final yamlContent = '''
class: TestModel
fields:
  id: String
''';

        // Create path: /tmp/.../lib/src/test_model.spy.yaml
        final srcDir = Directory('${tempDir.path}/lib/src')..createSync(recursive: true);
        final modelPath = '${srcDir.path}/test_model.spy.yaml';
        File(modelPath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(modelPath);

        expect(model, isNotNull);
        expect(model!.namespace, isEmpty);
      });

      test('should return empty namespace when src not in path', () {
        final yamlContent = '''
class: TestModel
fields:
  id: String
''';

        File(testFilePath).writeAsStringSync(yamlContent);

        final model = SpyYamlParser.parseFile(testFilePath);

        expect(model, isNotNull);
        expect(model!.namespace, isEmpty);
      });
    });

    group('findSpyYamlFiles', () {
      test('should find all .spy.yaml files in lib/src directory', () {
        final libDir = Directory('${tempDir.path}/lib/src')..createSync(recursive: true);

        // Create multiple spy.yaml files
        File('${libDir.path}/model1.spy.yaml').createSync();
        File('${libDir.path}/model2.spy.yaml').createSync();

        final subdir = Directory('${libDir.path}/subdir')..createSync();
        File('${subdir.path}/model3.spy.yaml').createSync();

        // Create non-spy.yaml file
        File('${libDir.path}/not_spy.txt').createSync();

        final files = SpyYamlParser.findSpyYamlFiles(tempDir.path);

        expect(files.length, equals(3));
        expect(files, contains(endsWith('model1.spy.yaml')));
        expect(files, contains(endsWith('model2.spy.yaml')));
        expect(files, contains(endsWith('model3.spy.yaml')));
        expect(files, isNot(contains(endsWith('not_spy.txt'))));
      });

      test('should return empty list when lib/src does not exist', () {
        final files = SpyYamlParser.findSpyYamlFiles(tempDir.path);

        expect(files, isEmpty);
      });

      test('should return empty list when directory has no .spy.yaml files', () {
        final libDir = Directory('${tempDir.path}/lib/src')..createSync(recursive: true);
        File('${libDir.path}/other.txt').createSync();

        final files = SpyYamlParser.findSpyYamlFiles(tempDir.path);

        expect(files, isEmpty);
      });
    });

    group('parseAll', () {
      test('should parse all .spy.yaml files in server package', () {
        final libDir = Directory('${tempDir.path}/lib/src')..createSync(recursive: true);

        // Create first model
        File('${libDir.path}/greeting.spy.yaml').writeAsStringSync('''
class: Greeting
fields:
  message: String
''');

        // Create second model
        File('${libDir.path}/user.spy.yaml').writeAsStringSync('''
class: User
fields:
  name: String
  email: String?
''');

        // Create invalid model (no class name)
        File('${libDir.path}/invalid.spy.yaml').writeAsStringSync('''
fields:
  name: String
''');

        final models = SpyYamlParser.parseAll(tempDir.path);

        expect(models.length, equals(2));

        expect(models[0].className, equals('Greeting'));
        expect(models[0].fields.length, equals(1));

        expect(models[1].className, equals('User'));
        expect(models[1].fields.length, equals(2));
      });

      test('should return empty list when no valid models found', () {
        final libDir = Directory('${tempDir.path}/lib/src')..createSync(recursive: true);

        File('${libDir.path}/invalid1.spy.yaml').writeAsStringSync('''
fields:
  name: String
''');

        File('${libDir.path}/invalid2.spy.yaml').writeAsStringSync('');

        final models = SpyYamlParser.parseAll(tempDir.path);

        expect(models, isEmpty);
      });
    });

    group('SpyYamlField', () {
      test('should provide correct dartType for non-optional fields', () {
        final field = SpyYamlField(name: 'id', type: 'String', isOptional: false);

        expect(field.dartType, equals('String'));
      });

      test('should provide correct dartType for optional fields', () {
        final field = SpyYamlField(name: 'age', type: 'int', isOptional: true);

        expect(field.dartType, equals('int?'));
      });

      test('should implement equality correctly', () {
        final field1 = SpyYamlField(name: 'id', type: 'String', isOptional: false);
        final field2 = SpyYamlField(name: 'id', type: 'String', isOptional: false);
        final field3 = SpyYamlField(name: 'id', type: 'String', isOptional: true);

        expect(field1, equals(field2));
        expect(field1, isNot(equals(field3)));
      });

      test('should implement toString correctly', () {
        final field = SpyYamlField(name: 'id', type: 'String', isOptional: false);

        expect(
          field.toString(),
          equals('SpyYamlField(name: id, type: String, isOptional: false)'),
        );
      });
    });

    group('SpyYamlModel', () {
      test('should implement equality correctly', () {
        final model1 = SpyYamlModel(
          className: 'Test',
          fields: [SpyYamlField(name: 'id', type: 'String')],
          filePath: '/path/to/test.spy.yaml',
        );
        final model2 = SpyYamlModel(
          className: 'Test',
          fields: [SpyYamlField(name: 'id', type: 'String')],
          filePath: '/path/to/test.spy.yaml',
        );
        final model3 = SpyYamlModel(
          className: 'Test',
          fields: [SpyYamlField(name: 'id', type: 'int')],
          filePath: '/path/to/test.spy.yaml',
        );

        expect(model1, equals(model2));
        expect(model1, isNot(equals(model3)));
      });

      test('should implement toString correctly', () {
        final model = SpyYamlModel(
          className: 'Greeting',
          fields: [
            SpyYamlField(name: 'message', type: 'String'),
            SpyYamlField(name: 'author', type: 'String'),
          ],
          filePath: '/path/to/greeting.spy.yaml',
        );

        expect(
          model.toString(),
          equals('SpyYamlModel(className: Greeting, namespace: , fields: 2, filePath: /path/to/greeting.spy.yaml)'),
        );
      });
    });

    group('fieldPattern', () {
      test('should match field definition lines', () {
        final pattern = SpyYamlParser.fieldPattern;

        final match1 = pattern.firstMatch('  message: String');
        expect(match1, isNotNull);
        expect(match1!.group(1), equals('message'));
        expect(match1.group(2), equals('String'));

        final match2 = pattern.firstMatch('    age: int?');
        expect(match2, isNotNull);
        expect(match2!.group(1), equals('age'));
        expect(match2.group(2), equals('int?'));
      });

      test('should not match non-field lines', () {
        final pattern = SpyYamlParser.fieldPattern;

        expect(pattern.hasMatch('class: Greeting'), isFalse);
        expect(pattern.hasMatch('fields:'), isFalse);
        expect(pattern.hasMatch('# Comment'), isFalse);
      });
    });
  });
}
