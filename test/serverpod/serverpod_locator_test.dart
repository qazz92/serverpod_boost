import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:serverpod_boost/serverpod/serverpod_locator.dart';

/// Helper to get canonical path (resolves symlinks on macOS)
String canonicalPath(String path) {
  try {
    return Directory(path).resolveSymbolicLinksSync();
  } catch (_) {
    return p.normalize(path);
  }
}

void main() {
  group('ServerPodLocator', () {
    late Directory tempDir;
    late String projectRoot;
    late String serverPath;
    late String clientPath;
    late String flutterPath;
    late String configPath;
    late String migrationsPath;

    setUp(() {
      // Create temporary directory structure for testing
      tempDir = Directory.systemTemp.createTempSync('serverpod_locator_test_');
      projectRoot = p.normalize(tempDir.path);

      // Create server package
      serverPath = p.join(projectRoot, 'myservice_server');
      Directory(p.join(serverPath, 'config')).createSync(recursive: true);
      Directory(p.join(serverPath, 'migrations')).createSync(recursive: true);
      Directory(p.join(serverPath, 'lib', 'src', 'endpoints')).createSync(recursive: true);
      Directory(p.join(serverPath, 'lib', 'src', 'models')).createSync(recursive: true);

      // Create server pubspec.yaml
      File(p.join(serverPath, 'pubspec.yaml')).writeAsStringSync('''
name: myservice_server
version: 1.0.0
publish_to: none
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  serverpod: ^2.0.0
''');

      // Create server.dart (required for valid ServerPod project)
      File(p.join(serverPath, 'lib', 'server.dart')).writeAsStringSync('''
// Server entry point
''');

      // Create client package
      clientPath = p.join(projectRoot, 'myservice_client');
      Directory(p.join(clientPath, 'lib')).createSync(recursive: true);

      // Create client pubspec.yaml
      File(p.join(clientPath, 'pubspec.yaml')).writeAsStringSync('''
name: myservice_client
version: 1.0.0
publish_to: none
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  serverpod_client: ^2.0.0
''');

      // Create flutter package
      flutterPath = p.join(projectRoot, 'myservice_flutter');
      Directory(p.join(flutterPath, 'lib')).createSync(recursive: true);

      // Create flutter pubspec.yaml
      File(p.join(flutterPath, 'pubspec.yaml')).writeAsStringSync('''
name: myservice_flutter
version: 1.0.0
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  flutter:
    sdk: flutter
  serverpod_flutter: ^2.0.0
''');

      // Create config files
      configPath = p.join(serverPath, 'config');
      File(p.join(configPath, 'development.yaml')).writeAsStringSync('''
# Development config
''');
      File(p.join(configPath, 'production.yaml')).writeAsStringSync('''
# Production config
''');

      // Create migration files
      migrationsPath = p.join(serverPath, 'migrations');
      File(p.join(migrationsPath, '0001_initial.dart')).writeAsStringSync('''
// Initial migration
''');
      File(p.join(migrationsPath, '0002_add_users.dart')).writeAsStringSync('''
// Add users
''');

      // Create endpoint file
      File(p.join(serverPath, 'lib', 'src', 'endpoints', 'test_endpoint.dart'))
          .writeAsStringSync('''
class TestEndpoint {}
''');

      // Create .spy.yaml model file
      File(p.join(serverPath, 'lib', 'src', 'models', 'user.spy.yaml'))
          .writeAsStringSync('''
# User model
''');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('detect should find ServerPod project', () {
      // Change to server directory
      final originalDir = Directory.current.path;
      Directory.current = serverPath;

      try {
        final project = ServerPodProject.detect();
        expect(project, isNotNull);
        // Use contains for path comparison (handles macOS /private symlinks)
        expect(project!.rootPath.contains('serverpod_locator_test_'), isTrue);
        expect(project.serverPath!.contains('myservice_server'), isTrue);
        expect(project.clientPath!.contains('myservice_client'), isTrue);
        expect(project.flutterPath!.contains('myservice_flutter'), isTrue);
        expect(project.isValid, isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('detect should return null for non-ServerPod project', () {
      final nonServerpodDir = Directory.systemTemp.createTempSync('non_serverpod_');

      try {
        final project = ServerPodProject.detect(nonServerpodDir.path);
        expect(project, isNull);
      } finally {
        nonServerpodDir.deleteSync(recursive: true);
      }
    });

    test('configPath should return config directory path', () {
      final originalDir = Directory.current.path;
      Directory.current = serverPath;

      try {
        final project = ServerPodProject.detect();
        expect(project?.configPath, isNotNull);
        expect(project!.configPath!.contains('config'), isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('configPath should return null when serverPath is null', () {
      final project = ServerPodProject(rootPath: projectRoot);
      expect(project.configPath, isNull);
    });

    test('migrationsPath should return migrations directory path', () {
      final originalDir = Directory.current.path;
      Directory.current = serverPath;

      try {
        final project = ServerPodProject.detect();
        expect(project?.migrationsPath, isNotNull);
        expect(project!.migrationsPath!.contains('migrations'), isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('migrationsPath should return null when serverPath is null', () {
      final project = ServerPodProject(rootPath: projectRoot);
      expect(project.migrationsPath, isNull);
    });

    test('getConfigFile should return config file if exists', () {
      final originalDir = Directory.current.path;
      Directory.current = serverPath;

      try {
        final project = ServerPodProject.detect();
        final devConfig = project?.getConfigFile('development');
        expect(devConfig, isNotNull);
        expect(devConfig!.path, contains('development.yaml'));

        final prodConfig = project?.getConfigFile('production');
        expect(prodConfig, isNotNull);
        expect(prodConfig!.path, contains('production.yaml'));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('getConfigFile should return null if file does not exist', () {
      final originalDir = Directory.current.path;
      Directory.current = serverPath;

      try {
        final project = ServerPodProject.detect();
        final stagingConfig = project?.getConfigFile('staging');
        expect(stagingConfig, isNull);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('migrationFiles should return sorted list of migration files', () {
      final originalDir = Directory.current.path;
      Directory.current = serverPath;

      try {
        final project = ServerPodProject.detect();
        final migrations = project?.migrationFiles;
        expect(migrations, isNotEmpty);
        expect(migrations!.length, equals(2));

        // Verify sorting
        expect(migrations.first.path, contains('0001_initial.dart'));
        expect(migrations.last.path, contains('0002_add_users.dart'));
      } finally {
        Directory.current = originalDir;
      }
    });

    test('migrationFiles should return empty list when migrationsPath is null', () {
      final project = ServerPodProject(rootPath: projectRoot);
      expect(project.migrationFiles, isEmpty);
    });

    test('isValid should return true for valid project', () {
      final originalDir = Directory.current.path;
      Directory.current = serverPath;

      try {
        final project = ServerPodProject.detect();
        expect(project?.isValid, isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('isValid should return false when serverPath is null', () {
      final project = ServerPodProject(rootPath: projectRoot);
      expect(project.isValid, isFalse);
    });

    test('isValid should return false when configPath is null', () {
      // Create project with server but no config
      final project = ServerPodProject(
        rootPath: projectRoot,
        serverPath: serverPath,
      );

      // Remove config directory temporarily
      final configDir = Directory(configPath);
      final configBackupDir = Directory(
        p.join(projectRoot, 'config_backup')
      );

      try {
        if (configDir.existsSync()) {
          configDir.renameSync(configBackupDir.path);
        }

        expect(project.isValid, isFalse);
      } finally {
        if (configBackupDir.existsSync()) {
          configBackupDir.renameSync(configPath);
        }
      }
    });

    test('endpointFiles should find endpoint files', () {
      final originalDir = Directory.current.path;
      Directory.current = serverPath;

      try {
        final project = ServerPodProject.detect();
        final endpoints = project?.endpointFiles;
        expect(endpoints, isNotEmpty);
        expect(endpoints!.any((e) => e.contains('test_endpoint.dart')), isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('endpointFiles should return empty list when serverPath is null', () {
      final project = ServerPodProject(rootPath: projectRoot);
      expect(project.endpointFiles, isEmpty);
    });
  });

  group('ServerPodLocator', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('locator_test_');

      // Create minimal ServerPod project
      final serverPath = p.join(tempDir.path, 'test_server');
      Directory(p.join(serverPath, 'config')).createSync(recursive: true);
      Directory(p.join(serverPath, 'lib')).createSync(recursive: true);

      File(p.join(serverPath, 'pubspec.yaml')).writeAsStringSync('''
name: test_server
version: 1.0.0
dependencies:
  serverpod: ^2.0.0
''');

      // Create server.dart (required for valid ServerPod project)
      File(p.join(serverPath, 'lib', 'server.dart')).writeAsStringSync('''
// Server entry point
''');

      final clientPath = p.join(tempDir.path, 'test_client');
      Directory(p.join(clientPath, 'lib')).createSync(recursive: true);

      File(p.join(clientPath, 'pubspec.yaml')).writeAsStringSync('''
name: test_client
version: 1.0.0
dependencies:
  serverpod_client: ^2.0.0
''');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('getProject should cache result', () {
      final originalDir = Directory.current.path;
      Directory.current = p.join(tempDir.path, 'test_server');

      try {
        ServerPodLocator.resetCache();

        final project1 = ServerPodLocator.getProject();
        final project2 = ServerPodLocator.getProject();

        expect(identical(project1, project2), isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('getProject with forceReload should bypass cache', () {
      final originalDir = Directory.current.path;
      Directory.current = p.join(tempDir.path, 'test_server');

      try {
        ServerPodLocator.resetCache();

        final project1 = ServerPodLocator.getProject();
        final project2 = ServerPodLocator.getProject(forceReload: true);

        expect(identical(project1, project2), isFalse);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('resetCache should clear cached project', () {
      final originalDir = Directory.current.path;
      Directory.current = p.join(tempDir.path, 'test_server');

      try {
        ServerPodLocator.getProject();
        ServerPodLocator.resetCache();

        final project = ServerPodLocator.getProject();
        expect(project, isNotNull);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('isInServerPodProject should return true for valid project', () {
      final originalDir = Directory.current.path;
      Directory.current = p.join(tempDir.path, 'test_server');

      try {
        ServerPodLocator.resetCache();
        final result = ServerPodLocator.isInServerPodProject();
        expect(result, isTrue);
      } finally {
        Directory.current = originalDir;
      }
    });

    test('isInServerPodProject should return false for invalid project', () {
      final nonServerpodDir = Directory.systemTemp.createTempSync('non_serverpod_');

      try {
        ServerPodLocator.resetCache();
        final result = ServerPodLocator.isInServerPodProject(
          currentPath: nonServerpodDir.path
        );
        expect(result, isFalse);
      } finally {
        nonServerpodDir.deleteSync(recursive: true);
      }
    });

    test('getProject should accept custom currentPath', () {
      ServerPodLocator.resetCache();

      final project = ServerPodLocator.getProject(
        currentPath: p.join(tempDir.path, 'test_server')
      );

      expect(project, isNotNull);
      expect(project!.isValid, isTrue);
    });
  });

  group('ServerPodProject edge cases', () {
    test('detect should handle projects without flutter package', () {
      final tempDir = Directory.systemTemp.createTempSync('no_flutter_');

      try {
        // Create server package
        final serverPath = p.join(tempDir.path, 'test_server');
        Directory(p.join(serverPath, 'config')).createSync(recursive: true);
        Directory(p.join(serverPath, 'lib')).createSync(recursive: true);

        File(p.join(serverPath, 'pubspec.yaml')).writeAsStringSync('''
name: test_server
version: 1.0.0
dependencies:
  serverpod: ^2.0.0
''');

        // Create server.dart (required for valid ServerPod project)
        File(p.join(serverPath, 'lib', 'server.dart')).writeAsStringSync('''
// Server entry point
''');

        // Create client package
        final clientPath = p.join(tempDir.path, 'test_client');
        Directory(p.join(clientPath, 'lib')).createSync(recursive: true);

        File(p.join(clientPath, 'pubspec.yaml')).writeAsStringSync('''
name: test_client
version: 1.0.0
dependencies:
  serverpod_client: ^2.0.0
''');

        final originalDir = Directory.current.path;
        Directory.current = serverPath;

        try {
          final project = ServerPodProject.detect();
          expect(project, isNotNull);
          expect(project!.flutterPath, isNull);
        } finally {
          Directory.current = originalDir;
        }
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('detect should handle projects without client package', () {
      final tempDir = Directory.systemTemp.createTempSync('no_client_');

      try {
        // Create only server package
        final serverPath = p.join(tempDir.path, 'test_server');
        Directory(p.join(serverPath, 'config')).createSync(recursive: true);
        Directory(p.join(serverPath, 'lib')).createSync(recursive: true);

        File(p.join(serverPath, 'pubspec.yaml')).writeAsStringSync('''
name: test_server
version: 1.0.0
dependencies:
  serverpod: ^2.0.0
''');

        // Create server.dart (required for valid ServerPod project)
        File(p.join(serverPath, 'lib', 'server.dart')).writeAsStringSync('''
// Server entry point
''');

        final originalDir = Directory.current.path;
        Directory.current = serverPath;

        try {
          final project = ServerPodProject.detect();
          expect(project, isNotNull);
          expect(project!.clientPath, isNull);
        } finally {
          Directory.current = originalDir;
        }
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
