/// skill:add command
///
/// Adds a skill from a GitHub repository.
library serverpod_boost.commands.skill_add_command;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:serverpod_boost/cli/command.dart';
import 'package:serverpod_boost/skills/github_skill_fetcher.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';
import 'package:serverpod_boost/skills/skill_metadata.dart';

/// Command to add a skill from a GitHub repository
class SkillAddCommand extends Command {
  /// Path to skills directory
  final String skillsPath;

  /// Repository to fetch from (format: owner/repo)
  final String? repo;

  /// Skill name to fetch (optional, lists all if null)
  final String? skillName;

  /// Force flag (skip confirmations)
  final bool force;

  /// Create a new skill add command
  SkillAddCommand({
    this.skillsPath = '.ai/skills',
    this.repo,
    this.skillName,
    this.force = false,
  });

  @override
  String get name => 'skill:add';

  @override
  String get description => 'Add a skill from a GitHub repository';

  @override
  Future<void> run() async {
    if (repo == null || repo!.isEmpty) {
      _showUsage();
      return;
    }

    // Validate repo format
    if (!_isValidRepoFormat(repo!)) {
      stderr.writeln('✗ Invalid repository format: $repo');
      stderr.writeln('Expected format: owner/repo');
      exit(1);
    }

    final fetcher = GitHubSkillFetcher(skillsPath: skillsPath);

    try {
      if (skillName == null || skillName!.isEmpty) {
        // List available skills
        await _listSkills(fetcher, repo!);
      } else {
        // Add specific skill
        await _addSkill(fetcher, repo!, skillName!);
      }
    } on SkillLoadException catch (e) {
      stderr.writeln('✗ ${e.message}');
      exit(1);
    } catch (e) {
      stderr.writeln('✗ Error: $e');
      exit(1);
    } finally {
      fetcher.close();
    }
  }

  /// List available skills in a repository
  Future<void> _listSkills(GitHubSkillFetcher fetcher, String repo) async {
    print('Fetching skills from $repo...');
    print('');

    final skills = await fetcher.listSkills(repo);

    if (skills.isEmpty) {
      print('  No skills found');
      print('');
      print('Make sure the repository has a .ai/skills/ directory with skill subdirectories.');
      return;
    }

    print('Available Skills (${skills.length}):');
    print('');

    for (final skill in skills) {
      print('  • $skill');
    }

    print('');
    print('To add a skill, run:');
    print('  boost skill:add $repo <skill-name>');
  }

  /// Add a specific skill from a repository
  Future<void> _addSkill(
    GitHubSkillFetcher fetcher,
    String repo,
    String skillName,
  ) async {
    // Check if skill already exists locally
    final loader = SkillLoader(skillsPath: skillsPath);
    if (await loader.exists(skillName)) {
      stderr.writeln('✗ Skill already exists locally: $skillName');
      stderr.writeln('');
      stderr.writeln('Use "boost skill:remove $skillName" to remove it first,');
      stderr.writeln('or install to a different location.');
      exit(1);
    }

    print('Adding $skillName from $repo...');

    // Fetch the skill
    final skill = await fetcher.fetchSkill(repo, skillName);

    // Install to local skills directory
    final localDir = Directory(p.join(skillsPath, 'remote', repo, skillName));
    await localDir.create(recursive: true);

    // Write the skill template
    final skillFile = File(p.join(localDir.path, 'SKILL.md.mustache'));
    await skillFile.writeAsString(skill.template);

    // Write metadata if available
    if (skill.metadata.description.isNotEmpty ||
        skill.metadata.dependencies.isNotEmpty ||
        skill.metadata.tags.isNotEmpty) {
      final metaFile = File(p.join(localDir.path, 'meta.yaml'));
      final metaContent = _generateMetaYaml(skill.metadata);
      await metaFile.writeAsString(metaContent);
    }

    print('✓ Skill installed successfully');
    print('');
    print('Location: ${localDir.path}');
    print('');

    // Show usage
    print('You can now use this skill:');
    print('  boost skill:show $skillName');
    print('  boost skill:render $skillName');
    print('  boost install --with-skill $skillName');

    // Show dependencies if any
    if (skill.metadata.hasDependencies) {
      print('');
      print('Dependencies: ${skill.metadata.dependencies.join(', ')}');
    }

    // Show tags if any
    if (skill.metadata.tags.isNotEmpty) {
      print('Tags: ${skill.metadata.tags.join(', ')}');
    }
  }

  /// Generate YAML metadata from skill metadata
  String _generateMetaYaml(SkillMetadata metadata) {
    final buffer = StringBuffer();

    if (metadata.description.isNotEmpty) {
      buffer.writeln('description: ${metadata.description}');
    }

    if (metadata.version != '1.0.0') {
      buffer.writeln('version: ${metadata.version}');
    }

    if (metadata.minServerpodVersion != null) {
      buffer.writeln('minServerpodVersion: ${metadata.minServerpodVersion}');
    }

    if (metadata.dependencies.isNotEmpty) {
      buffer.writeln('dependencies:');
      for (final dep in metadata.dependencies) {
        buffer.writeln('  - $dep');
      }
    }

    if (metadata.tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in metadata.tags) {
        buffer.writeln('  - $tag');
      }
    }

    return buffer.toString().trim();
  }

  /// Validate repository format (owner/repo)
  bool _isValidRepoFormat(String repo) {
    final parts = repo.split('/');
    return parts.length == 2 && parts.every((part) => part.isNotEmpty);
  }

  /// Show usage information
  void _showUsage() {
    print('Usage: boost skill:add <repo> [skill]');
    print('');
    print('Arguments:');
    print('  repo        GitHub repository in format "owner/repo"');
    print('  skill       Optional skill name to add (lists all if omitted)');
    print('');
    print('Examples:');
    print('  boost skill:add username/repo');
    print('  boost skill:add username/repo specific-skill');
    print('');
    print('Environment Variables:');
    print('  GITHUB_TOKEN    Optional GitHub token for API authentication');
  }
}
