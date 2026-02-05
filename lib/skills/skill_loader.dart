/// Skill loader
///
/// Loads skills from the file system.
library serverpod_boost.skills.skill_loader;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'skill.dart';
import 'skill_metadata.dart';

/// Exception thrown when skill loading fails
class SkillLoadException implements Exception {

  const SkillLoadException(this.message, [this.path]);
  final String message;
  final String? path;

  @override
  String toString() {
    if (path != null) {
      return 'SkillLoadException: $message (at $path)';
    }
    return 'SkillLoadException: $message';
  }
}

/// Loads skills from the file system
class SkillLoader {

  const SkillLoader({required this.skillsPath});
  /// Base path to skills directory
  final String skillsPath;

  /// Load all available skills
  Future<List<Skill>> loadAll() async {
    final skillsDir = Directory(skillsPath);
    if (!await skillsDir.exists()) {
      throw SkillLoadException('Skills directory not found', skillsPath);
    }

    final skills = <Skill>[];

    await for (final entity in skillsDir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('SKILL.md.mustache')) {
        try {
          final skill = await _loadSkill(entity);
          skills.add(skill);
        } catch (e) {
          // Skip invalid skills, log warning
          // TODO: Add logging
          continue;
        }
      }
    }

    return skills;
  }

  /// Load a specific skill by name
  Future<Skill?> loadSkill(String name) async {
    // Try loading from different possible locations
    final possiblePaths = [
      p.join(skillsPath, name, 'SKILL.md.mustache'),
      p.join(skillsPath, 'serverpod', name, 'SKILL.md.mustache'),
      p.join(skillsPath, 'remote', name, 'SKILL.md.mustache'),
    ];

    for (final skillPath in possiblePaths) {
      final file = File(skillPath);
      if (await file.exists()) {
        return await _loadSkill(file);
      }
    }

    return null;
  }

  /// Load skills from a specific subdirectory
  Future<List<Skill>> loadFromDirectory(String subdirectory) async {
    final dirPath = p.join(skillsPath, subdirectory);
    final dir = Directory(dirPath);

    if (!await dir.exists()) {
      return [];
    }

    final skills = <Skill>[];

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('SKILL.md.mustache')) {
        try {
          final skill = await _loadSkill(entity);
          skills.add(skill);
        } catch (e) {
          continue;
        }
      }
    }

    return skills;
  }

  /// Check if a skill exists
  Future<bool> exists(String name) async {
    final skill = await loadSkill(name);
    return skill != null;
  }

  /// List all skill names
  Future<List<String>> listSkillNames() async {
    final skills = await loadAll();
    return skills.map((s) => s.name).toList()..sort();
  }

  /// Load a skill from a file
  Future<Skill> _loadSkill(File file) async {
    final content = await file.readAsString();
    final skillName = p.basename(p.dirname(file.path));

    // Try to load metadata from meta.yaml
    final metaFile = File(p.join(p.dirname(file.path), 'meta.yaml'));
    late final SkillMetadata metadata;

    if (await metaFile.exists()) {
      try {
        final yamlContent = await metaFile.readAsString();
        final yaml = loadYaml(yamlContent) as Map;
        metadata = SkillMetadata.fromYaml(yaml);
      } catch (e) {
        // If metadata fails to load, use defaults
        metadata = SkillMetadata.defaults;
      }
    } else {
      metadata = SkillMetadata.defaults;
    }

    return Skill(
      name: skillName,
      description: metadata.description,
      template: content,
      metadata: metadata,
    );
  }

  /// Get the skill directory path for a given skill name
  String getSkillPath(String name) {
    return p.join(skillsPath, name);
  }
}
