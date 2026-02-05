/// skill:render command
///
/// Renders a skill template with current project context.
library serverpod_boost.commands.skill_render_command;

import 'dart:io';
import 'package:serverpod_boost/cli/command.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';
import 'package:serverpod_boost/skills/template_renderer.dart';
import 'package:serverpod_boost/serverpod/serverpod_locator.dart';
import 'package:serverpod_boost/project_context.dart';

/// Command to render a skill template
class SkillRenderCommand extends Command {
  /// Path to skills directory
  final String skillsPath;

  /// Name of the skill to render
  final String? skillName;

  /// Output file path (optional)
  final String? outputPath;

  /// Create a new skill render command
  SkillRenderCommand({
    this.skillsPath = '.ai/skills',
    this.skillName,
    this.outputPath,
  });

  @override
  String get name => 'skill:render';

  @override
  String get description => 'Render a skill template';

  @override
  Future<void> run() async {
    if (skillName == null || skillName!.isEmpty) {
      stderr.writeln('Error: Skill name is required');
      stderr.writeln('');
      stderr.writeln('Usage: boost skill:render <skill-name> [output-file]');
      exit(1);
    }

    try {
      // Load the skill
      final loader = SkillLoader(skillsPath: skillsPath);
      final skill = await loader.loadSkill(skillName!);

      if (skill == null) {
        stderr.writeln('Error: Skill "$skillName" not found');
        stderr.writeln('');
        stderr.writeln('Run "boost skill:list" to see available skills');
        exit(1);
      }

      // Detect ServerPod project for context
      final project = ServerPodLocator.getProject();
      if (project == null || !project.isValid) {
        stderr.writeln('Warning: Not a valid ServerPod project');
        stderr.writeln('Rendering with minimal context...');
        print('');

        final context = const ProjectContext(
          projectName: 'unknown',
          serverpodVersion: '3.2.3',
          rootPath: '.',
        );

        final renderer = TemplateRenderer(context: context);
        final rendered = renderer.render(skill.template, {});
        _outputRendered(rendered, outputPath);
        return;
      }

      // Build context from project
      final projectContext = ProjectContext.fromProject(project);

      // Render the template
      final renderer = TemplateRenderer(context: projectContext);
      final rendered = renderer.render(skill.template, {});

      _outputRendered(rendered, outputPath);
    } catch (e) {
      stderr.writeln('Error rendering skill: $e');
      exit(1);
    }
  }

  /// Output rendered content
  void _outputRendered(String content, String? path) {
    if (path != null && path.isNotEmpty) {
      try {
        final file = File(path);
        file.parent.createSync(recursive: true);
        file.writeAsStringSync(content);
        print('Rendered skill written to: $path');
      } catch (e) {
        stderr.writeln('Error writing to file: $e');
        exit(1);
      }
    } else {
      print(content);
    }
  }
}
