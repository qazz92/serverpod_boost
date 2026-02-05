import 'dart:io';
import 'package:test/test.dart';
import 'package:serverpod_boost/serverpod/method_parser.dart';

void main() {
  group('MethodParser', () {
    late Directory tempDir;

    setUp(() async {
      // Create temporary directory for test files
      tempDir = Directory.systemTemp.createTempSync('method_parser_test_');
    });

    tearDown(() async {
      // Clean up temporary directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('parseFile', () {
      test('parses simple method with single parameter', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''class TestEndpoint {
  Future<String> hello(Session session, String name) async {
    return 'Hello, \$name';
  }
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(1));
        expect(methods[0].name, 'hello');
        expect(methods[0].returnType, 'String');
        expect(methods[0].parameters, hasLength(2));
        expect(methods[0].parameters[0].type, 'Session');
        expect(methods[0].parameters[0].name, 'session');
        expect(methods[0].parameters[0].isSession, true);
        expect(methods[0].parameters[1].type, 'String');
        expect(methods[0].parameters[1].name, 'name');
        expect(methods[0].parameters[1].isSession, false);
        expect(methods[0].lineNumber, 2); // Line 2 (0-indexed + 1)
      });

      test('parses method with multiple parameters', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
Future<Greeting> greet(Session session, String firstName, String lastName) async {
  return Greeting(firstName: firstName, lastName: lastName);
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(1));
        expect(methods[0].name, 'greet');
        expect(methods[0].returnType, 'Greeting');
        expect(methods[0].parameters, hasLength(3));
        expect(methods[0].userParameters, hasLength(2));
        expect(methods[0].userParameters[0].name, 'firstName');
        expect(methods[0].userParameters[1].name, 'lastName');
      });

      test('parses method with generic return type', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
Future<List<User>> getUsers(Session session, int limit) async {
  return [];
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(1));
        expect(methods[0].name, 'getUsers');
        expect(methods[0].returnType, 'List<User>');
        expect(methods[0].parameters[1].type, 'int');
        expect(methods[0].parameters[1].name, 'limit');
      });

      test('parses method with Map return type', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
Future<Map<String, dynamic>> getData(Session session, String key) async {
  return {};
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(1));
        expect(methods[0].returnType, 'Map<String, dynamic>');
      });

      test('parses multiple methods in same file', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
Future<String> hello(Session session, String name) async {
  return 'Hello';
}

Future<int> calculate(Session session, int a, int b) async {
  return a + b;
}

Future<List<User>> getUsers(Session session, int limit) async {
  return [];
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(3));
        expect(methods[0].name, 'hello');
        expect(methods[1].name, 'calculate');
        expect(methods[2].name, 'getUsers');
      });

      test('skips comment lines', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
// Future<String> commentedOut(Session session, String name) async {}
Future<String> hello(Session session, String name) async {
  return 'Hello';
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(1));
        expect(methods[0].name, 'hello');
      });

      test('skips empty lines', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''

Future<String> hello(Session session, String name) async {
  return 'Hello';
}

''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(1));
      });

      test('returns empty list for non-existent file', () {
        final methods = MethodParser.parseFile('${tempDir.path}/nonexistent.dart');

        expect(methods, isEmpty);
      });

      test('returns empty list for empty file', () {
        final file = File('${tempDir.path}/empty.dart');
        file.writeAsStringSync('');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, isEmpty);
      });

      test('parses method with complex parameter types', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
Future<void> processUser(Session session, User user, List<int> ids) async {
  // Implementation
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(1));
        expect(methods[0].returnType, 'void');
        expect(methods[0].parameters[1].type, 'User');
        expect(methods[0].parameters[2].type, 'List<int>');
      });
    });

    group('findEndpointFiles', () {
      test('finds endpoint files in standard structure', () {
        // Create standard ServerPod directory structure
        final srcDir = Directory('${tempDir.path}/lib/src');
        srcDir.createSync(recursive: true);

        // Create endpoint files
        File('${srcDir.path}/user_endpoint.dart').createSync();
        File('${srcDir.path}/auth_endpoint.dart').createSync();
        File('${srcDir.path}/generated_endpoint.dart').createSync(); // Should be ignored
        File('${srcDir.path}/service.dart').createSync(); // Should be ignored (doesn't match pattern)

        final files = MethodParser.findEndpointFiles(tempDir.path);

        expect(files, hasLength(2));
        expect(files, contains(endsWith('user_endpoint.dart')));
        expect(files, contains(endsWith('auth_endpoint.dart')));
        expect(files, isNot(contains(endsWith('generated_endpoint.dart'))));
        expect(files, isNot(contains(endsWith('service.dart'))));
      });

      test('finds endpoint files in nested directories', () {
        final srcDir = Directory('${tempDir.path}/lib/src');
        final nestedDir = Directory('${srcDir.path}/api');
        nestedDir.createSync(recursive: true);

        File('${srcDir.path}/main_endpoint.dart').createSync();
        File('${nestedDir.path}/nested_endpoint.dart').createSync();

        final files = MethodParser.findEndpointFiles(tempDir.path);

        expect(files, hasLength(2));
      });

      test('returns empty list when lib/src does not exist', () {
        final files = MethodParser.findEndpointFiles(tempDir.path);

        expect(files, isEmpty);
      });

      test('returns empty list for non-existent package path', () {
        final files = MethodParser.findEndpointFiles('/nonexistent/path');

        expect(files, isEmpty);
      });
    });

    group('EndpointMethod', () {
      test('generates correct signature string', () {
        final method = EndpointMethod(
          name: 'hello',
          returnType: 'String',
          parameters: [
            MethodParameter(type: 'Session', name: 'session', isSession: true),
            MethodParameter(type: 'String', name: 'name'),
          ],
          filePath: '/test/path.dart',
          lineNumber: 10,
        );

        expect(method.signature, 'Future<String> hello(Session session, String name)');
      });

      test('userParameters excludes Session', () {
        final method = EndpointMethod(
          name: 'test',
          returnType: 'void',
          parameters: [
            MethodParameter(type: 'Session', name: 'session', isSession: true),
            MethodParameter(type: 'String', name: 'a'),
            MethodParameter(type: 'int', name: 'b'),
          ],
          filePath: '/test.dart',
          lineNumber: 1,
        );

        expect(method.userParameters, hasLength(2));
        expect(method.userParameters[0].name, 'a');
        expect(method.userParameters[1].name, 'b');
        expect(method.userParameters.every((p) => !p.isSession), true);
      });

      test('equality works correctly', () {
        final method1 = EndpointMethod(
          name: 'hello',
          returnType: 'String',
          parameters: [
            MethodParameter(type: 'Session', name: 'session', isSession: true),
            MethodParameter(type: 'String', name: 'name'),
          ],
          filePath: '/test.dart',
          lineNumber: 10,
        );

        final method2 = EndpointMethod(
          name: 'hello',
          returnType: 'String',
          parameters: [
            MethodParameter(type: 'Session', name: 'session', isSession: true),
            MethodParameter(type: 'String', name: 'name'),
          ],
          filePath: '/test.dart',
          lineNumber: 10,
        );

        expect(method1, equals(method2));
        expect(method1.hashCode, equals(method2.hashCode));
      });
    });

    group('MethodParameter', () {
      test('toString returns correct format', () {
        final param = MethodParameter(type: 'String', name: 'name');

        expect(param.toString(), 'String name');
      });

      test('isSession flag is preserved', () {
        final sessionParam = MethodParameter(
          type: 'Session',
          name: 'session',
          isSession: true,
        );

        final userParam = MethodParameter(
          type: 'String',
          name: 'name',
          isSession: false,
        );

        expect(sessionParam.isSession, true);
        expect(userParam.isSession, false);
      });

      test('equality works correctly', () {
        final param1 = MethodParameter(type: 'String', name: 'name');
        final param2 = MethodParameter(type: 'String', name: 'name');
        final param3 = MethodParameter(type: 'int', name: 'name');

        expect(param1, equals(param2));
        expect(param1, isNot(equals(param3)));
        expect(param1.hashCode, equals(param2.hashCode));
      });
    });

    group('Pattern edge cases', () {
      test('parses method with extra whitespace', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
Future<String>   hello   (   Session   session   ,   String   name   ) async {
  return 'Hello';
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, hasLength(1));
        expect(methods[0].name, 'hello');
      });

      test('does not parse methods without Session parameter', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
Future<String> hello(String name) async {
  return 'Hello';
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, isEmpty);
      });

      test('does not parse non-Future methods', () {
        final file = File('${tempDir.path}/test_endpoint.dart');
        file.writeAsStringSync('''
String hello(Session session, String name) {
  return 'Hello';
}
''');

        final methods = MethodParser.parseFile(file.path);

        expect(methods, isEmpty);
      });
    });
  });
}
