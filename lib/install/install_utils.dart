/// Installation utilities
///
/// Helper classes for managing installation features and options.
library serverpod_boost.install.install_utils;

/// Feature that can be installed
class InstallFeature {
  /// Feature identifier
  final String id;

  /// Display name
  final String displayName;

  /// Description
  final String description;

  /// Whether this feature is selected by default
  final bool isDefault;

  const InstallFeature({
    required this.id,
    required this.displayName,
    required this.description,
    this.isDefault = true,
  });

  /// All available install features
  static const List<InstallFeature> all = [
    InstallFeature(
      id: 'guidelines',
      displayName: 'AI Guidelines',
      description: 'Generate AGENTS.md and CLAUDE.md files',
      isDefault: true,
    ),
    InstallFeature(
      id: 'skills',
      displayName: 'Agent Skills',
      description: 'Install and configure agent skills',
      isDefault: true,
    ),
    InstallFeature(
      id: 'mcp',
      displayName: 'MCP Configuration',
      description: 'Configure MCP server for AI editors',
      isDefault: true,
    ),
  ];

  /// Find feature by ID
  static InstallFeature? findById(String id) {
    for (final feature in all) {
      if (feature.id == id) {
        return feature;
      }
    }
    return null;
  }
}

/// Installation configuration
class InstallConfig {
  /// Selected features to install
  final List<String> features;

  /// Selected skills to include
  final List<String> skills;

  /// Selected AI editors to configure
  final List<String> agents;

  /// Whether to overwrite existing files
  final bool overwrite;

  /// Path to skills directory
  final String skillsPath;

  const InstallConfig({
    this.features = const ['guidelines', 'skills', 'mcp'],
    this.skills = const [],
    this.agents = const [],
    this.overwrite = false,
    this.skillsPath = '.ai/skills',
  });

  /// Check if a feature is selected
  bool hasFeature(String featureId) {
    return features.contains(featureId);
  }

  /// Check if guidelines should be installed
  bool get installGuidelines => hasFeature('guidelines');

  /// Check if skills should be installed
  bool get installSkills => hasFeature('skills');

  /// Check if MCP should be installed
  bool get installMcp => hasFeature('mcp');

  /// Create a copy with modified fields
  InstallConfig copyWith({
    List<String>? features,
    List<String>? skills,
    List<String>? agents,
    bool? overwrite,
    String? skillsPath,
  }) {
    return InstallConfig(
      features: features ?? this.features,
      skills: skills ?? this.skills,
      agents: agents ?? this.agents,
      overwrite: overwrite ?? this.overwrite,
      skillsPath: skillsPath ?? this.skillsPath,
    );
  }
}

/// Installation result
class InstallResult {
  /// Whether installation was successful
  final bool success;

  /// List of successful installations
  final List<String> successes;

  /// List of failed installations with errors
  final Map<String, String> failures;

  /// Installation messages
  final List<String> messages;

  const InstallResult({
    this.success = true,
    this.successes = const [],
    this.failures = const {},
    this.messages = const [],
  });

  /// Create a successful result
  factory InstallResult.success([List<String> successes = const []]) {
    return InstallResult(
      success: true,
      successes: successes,
    );
  }

  /// Create a failed result
  factory InstallResult.failure(Map<String, String> failures) {
    return InstallResult(
      success: false,
      failures: failures,
    );
  }

  /// Check if there are any failures
  bool get hasFailures => failures.isNotEmpty;

  /// Get total count of installations
  int get total => successes.length + failures.length;
}
