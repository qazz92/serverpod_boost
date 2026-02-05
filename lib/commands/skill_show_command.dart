/// skill:show command
///
/// Shows details of a specific skill.
library serverpod_boost.commands.skill_show_command;

import 'dart:io';
import 'package:serverpod_boost/cli/command.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';
import 'package:serverpod_boost/skills/skill.dart';

/// Command to show details of a specific skill
class SkillShowCommand extends Command {
  /// Path to skills directory
  final String skillsPath;

  /// Name of the skill to show
  final String? skillName;

  /// Create a new skill show command
  SkillShowCommand({
    this.skillsPath = '.ai/skills',
    this.skillName,
  });

  @override
  String get name => 'skill:show';

  @override
  String get description => 'Show details of a specific skill';

  @override
  Future<void> run() async {
    if (skillName == null || skillName!.isEmpty) {
      stderr.writeln('Error: Skill name is required');
      stderr.writeln('');
      stderr.writeln('Usage: boost skill:show <skill-name>');
      exit(1);
    }

    try {
      final loader = SkillLoader(skillsPath: skillsPath);
      final skill = await loader.loadSkill(skillName!);

      if (skill == null) {
        stderr.writeln('Error: Skill "$skillName" not found');
        stderr.writeln('');
        stderr.writeln('Run "boost skill:list" to see available skills');
        exit(1);
      }

      _displaySkill(skill);
    } catch (e) {
      stderr.writeln('Error loading skill: $e');
      exit(1);
    }
  }

  /// Display skill details
  void _displaySkill(Skill skill) {
    final lineLength = skill.name.length + 7;
    print('Skill: ${skill.name}');
    print('=' * lineLength);
    print('');

    if (skill.description.isNotEmpty) {
      print('Description:');
      print('  ${skill.description}');
      print('');
    }

    print('Metadata:');
    print('  Version: ${skill.metadata.version}');

    if (skill.metadata.hasVersionRequirement) {
      print('  Min ServerPod Version: ${skill.metadata.minServerpodVersion}');
    }

    if (skill.metadata.hasDependencies) {
      print('  Dependencies:');
      for (final dep in skill.metadata.dependencies) {
        print('    - $dep');
      }
    } else {
      print('  Dependencies: none');
    }

    if (skill.metadata.tags.isNotEmpty) {
      print('  Tags: ${skill.metadata.tags.join(', ')}');
    }

    print('  Source: ${skill.metadata.source}');

    print('');
    print('Template:');
    print('---');
    print(skill.template);
    print('---');
  }
}
