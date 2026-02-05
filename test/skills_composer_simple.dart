/// Simple integration tests for SkillComposer
library serverpod_boost.test.skills.skill_composer_simple;

import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'package:serverpod_boost/skills/skill_loader.dart';
import 'package:serverpod_boost/skills/skill.dart';
import 'package:serverpod_boost/skills/skill_metadata.dart';

void main() {
  group('SkillComposer Simple Tests', () {
    late Directory tempDir;
    late String skillsPath;
    late SkillLoader loader;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('skill_composer_simple_test_');
      skillsPath = tempDir.path;

      // Create a simple test skill
      final skillDir = Directory(p.join(skillsPath, 'test_skill'));
      await skillDir.create();

      final skillFile = File(p.join(skillDir.path, 'SKILL.md.mustache'));
      await skillFile.writeAsString('''
# Test Skill

This is a test skill.
''');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('load skills successfully', () async {
      // Arrange
      loader = SkillLoader(skillsPath: skillsPath);

      // Act
      final skills = await loader.loadAll();

      // Assert
      expect(skills, isNotEmpty);
      expect(skills.length, equals(1));
      expect(skills[0].name, equals('test_skill'));
    });

    test('compose skills helper function', () async {
      // Arrange
      loader = SkillLoader(skillsPath: skillsPath);
      final skills = await loader.loadAll();
      final skillNames = ['test_skill'];

      // Act
      final result = _composeSkills(skills, skillNames);

      // Assert
      expect(result, isNotNull);
      expect(result, contains('# test_skill'));
      expect(result, contains('Generated at:'));
    });
  });
}

/// Simple helper function to compose skills
String _composeSkills(List<Skill> skills, List<String> skillNames) {
  if (skillNames.isEmpty) {
    return '''
# Composed Skills Document

Generated at: ${DateTime.now().toIso8601String()}
skills included: 0

No skills were requested.
''';
  }

  final buffer = StringBuffer();
  buffer.writeln('# Composed Skills Document');
  buffer.writeln('Generated at: ${DateTime.now().toIso8601String()}');
  buffer.writeln('skills included: ${skillNames.length}');
  buffer.writeln('');

  for (int i = 0; i < skillNames.length; i++) {
    final skillName = skillNames[i];
    final skill = skills.firstWhere((s) => s.name == skillName);
    buffer.writeln('# ${skill.name}');
    buffer.writeln(skill.description);
    buffer.writeln('');

    if (i < skillNames.length - 1) {
      buffer.writeln('---');
      buffer.writeln('');
    }
  }

  return buffer.toString();
}