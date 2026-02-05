/// Skill composer
///
/// Composes multiple skills into a single document.
library serverpod_boost.skills.skill_composer;

import '../project_context.dart';
import 'skill.dart';
import 'skill_loader.dart';
import 'template_renderer.dart';

/// Exception thrown when skill composition fails
class SkillCompositionException implements Exception {

  const SkillCompositionException(this.message);
  final String message;

  @override
  String toString() => 'SkillCompositionException: $message';
}

/// Exception thrown when a required skill is missing
class SkillNotFoundException implements Exception {

  const SkillNotFoundException(this.skillName, [this.searchedPaths = const []]);
  final String skillName;
  final List<String> searchedPaths;

  @override
  String toString() {
    if (searchedPaths.isNotEmpty) {
      return 'SkillNotFoundException: Skill "$skillName" not found. Searched in: ${searchedPaths.join(", ")}';
    }
    return 'SkillNotFoundException: Skill "$skillName" not found';
  }
}

/// Exception thrown when skill dependencies are not satisfied
class UnsatisfiedDependencyException implements Exception {

  const UnsatisfiedDependencyException(this.skillName, this.missingDependencies);
  final String skillName;
  final List<String> missingDependencies;

  @override
  String toString() {
    return 'UnsatisfiedDependencyException: Skill "$skillName" has unsatisfied dependencies: ${missingDependencies.join(", ")}';
  }
}

/// Exception thrown when circular dependencies are detected
class CircularDependencyException implements Exception {

  const CircularDependencyException(this.cycle);
  final List<String> cycle;

  @override
  String toString() {
    return 'CircularDependencyException: Circular dependency detected: ${cycle.join(" -> ")} -> ${cycle.first}';
  }
}

/// Composes multiple skills into a single document
class SkillComposer {

  const SkillComposer({
    required this.loader,
    required this.renderer,
  });
  /// Skill loader for loading skills
  final SkillLoader loader;

  /// Template renderer for rendering skill templates
  final TemplateRenderer renderer;

  /// Compose multiple skills into one document
  ///
  /// Takes a list of skill names and composes them into a single
  /// document with a header and rendered skill sections.
  ///
  /// Throws [SkillNotFoundException] if any skill is not found.
  /// Throws [UnsatisfiedDependencyException] if dependencies are not met.
  /// Throws [CircularDependencyException] if circular dependencies exist.
  Future<String> compose(List<String> skillNames, ProjectContext context) async {
    final skills = await _loadSkills(skillNames);
    _validateDependencies(skills);

    final sections = <String>[];

    // Add header
    sections.add(_buildHeader(skills));

    // Add each skill
    for (final skill in skills) {
      sections.add(await _renderSkill(skill, context));
    }

    return sections.join('\n\n---\n\n');
  }

  /// Load skills by name
  ///
  /// Throws [SkillNotFoundException] if any skill is not found.
  Future<List<Skill>> _loadSkills(List<String> names) async {
    final skills = <Skill>[];
    final missingSkills = <String>[];

    for (final name in names) {
      final skill = await loader.loadSkill(name);
      if (skill == null) {
        missingSkills.add(name);
      } else {
        skills.add(skill);
      }
    }

    if (missingSkills.isNotEmpty) {
      final searchedPaths = [
        loader.getSkillPath('<skill>'),
        loader.getSkillPath('serverpod/<skill>'),
        loader.getSkillPath('remote/<skill>'),
      ];
      throw SkillNotFoundException(missingSkills.first, searchedPaths);
    }

    return skills;
  }

  /// Validate that all skill dependencies are satisfied
  ///
  /// Throws [UnsatisfiedDependencyException] if dependencies are missing.
  /// Throws [CircularDependencyException] if circular dependencies exist.
  void _validateDependencies(List<Skill> skills) {
    // Build a map of skill names to skills
    final skillMap = {for (var s in skills) s.name: s};

    // Check for circular dependencies first
    _detectCircularDependencies(skillMap);

    // Check that all dependencies are satisfied
    for (final skill in skills) {
      if (skill.hasDependencies) {
        final missingDeps = skill.metadata.dependencies
            .where((dep) => !skillMap.containsKey(dep))
            .toList();

        if (missingDeps.isNotEmpty) {
          throw UnsatisfiedDependencyException(skill.name, missingDeps);
        }
      }
    }
  }

  /// Detect circular dependencies using DFS
  ///
  /// Throws [CircularDependencyException] if a cycle is found.
  void _detectCircularDependencies(Map<String, Skill> skillMap) {
    final visited = <String>{};
    final recursionStack = <String>{};
    final path = <String>[];

    void dfs(String skillName) {
      if (recursionStack.contains(skillName)) {
        // Found a cycle - extract it from the path
        final cycleStart = path.indexOf(skillName);
        final cycle = path.sublist(cycleStart);
        throw CircularDependencyException(cycle);
      }

      if (visited.contains(skillName)) {
        return;
      }

      visited.add(skillName);
      recursionStack.add(skillName);
      path.add(skillName);

      final skill = skillMap[skillName];
      if (skill != null && skill.hasDependencies) {
        for (final dep in skill.metadata.dependencies) {
          if (skillMap.containsKey(dep)) {
            dfs(dep);
          }
        }
      }

      recursionStack.remove(skillName);
      path.removeLast();
    }

    for (final skillName in skillMap.keys) {
      if (!visited.contains(skillName)) {
        dfs(skillName);
      }
    }
  }

  /// Build the header section of the composed document
  String _buildHeader(List<Skill> skills) {
    final timestamp = DateTime.now().toIso8601String();
    final skillList = skills.map((s) => s.name).join(', ');

    final buffer = StringBuffer();
    buffer.writeln('# ServerPod Boost Skills');
    buffer.writeln();
    buffer.writeln('**Generated:** $timestamp');
    buffer.writeln('**Skills:** $skillList');
    buffer.writeln();

    // Add skill descriptions
    if (skills.any((s) => s.description.isNotEmpty)) {
      buffer.writeln('## Skills Overview');
      buffer.writeln();
      for (final skill in skills) {
        buffer.writeln('- **${skill.name}**${skill.description.isNotEmpty ? ': ${skill.description}' : ''}');
      }
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln();

    return buffer.toString();
  }

  /// Render a single skill with the given context
  Future<String> _renderSkill(Skill skill, ProjectContext context) async {
    // Create a renderer with the current context
    final skillRenderer = TemplateRenderer(context: context);

    // Render the template
    final rendered = skillRenderer.render(skill.template);

    // Add skill name as heading
    final buffer = StringBuffer();
    buffer.writeln('## ${skill.name}');
    if (skill.description.isNotEmpty) {
      buffer.writeln('*${skill.description}*');
      buffer.writeln();
    }
    buffer.writeln(rendered);

    return buffer.toString();
  }

  /// Get an ordered list of skills based on dependencies
  ///
  /// Returns skills in topological order so that dependencies
  /// appear before dependent skills.
  List<Skill> sortSkillsByDependencies(List<Skill> skills) {
    final skillMap = {for (var s in skills) s.name: s};
    final visited = <String>{};
    final result = <Skill>[];

    void visit(String skillName) {
      if (visited.contains(skillName)) return;

      visited.add(skillName);

      final skill = skillMap[skillName];
      if (skill != null && skill.hasDependencies) {
        for (final dep in skill.metadata.dependencies) {
          if (skillMap.containsKey(dep)) {
            visit(dep);
          }
        }
      }

      if (skill != null) {
        result.add(skill);
      }
    }

    for (final skill in skills) {
      visit(skill.name);
    }

    return result;
  }
}
