/// A ServerPod Boost skill
///
/// Skills are reusable AI capability templates that provide context
/// and guidance for AI assistants working with ServerPod projects.
library serverpod_boost.skills.skill;

import 'skill_metadata.dart';

/// A ServerPod Boost skill
class Skill {

  const Skill({
    required this.name,
    this.description = '',
    required this.template,
    SkillMetadata? metadata,
  }) : metadata = metadata ?? SkillMetadata.defaults;

  /// Create a skill from a template file
  factory Skill.fromFile(
    String name,
    String template, {
    SkillMetadata? metadata,
  }) {
    return Skill(
      name: name,
      description: metadata?.description ?? '',
      template: template,
      metadata: metadata ?? SkillMetadata.defaults,
    );
  }
  /// Unique name of the skill
  final String name;

  /// Human-readable description
  final String description;

  /// Mustache template content
  final String template;

  /// Skill metadata
  final SkillMetadata metadata;

  /// Check if this skill depends on another skill
  bool dependsOn(String skillName) {
    return metadata.dependsOn(skillName);
  }

  /// Check if this skill has any dependencies
  bool get hasDependencies => metadata.hasDependencies;

  /// Check if this skill has a minimum ServerPod version requirement
  bool get hasVersionRequirement => metadata.hasVersionRequirement;

  @override
  String toString() {
    return 'Skill(name: $name, description: $description, version: ${metadata.version})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Skill &&
        other.name == name &&
        other.template == template;
  }

  @override
  int get hashCode => Object.hash(name, template);
}
