/// skill:remove command
///
/// Removes a skill from the local skills directory.
library serverpod_boost.commands.skill_remove_command;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:serverpod_boost/cli/command.dart';

/// Command to remove a skill
class SkillRemoveCommand extends Command {
  /// Path to skills directory
  final String skillsPath;

  /// Name of the skill to remove
  final String? skillName;

  /// Force flag (skip confirmations)
  final bool force;

  /// Create a new skill remove command
  SkillRemoveCommand({
    this.skillsPath = '.ai/skills',
    this.skillName,
    this.force = false,
  });

  @override
  String get name => 'skill:remove';

  @override
  String get description => 'Remove a skill from the local skills directory';

  @override
  Future<void> run() async {
    if (skillName == null || skillName!.isEmpty) {
      _showUsage();
      return;
    }

    // Find the skill location
    final location = await _findSkillLocation(skillName!);

    if (location == null) {
      stderr.writeln('✗ Skill not found: $skillName');
      stderr.writeln('');
      stderr.writeln('Use "boost skill:list" to see available skills.');
      exit(1);
    }

    // Confirm removal unless force flag is set
    if (!force) {
      print('Removing skill: $skillName');
      print('Location: ${location.path}');
      print('');
      print('This will permanently delete the skill directory.');
      print('Use --force to skip this confirmation.');

      // In a real interactive version, we would ask for confirmation here
      // For now, we'll proceed with a warning
      print('');
      print('To confirm, run with --force flag:');
      print('  boost skill:remove $skillName --force');
      return;
    }

    // Remove the skill
    try {
      await location.delete(recursive: true);
      print('✓ Skill removed: $skillName');
      print('');
      print('Location: ${location.path}');
    } catch (e) {
      stderr.writeln('✗ Failed to remove skill: $e');
      exit(1);
    }
  }

  /// Find the location of a skill
  ///
  /// Searches in multiple possible locations:
  /// 1. .ai/skills/<name> (local skill)
  /// 2. .ai/skills/remote/*/<name> (remote skill)
  /// 3. .ai/skills/serverpod/<name> (built-in skill override)
  Future<Directory?> _findSkillLocation(String name) async {
    final possiblePaths = [
      p.join(skillsPath, name),
      p.join(skillsPath, 'serverpod', name),
      p.join(skillsPath, 'remote'),
    ];

    // Check direct paths first
    for (final path in possiblePaths.where((p) => !p.endsWith('remote'))) {
      final dir = Directory(path);
      if (await dir.exists()) {
        final skillFile = File(p.join(dir.path, 'SKILL.md.mustache'));
        if (await skillFile.exists()) {
          return dir;
        }
      }
    }

    // Search in remote directory
    final remoteDir = Directory(p.join(skillsPath, 'remote'));
    if (await remoteDir.exists()) {
      await for (final entity in remoteDir.list(recursive: true)) {
        if (entity is Directory && p.basename(entity.path) == name) {
          final skillFile = File(p.join(entity.path, 'SKILL.md.mustache'));
          if (await skillFile.exists()) {
            return entity;
          }
        }
      }
    }

    return null;
  }

  /// Show usage information
  void _showUsage() {
    print('Usage: boost skill:remove <name> [options]');
    print('');
    print('Arguments:');
    print('  name        Name of the skill to remove');
    print('');
    print('Options:');
    print('  --force     Skip confirmation and remove immediately');
    print('');
    print('Examples:');
    print('  boost skill:remove my-skill');
    print('  boost skill:remove my-skill --force');
    print('');
    print('Note: This removes the skill from your local .ai/skills directory.');
    print('      It does not affect remote repositories.');
  }
}
