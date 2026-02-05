/// Unit tests for SkillLoader
library serverpod_boost.test.skills.skill_loader_test;

import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'package:serverpod_boost/skills/skill_loader.dart';
import 'package:serverpod_boost/skills/skill_metadata.dart';

void main() {
  group('SkillLoader', () {
    late Directory tempDir;
    late String skillsPath;
    late SkillLoader loader;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('skill_loader_test_');
      skillsPath = tempDir.path;

      // Create test skill directories
      await _createTestSkill(skillsPath, 'core', 'Core skill');
      await _createTestSkill(skillsPath, 'endpoints', 'Endpoints skill');
      await _createTestSkill(skillsPath, 'models', 'Models skill');

      // Create skill with metadata
      await _createTestSkillWithMetadata(
        skillsPath,
        'advanced',
        'Advanced skill',
        SkillMetadata(
          description: 'Advanced skill with metadata',
          version: '2.0.0',
          dependencies: ['core', 'models'],
          tags: ['advanced', 'expert'],
        ),
      );

      // Create nested skill structure
      final serverpodDir = Directory(p.join(skillsPath, 'serverpod'));
      await serverpodDir.create();
      await _createTestSkill(serverpodDir.path, 'testing', 'Testing skill');

      loader = SkillLoader(skillsPath: skillsPath);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('loadAll loads all skills', () async {
      final skills = await loader.loadAll();

      expect(skills, isNotEmpty);
      expect(skills.length, greaterThanOrEqualTo(4));

      final skillNames = skills.map((s) => s.name).toList();
      expect(skillNames, contains('core'));
      expect(skillNames, contains('endpoints'));
      expect(skillNames, contains('models'));
      expect(skillNames, contains('advanced'));
    });

    test('loadSkill loads specific skill by name', () async {
      final skill = await loader.loadSkill('core');

      expect(skill, isNotNull);
      expect(skill!.name, equals('core'));
      expect(skill.template, contains('# Core skill'));
    });

    test('loadSkill loads skill from nested directory', () async {
      final skill = await loader.loadSkill('testing');

      expect(skill, isNotNull);
      expect(skill!.name, equals('testing'));
    });

    test('loadSkill returns null for non-existent skill', () async {
      final skill = await loader.loadSkill('nonexistent');

      expect(skill, isNull);
    });

    test('loadFromDirectory loads skills from subdirectory', () async {
      final skills = await loader.loadFromDirectory('serverpod');

      expect(skills, isNotEmpty);
      expect(skills.any((s) => s.name == 'testing'), isTrue);
    });

    test('exists returns true for existing skill', () async {
      final exists = await loader.exists('core');

      expect(exists, isTrue);
    });

    test('exists returns false for non-existent skill', () async {
      final exists = await loader.exists('nonexistent');

      expect(exists, isFalse);
    });

    test('listSkillNames returns sorted list of names', () async {
      final names = await loader.listSkillNames();

      expect(names, isNotEmpty);
      // Check sorted
      final sorted = List.from(names)..sort();
      expect(names, equals(sorted));
    });

    test('skill with metadata loads correctly', () async {
      final skill = await loader.loadSkill('advanced');

      expect(skill, isNotNull);
      expect(skill!.metadata.description, equals('Advanced skill with metadata'));
      expect(skill.metadata.version, equals('2.0.0'));
      expect(skill.metadata.dependencies, equals(['core', 'models']));
      expect(skill.metadata.tags, equals(['advanced', 'expert']));
    });

    test('skill without metadata uses defaults', () async {
      final skill = await loader.loadSkill('core');

      expect(skill, isNotNull);
      expect(skill!.metadata.version, equals('1.0.0'));
      expect(skill.metadata.dependencies, isEmpty);
      expect(skill.metadata.tags, isEmpty);
    });

    test('loadAll handles invalid skills gracefully', () async {
      // Create invalid skill (directory without SKILL.md.mustache)
      final invalidDir = Directory(p.join(skillsPath, 'invalid'));
      await invalidDir.create();

      final skills = await loader.loadAll();

      // Should still load valid skills
      expect(skills, isNotEmpty);
      expect(skills.any((s) => s.name == 'invalid'), isFalse);
    });

    test('throws SkillLoadException for non-existent directory', () async {
      final badLoader = SkillLoader(skillsPath: '/nonexistent/path');

      expect(
        () => badLoader.loadAll(),
        throwsA(isA<SkillLoadException>()),
      );
    });
  });

  group('SkillLoadException', () {
    test('toString with path includes path', () {
      final exception = SkillLoadException('Test error', '/some/path');

      expect(
        exception.toString(),
        equals('SkillLoadException: Test error (at /some/path)'),
      );
    });

    test('toString without path omits path', () {
      final exception = SkillLoadException('Test error');

      expect(
        exception.toString(),
        equals('SkillLoadException: Test error'),
      );
    });
  });
}

/// Helper to create a test skill
Future<void> _createTestSkill(String basePath, String name, String title) async {
  final skillDir = Directory(p.join(basePath, name));
  await skillDir.create();

  final skillFile = File(p.join(skillDir.path, 'SKILL.md.mustache'));
  await skillFile.writeAsString('# $title\n\nThis is the $name skill.');
}

/// Helper to create a test skill with metadata
Future<void> _createTestSkillWithMetadata(
  String basePath,
  String name,
  String title,
  SkillMetadata metadata,
) async {
  final skillDir = Directory(p.join(basePath, name));
  await skillDir.create();

  final skillFile = File(p.join(skillDir.path, 'SKILL.md.mustache'));
  await skillFile.writeAsString('# $title\n\nContent for $name.');

  final metaFile = File(p.join(skillDir.path, 'meta.yaml'));
  final metaContent = '''
description: ${metadata.description}
version: ${metadata.version}
dependencies:
${metadata.dependencies.map((d) => '  - $d').join('\n')}
tags:
${metadata.tags.map((t) => '  - $t').join('\n')}
''';
  await metaFile.writeAsString(metaContent);
}
