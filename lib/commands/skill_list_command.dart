/// skill:list command
///
/// Lists all available skills.
library serverpod_boost.commands.skill_list_command;

import 'dart:io';
import 'package:serverpod_boost/cli/command.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';

/// Command to list all available skills
class SkillListCommand extends Command {
  /// Path to skills directory
  final String skillsPath;

  /// Create a new skill list command
  SkillListCommand({this.skillsPath = '.ai/skills'});

  @override
  String get name => 'skill:list';

  @override
  String get description => 'List all available skills';

  @override
  Future<void> run() async {
    try {
      final loader = SkillLoader(skillsPath: skillsPath);
      final skills = await loader.loadAll();

      if (skills.isEmpty) {
        print('No skills found in $skillsPath');
        return;
      }

      // Sort skills by name
      skills.sort((a, b) => a.name.compareTo(b.name));

      print('Available Skills (${skills.length}):');
      print('');

      for (final skill in skills) {
        print('  ${skill.name}');
        if (skill.description.isNotEmpty) {
          print('    ${skill.description}');
        }
        if (skill.metadata.hasDependencies) {
          print('    Depends on: ${skill.metadata.dependencies.join(', ')}');
        }
        if (skill.metadata.hasVersionRequirement) {
          print('    Requires ServerPod: ${skill.metadata.minServerpodVersion}');
        }
        if (skill.metadata.tags.isNotEmpty) {
          print('    Tags: ${skill.metadata.tags.join(', ')}');
        }
        print('');
      }
    } catch (e) {
      stderr.writeln('Error loading skills: $e');
      exit(1);
    }
  }
}
