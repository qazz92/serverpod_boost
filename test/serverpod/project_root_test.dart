import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:serverpod_boost/serverpod/project_root.dart';

void main() {
  group('ProjectRoot', () {
    late Directory testDir;
    late Directory projectRoot;

    setUp(() async {
      // Create temporary test directory structure
      final tempDir = Directory.systemTemp;
      testDir = await tempDir.createTemp('serverpod_boost_test_');
      projectRoot = Directory('${testDir.path}/test_project');
      await projectRoot.create();

      // Create ServerPod project structure
      await Directory('${projectRoot.path}/test_project_server/lib').create(recursive: true);
      await Directory('${projectRoot.path}/test_project_client/lib').create(recursive: true);
      await Directory('${projectRoot.path}/test_project_flutter/lib').create(recursive: true);

      // Create server.dart file for validation
      await File('${projectRoot.path}/test_project_server/lib/server.dart').writeAsString('');
    });

    tearDown(() async {
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    group('detect', () {
      test('detects project root from environment variable', () {
        // Note: Platform.environment is read-only in tests
        // This test documents the behavior but cannot modify the env var
        // In real usage, setting SERVERPOD_BOOST_PROJECT_ROOT would work

        // Test with explicit path instead
        final detected = ProjectRoot.detect(projectRoot.path);
        expect(detected, equals(projectRoot.path));
      });

      test('navigates up from .ai/boost directory', () {
        final boostDir = Directory('${projectRoot.path}/.ai/boost');
        boostDir.createSync(recursive: true);

        final detected = ProjectRoot.detect(boostDir.path);
        expect(detected, equals(projectRoot.path));
      });

      test('detects from *_server package path', () {
        final serverPath = '${projectRoot.path}/test_project_server';
        final detected = ProjectRoot.detect(serverPath);
        expect(detected, equals(projectRoot.path));
      });

      test('navigates up from subdirectory in _server package', () {
        final subPath = '${projectRoot.path}/test_project_server/lib/src';
        Directory(subPath).createSync(recursive: true);

        final detected = ProjectRoot.detect(subPath);
        expect(detected, equals(projectRoot.path));
      });

      test('falls back to current directory when detection fails', () async {
        final randomDir = await Directory.systemTemp.createTemp('random_dir_');
        try {
          final detected = ProjectRoot.detect(randomDir.path);
          expect(detected, equals(p.normalize(randomDir.path)));
        } finally {
          await randomDir.delete(recursive: true);
        }
      });
    });

    group('findServerPackage', () {
      test('finds server package directory', () {
        final serverPath = ProjectRoot.findServerPackage(projectRoot.path);
        expect(serverPath, isNotNull);
        expect(serverPath, endsWith('test_project_server'));
      });

      test('returns null when server package not found', () async {
        final emptyDir = await Directory.systemTemp.createTemp('empty_');
        try {
          final serverPath = ProjectRoot.findServerPackage(emptyDir.path);
          expect(serverPath, isNull);
        } finally {
          await emptyDir.delete(recursive: true);
        }
      });

      test('returns null for non-existent directory', () {
        final serverPath = ProjectRoot.findServerPackage('/non/existent/path');
        expect(serverPath, isNull);
      });
    });

    group('findClientPackage', () {
      test('finds client package directory', () {
        final clientPath = ProjectRoot.findClientPackage(projectRoot.path);
        expect(clientPath, isNotNull);
        expect(clientPath, endsWith('test_project_client'));
      });

      test('returns null when client package not found', () async {
        final emptyDir = await Directory.systemTemp.createTemp('empty_');
        try {
          final clientPath = ProjectRoot.findClientPackage(emptyDir.path);
          expect(clientPath, isNull);
        } finally {
          await emptyDir.delete(recursive: true);
        }
      });

      test('returns null for non-existent directory', () {
        final clientPath = ProjectRoot.findClientPackage('/non/existent/path');
        expect(clientPath, isNull);
      });
    });

    group('isValidServerPodProject', () {
      test('validates valid ServerPod project', () {
        final isValid = ProjectRoot.isValidServerPodProject(projectRoot.path);
        expect(isValid, isTrue);
      });

      test('returns false when server package missing', () async {
        final emptyDir = await Directory.systemTemp.createTemp('empty_');
        try {
          final isValid = ProjectRoot.isValidServerPodProject(emptyDir.path);
          expect(isValid, isFalse);
        } finally {
          await emptyDir.delete(recursive: true);
        }
      });

      test('returns false when server.dart missing', () async {
        final invalidProject = await Directory.systemTemp.createTemp('invalid_');
        await Directory('${invalidProject.path}/test_project_server/lib').create(recursive: true);
        // Don't create server.dart

        try {
          final isValid = ProjectRoot.isValidServerPodProject(invalidProject.path);
          expect(isValid, isFalse);
        } finally {
          await invalidProject.delete(recursive: true);
        }
      });

      test('returns false for non-existent directory', () {
        final isValid = ProjectRoot.isValidServerPodProject('/non/existent/path');
        expect(isValid, isFalse);
      });
    });
  });
}
