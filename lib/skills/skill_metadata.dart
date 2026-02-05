/// Metadata for a skill
///
/// Contains information about a skill's source, version, dependencies, etc.
library serverpod_boost.skills.skill_metadata;

/// Source of a skill (built-in, local, or remote)
enum SkillSourceType {
  /// Built-in skill shipped with serverpod_boost
  builtin,

  /// Local custom skill
  local,

  /// Remote skill from GitHub
  github,

  /// Cached remote skill
  cached,
}

/// Source information for a skill
class SkillSource {

  const SkillSource({required this.type, this.location, this.version});

  /// Create a built-in skill source
  const SkillSource.builtin()
    : type = SkillSourceType.builtin,
      location = null,
      version = null;

  /// Create a GitHub skill source
  factory SkillSource.github(String repo) {
    return SkillSource(type: SkillSourceType.github, location: repo);
  }

  /// Create a cached skill source
  const SkillSource.cached()
    : type = SkillSourceType.cached,
      location = null,
      version = null;
  final SkillSourceType type;
  final String? location;
  final String? version;

  @override
  String toString() {
    switch (type) {
      case SkillSourceType.builtin:
        return 'built-in';
      case SkillSourceType.local:
        return 'local';
      case SkillSourceType.github:
        return 'github:$location';
      case SkillSourceType.cached:
        return 'cached';
    }
  }
}

/// Metadata about a skill
class SkillMetadata {

  const SkillMetadata({
    this.description = '',
    this.version = '1.0.0',
    this.minServerpodVersion,
    this.dependencies = const [],
    this.source = const SkillSource.builtin(),
    this.tags = const [],
  });

  /// Create from YAML map
  factory SkillMetadata.fromYaml(Map<dynamic, dynamic> yaml) {
    final deps = yaml['dependencies'] as List<dynamic>?;
    final tags = yaml['tags'] as List<dynamic>?;

    return SkillMetadata(
      description: yaml['description'] as String? ?? '',
      version: yaml['version'] as String? ?? '1.0.0',
      minServerpodVersion: yaml['minServerpodVersion'] as String?,
      dependencies: deps?.map((e) => e.toString()).toList() ?? [],
      tags: tags?.map((e) => e.toString()).toList() ?? [],
    );
  }
  /// Human-readable description
  final String description;

  /// Skill version
  final String version;

  /// Minimum ServerPod version required (optional)
  final String? minServerpodVersion;

  /// Other skills this skill depends on
  final List<String> dependencies;

  /// Source of this skill
  final SkillSource source;

  /// Tags for categorization
  final List<String> tags;

  /// Default metadata instance
  static const defaults = SkillMetadata();

  /// Check if this skill depends on another skill
  bool dependsOn(String skillName) {
    return dependencies.contains(skillName);
  }

  /// Check if this skill has any dependencies
  bool get hasDependencies => dependencies.isNotEmpty;

  /// Check if this skill has a minimum ServerPod version requirement
  bool get hasVersionRequirement => minServerpodVersion != null;

  /// Create a copy of this metadata with some fields replaced
  SkillMetadata copyWith({
    String? description,
    String? version,
    String? minServerpodVersion,
    List<String>? dependencies,
    List<String>? tags,
    SkillSource? source,
  }) {
    return SkillMetadata(
      description: description ?? this.description,
      version: version ?? this.version,
      minServerpodVersion: minServerpodVersion ?? this.minServerpodVersion,
      dependencies: dependencies ?? this.dependencies,
      tags: tags ?? this.tags,
      source: source ?? this.source,
    );
  }
}
