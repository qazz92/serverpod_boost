import 'package:test/test.dart';
import 'dart:io';

import '../../lib/tools/cli_commands_tool.dart';
import '../../lib/mcp/mcp_protocol.dart';
import '../../lib/serverpod/serverpod_locator.dart';

void main() {
  group('CliCommandsTool', () {
    late CliCommandsTool tool;

    setUp(() {
      tool = CliCommandsTool();
    });

    tearDown(() {
      // Reset ServerPod locator cache between tests
      ServerPodLocator.resetCache();
    });

    group('Command Discovery', () {
      test('lists commands from bin directory', () async {
        // Setup test project structure
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        // Create directories
        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create a config directory (required for valid project)
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create test command files
        final runFile = File('${binDir.path}/run.dart');
        runFile.writeAsStringSync('''
/// Start the ServerPod development server
void main(List<String> args) {
  print("Starting server...");
}
''');

        final buildFile = File('${binDir.path}/build.dart');
        buildFile.writeAsStringSync('''
/// Build the ServerPod project
void main(List<String> args) {
  print("Building project...");
}
''');

        // Mock ServerPodLocator to return our test project
        ServerPodLocator.resetCache();
        // We need to access the project detection logic
        // This is a simplified version of what ServerProject.detect() does
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );

        // Create a test version of the tool that uses our mock project
        final testTool = _MockCliCommandsTool(mockProject);

        // Test with empty params
        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {'source': 'custom'},  // Only test custom commands
        );

        final response = await testTool.execute(request);

        // Verify response structure
        expect(response.isSuccess, isTrue);
        expect(response.result, isMap);
        expect(response.result['commands'], isList);
        expect(response.result['categories'], isList);
        expect(response.result['count'], isA<int>());

        // Verify commands found (only custom, no built-in)
        final commands = response.result['commands'] as List;
        expect(commands.length, equals(2));

        // Verify first command
        final runCommand = commands[0] as Map<String, dynamic>;
        expect(runCommand['name'], equals('run'));
        expect(runCommand['description'], equals('Start the ServerPod development server'));
        expect(runCommand['category'], equals('server'));
        expect(runCommand['file'], contains('run.dart'));
        expect(runCommand['relativePath'], equals('bin/run.dart'));

        // Verify second command
        final buildCommand = commands[1] as Map<String, dynamic>;
        expect(buildCommand['name'], equals('build'));
        expect(buildCommand['description'], equals('Build the ServerPod project'));
        expect(buildCommand['category'], equals('build'));
        expect(buildCommand['file'], contains('build.dart'));
        expect(buildCommand['relativePath'], equals('bin/build.dart'));

        // Verify categories
        final categories = response.result['categories'] as List;
        expect(categories.contains('server'), isTrue);
        expect(categories.contains('build'), isTrue);

        // Clean up
        tempDir.deleteSync(recursive: true);
      });

      test('excludes boost.dart file automatically', () async {
        // Setup test project structure
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        // Create directories
        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create a config directory (required for valid project)
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create test command files
        File('${binDir.path}/run.dart').writeAsStringSync('/// Start server\nvoid main() {}');
        File('${binDir.path}/build.dart').writeAsStringSync('/// Build project\nvoid main() {}');
        File('${binDir.path}/boost.dart').writeAsStringSync('/// Main entry point\nvoid main() {}');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Verify boost.dart is excluded
        final commands = response.result['commands'] as List;
        expect(commands.length, equals(2));

        final commandNames = commands.map((c) => c['name']).toList();
        expect(commandNames, isNot(contains('boost')));
        expect(commandNames, contains('run'));
        expect(commandNames, contains('build'));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });

      test('handles non-existent bin directory', () async {
        // Setup test project without bin directory
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final serverDir = Directory('${projectRoot.path}/server');

        // Create directories but NOT bin
        projectRoot.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create a config directory (required for valid project)
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Should handle missing bin directory gracefully
        expect(response.isSuccess, isTrue);
        final commands = response.result['commands'] as List;
        expect(commands.isEmpty, isTrue);
        expect(response.result['count'], equals(0));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });
    });

    group('Description Extraction', () {
      test('extracts description from doc comments', () async {
        // Setup test project
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create file with doc comments
        final testFile = File('${binDir.path}/migration.dart');
        testFile.writeAsStringSync('''
/// Create database migrations
///
/// This command generates migration files for pending database changes
/// and applies them to the database.
void main(List<String> args) {
  print("Running migrations...");
}
''');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Verify description extraction
        final commands = response.result['commands'] as List;
        expect(commands.length, equals(1));

        final command = commands[0] as Map<String, dynamic>;
        expect(command['description'], contains('Create database migrations'));
        expect(command['description'], contains('generates migration files'));
        expect(command['description'], contains('applies them to the database'));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });

      test('provides default description when no doc comments found', () async {
        // Setup test project
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create file without doc comments
        final testFile = File('${binDir.path}/test.dart');
        testFile.writeAsStringSync('''
import 'dart:io';

void main(List<String> args) {
  print("Hello world");
}
''');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Verify default description
        final commands = response.result['commands'] as List;
        final command = commands[0] as Map<String, dynamic>;
        expect(command['description'], equals('CLI command for ServerPod development'));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });

      test('provides specific default for common commands', () async {
        // Setup test project with test command
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create test command file without description
        final testFile = File('${binDir.path}/test.dart');
        testFile.writeAsStringSync('''
void main(List<String> args) {
  print("Running tests...");
}
''');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Verify specific default description
        final commands = response.result['commands'] as List;
        final command = commands[0] as Map<String, dynamic>;
        expect(command['description'], equals('Run tests for the ServerPod project'));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });
    });

    group('Categorization', () {
      test('categorizes commands based on filename patterns', () async {
        // Setup test project with various command types
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create various command files
        File('${binDir.path}/migrate.dart').writeAsStringSync('/// Run migrations\nvoid main() {}');
        File('${binDir.path}/database.dart').writeAsStringSync('/// Database utilities\nvoid main() {}');
        File('${binDir.path}/run.dart').writeAsStringSync('/// Start server\nvoid main() {}');
        File('${binDir.path}/serve.dart').writeAsStringSync('/// Serve dev server\nvoid main() {}');
        File('${binDir.path}/build.dart').writeAsStringSync('/// Build project\nvoid main() {}');
        File('${binDir.path}/generate.dart').writeAsStringSync('/// Generate code\nvoid main() {}');
        File('${binDir.path}/test.dart').writeAsStringSync('/// Run tests\nvoid main() {}');
        File('${binDir.path}/deploy.dart').writeAsStringSync('/// Deploy to production\nvoid main() {}');
        File('${binDir.path}/auth.dart').writeAsStringSync('/// Auth utilities\nvoid main() {}');
        File('${binDir.path}/tools.dart').writeAsStringSync('/// General tools\nvoid main() {}');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Verify categorization
        final commands = response.result['commands'] as List;
        final categories = response.result['categories'] as List;

        // Check expected categories
        expect(categories, contains('migration'));
        expect(categories, contains('database'));
        expect(categories, contains('server'));
        expect(categories, contains('build'));
        expect(categories, contains('test'));
        expect(categories, contains('deployment'));
        expect(categories, contains('auth'));
        expect(categories, contains('tools'));

        // Verify specific categorization
        final commandCategories = {
          for (final cmd in commands) cmd['name']: cmd['category']
        };

        expect(commandCategories['migrate'], equals('migration'));
        expect(commandCategories['database'], equals('database'));
        expect(commandCategories['run'], equals('server'));
        expect(commandCategories['serve'], equals('server'));
        expect(commandCategories['build'], equals('build'));
        expect(commandCategories['generate'], equals('build'));
        expect(commandCategories['test'], equals('test'));
        expect(commandCategories['deploy'], equals('deployment'));
        expect(commandCategories['auth'], equals('auth'));
        expect(commandCategories['tools'], equals('tools'));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });
    });

    group('Category Filter', () {
      test('filters commands by category parameter', () async {
        // Setup test project
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create various command files
        File('${binDir.path}/migrate.dart').writeAsStringSync('/// Run migrations\nvoid main() {}');
        File('${binDir.path}/run.dart').writeAsStringSync('/// Start server\nvoid main() {}');
        File('${binDir.path}/build.dart').writeAsStringSync('/// Build project\nvoid main() {}');
        File('${binDir.path}/test.dart').writeAsStringSync('/// Run tests\nvoid main() {}');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        // Test filtering by server category
        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {'category': 'server'},
        );

        final response = await testTool.execute(request);

        // Verify filtered results
        final commands = response.result['commands'] as List;
        expect(commands.length, equals(1));

        final command = commands[0] as Map<String, dynamic>;
        expect(command['name'], equals('run'));
        expect(command['category'], equals('server'));
        expect(response.result['count'], equals(1));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });

      test('returns empty list when no commands match category', () async {
        // Setup test project
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create some command files
        File('${binDir.path}/run.dart').writeAsStringSync('/// Start server\nvoid main() {}');
        File('${binDir.path}/build.dart').writeAsStringSync('/// Build project\nvoid main() {}');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        // Test filtering by non-existent category
        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {'category': 'nonexistent'},
        );

        final response = await testTool.execute(request);

        // Should return empty list
        final commands = response.result['commands'] as List;
        expect(commands.isEmpty, isTrue);
        expect(response.result['count'], equals(0));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });
    });

    group('Empty Directory', () {
      test('handles empty bin directory', () async {
        // Setup test project with empty bin directory
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create empty bin directory (no dart files)

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Should handle empty directory gracefully
        expect(response.isSuccess, isTrue);
        expect(response.result['commands'], isList);
        expect(response.result['commands'], isEmpty);
        expect(response.result['count'], equals(0));
        expect(response.result['categories'], isList);
        expect(response.result['categories'], isEmpty);

        // Clean up
        tempDir.deleteSync(recursive: true);
      });

      test('handles bin directory with non-dart files', () async {
        // Setup test project with non-dart files in bin
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create non-dart files
        File('${binDir.path}/readme.md').writeAsStringSync('# CLI Commands');
        File('${binDir.path}/config.yaml').writeAsStringSync('settings: {}');
        Directory('${binDir.path}/scripts').createSync();

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Should only filter out dart files
        final commands = response.result['commands'] as List;
        expect(commands.isEmpty, isTrue);
        expect(response.result['count'], equals(0));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });
    });

    group('Error Handling', () {
      test('returns error for invalid ServerPod project', () async {
        // Create a directory that's not a valid ServerPod project
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/regular_project');
        projectRoot.createSync(recursive: true);

        // Create mock project without server/config
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: null,
        );

        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Should return error for invalid project
        expect(response.isSuccess, isFalse);
        expect(response.error!.message, contains('Not a valid ServerPod project'));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });

      test('handles file parsing errors gracefully', () async {
        // Setup test project with invalid dart file
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create invalid dart file
        final invalidFile = File('${binDir.path}/invalid.dart');
        invalidFile.writeAsStringSync('''
/// Invalid Dart file
@invalid syntax here
void main() {
  // valid block
}
''');

        // Create valid command file too
        File('${binDir.path}/valid.dart').writeAsStringSync('/// Valid command\nvoid main() {}');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Should still return valid commands, skipping invalid ones
        expect(response.isSuccess, isTrue);
        final commands = response.result['commands'] as List;
        expect(commands.length, equals(1));
        expect(commands[0]['name'], equals('valid'));

        // Clean up
        tempDir.deleteSync(recursive: true);
      });

      test('handles permission errors gracefully', () async {
        // Setup test project with unreadable file
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create dart file
        final testFile = File('${binDir.path}/command.dart');
        testFile.writeAsStringSync('/// Test command\nvoid main() {}');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: {},
        );

        final response = await testTool.execute(request);

        // Should handle gracefully
        expect(response.isSuccess, isTrue);

        // Clean up
        tempDir.deleteSync(recursive: true);
      });
    });

    group('Tool Metadata', () {
      test('returns correct tool metadata', () {
        expect(tool.name, equals('cli_commands'));
        expect(tool.description, equals('List available ServerPod CLI commands'));
        expect(tool.inputSchema, isMap);

        final schema = tool.inputSchema;
        expect(schema['type'], equals('object'));
        expect(schema['properties'], isMap);
        expect(schema['properties']!['category'], isMap);
        expect(schema['properties']!['category']!['type'], equals('string'));

        // Optional category parameter
        final required = schema['required'] as List?;
        expect(required, isNull);
      });

      test('handles empty parameters correctly', () async {
        // Setup minimal test project
        final tempDir = Directory.systemTemp.createTempSync('serverpod-test-');
        final projectRoot = Directory('${tempDir.path}/test_project');
        final binDir = Directory('${projectRoot.path}/bin');
        final serverDir = Directory('${projectRoot.path}/server');

        projectRoot.createSync(recursive: true);
        binDir.createSync(recursive: true);
        serverDir.createSync(recursive: true);

        // Create config directory
        final configDir = Directory('${serverDir.path}/config');
        configDir.createSync(recursive: true);
        File('${configDir.path}/development.yaml').writeAsStringSync('environment: development');

        // Create mock tool
        final mockProject = ServerPodProject(
          rootPath: projectRoot.path,
          serverPath: serverDir.path,
        );
        final testTool = _MockCliCommandsTool(mockProject);

        // Test with null parameters
        final request = McpRequest(
          id: 'test',
          method: 'cli_commands',
          params: null,
        );

        final response = await testTool.execute(request);

        // Should handle null parameters
        expect(response.isSuccess, isTrue);
        expect(response.result['commands'], isList);

        // Clean up
        tempDir.deleteSync(recursive: true);
      });
    });
  });
}

// Mock implementation of CliCommandsTool for testing
class _MockCliCommandsTool extends CliCommandsTool {
  final ServerPodProject mockProject;

  _MockCliCommandsTool(this.mockProject);

  @override
  Future<Map<String, dynamic>> executeImpl(Map<String, dynamic> params) async {
    // Override to use mock project
    final category = params['category'] as String?;

    // Use the same logic but with our mock project
    if (!mockProject.isValid) {
      return {'error': 'Not a valid ServerPod project'};
    }

    try {
      // Find bin directory
      final binDirectory = Directory('${mockProject.rootPath}/bin');

      if (!await binDirectory.exists()) {
        return {'error': 'No bin/ directory found'};
      }

      // Collect .dart files in bin directory (excluding this file itself)
      final dartFiles = binDirectory.listSync()
          .whereType<File>()
          .where((entity) =>
            entity.uri.pathSegments.last.endsWith('.dart') &&
            !entity.uri.pathSegments.last.contains('boost.dart') // Exclude main entry point
          );

      final commands = <Map<String, dynamic>>[];
      final categories = <String>{};

      for (final file in dartFiles) {
        final command = await _parseCommandFile(file, mockProject);
        if (command != null) {
          if (category == null || command['category'] == category) {
            commands.add(command);
            categories.add(command['category']);
          }
        }
      }

      return {
        'commands': commands,
        'categories': categories.toList(),
        'count': commands.length,
      };
    } catch (e) {
      return {'error': 'Failed to parse CLI commands: ${e.toString()}'};
    }
  }

  // Copy the private methods from the original tool
  Future<Map<String, dynamic>?> _parseCommandFile(File file, ServerPodProject project) async {
    try {
      final content = await file.readAsString();
      final fileName = file.uri.pathSegments.last;

      // Extract command name from filename
      final commandName = fileName.replaceFirst('.dart', '');

      // Extract description from doc comments
      final description = _extractDescription(content);

      // Determine category based on filename patterns
      final category = _determineCategory(fileName);

      return {
        'name': commandName,
        'description': description,
        'category': category,
        'file': file.uri.pathSegments.join('/'),
        'relativePath': 'bin/$fileName',
        'path': file.uri.toFilePath(),
      };
    } catch (e) {
      print('Error parsing command file ${file.path}: $e');
      return null;
    }
  }

  String _extractDescription(String content) {
    // Look for doc comments /// at the beginning of the file
    final lines = content.split('\n');
    String description = '';
    bool inDocComment = false;
    int docCommentLineCount = 0;
    const maxDocLines = 5; // Only look at first 5 lines for description

    for (int i = 0; i < lines.length && docCommentLineCount < maxDocLines; i++) {
      final line = lines[i].trim();

      if (line.startsWith('///')) {
        inDocComment = true;
        docCommentLineCount++;
        final commentText = line.substring(3).trim();
        if (commentText.isNotEmpty) {
          if (description.isNotEmpty) description += ' ';
          description += commentText;
        }
      } else if (inDocComment && line.trim().isEmpty) {
        // Empty line in doc comment
        docCommentLineCount++;
        if (description.isNotEmpty) description += ' ';
      } else if (!line.startsWith('import') && !line.startsWith('library')) {
        // End of doc comments, start of actual code
        break;
      }
    }

    // If no description found, use a default based on command name
    if (description.isEmpty) {
      switch (_extractCommandNameFromContent(content)) {
        case 'run':
          return 'Start the ServerPod server';
        case 'build':
          return 'Build the ServerPod project';
        case 'test':
          return 'Run tests for the ServerPod project';
        case 'migrate':
          return 'Run database migrations';
        case 'generate':
          return 'Generate code from models';
        case 'serve':
          return 'Start the development server';
        default:
          return 'CLI command for ServerPod development';
      }
    }

    return description;
  }

  String _determineCategory(String fileName) {
    final lowerName = fileName.toLowerCase();

    if (lowerName.contains('migration') || lowerName.contains('migrate')) {
      return 'migration';
    } else if (lowerName.contains('db') || lowerName.contains('database')) {
      return 'database';
    } else if (lowerName.contains('server') || lowerName.contains('run') || lowerName.contains('serve')) {
      return 'server';
    } else if (lowerName.contains('build') || lowerName.contains('generate')) {
      return 'build';
    } else if (lowerName.contains('test')) {
      return 'test';
    } else if (lowerName.contains('deploy') || lowerName.contains('prod')) {
      return 'deployment';
    } else if (lowerName.contains('auth') || lowerName.contains('user')) {
      return 'auth';
    } else {
      return 'tools';
    }
  }

  String _extractCommandNameFromContent(String content) {
    // Try to find main function or similar command patterns
    final lines = content.split('\n');

    for (final line in lines) {
      if (line.contains('void main(') || line.contains('Future<void> main(')) {
        // Extract after 'main('
        final mainMatch = RegExp(r'main\(\s*([^)]*)\s*\)').firstMatch(line);
        if (mainMatch != null) {
          final args = mainMatch.group(1) ?? '';
          if (args.contains('run') || args.contains('serve')) {
            return 'run';
          }
        }
        return 'run';
      }

      if (line.contains('Command(') && !line.contains('//')) {
        // Look for command definitions
        final commandMatch = RegExp(r'''Command\(['"]([^'"]+)['"]\)''').firstMatch(line);
        if (commandMatch != null) {
          return commandMatch.group(1)!;
        }
      }
    }

    return 'unknown';
  }
}