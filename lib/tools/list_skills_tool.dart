/// List Skills Tool
///
/// List all available AI skills for the ServerPod project.
/// Includes both built-in skills from serverpod_boost package
/// and custom skills from the user's project.
library serverpod_boost.tools.list_skills_tool;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:package_config/package_config.dart';

import '../mcp/mcp_tool.dart';

/// Information about a single skill
class SkillInfo {
  SkillInfo({
    required this.name,
    required this.category,
    required this.description,
    required this.path,
    this.isBuiltIn = false,
  });

  /// Skill name (directory name)
  final String name;

  /// Category (serverpod, remote, etc.)
  final String category;

  /// Description extracted from skill file
  final String description;

  /// Path to the skill template file
  final String path;

  /// Whether this is a built-in skill from serverpod_boost
  final bool isBuiltIn;

  /// Convert to JSON-serializable map
  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'description': description,
    'path': path,
    'isBuiltIn': isBuiltIn,
  };

  @override
  String toString() => 'SkillInfo(name: $name, category: $category, builtIn: $isBuiltIn)';
}

/// Tool for listing all available skills in the project
class ListSkillsTool extends McpToolBase {
  @override
  String get name => 'list_skills';

  @override
  String get description => '''
List all available AI skills for this ServerPod project.

Skills are reusable AI prompts/templates that guide LLMs in performing
specific development tasks. Each skill contains domain knowledge and
best practices for ServerPod development.

Includes both:
- Built-in skills from serverpod_boost package (authentication, core, endpoints, models, etc.)
- Custom skills from your project's .ai/skills/ directory

Returns a list of skills with their names, categories, descriptions, and file paths.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'category': McpSchema.string(
        description: 'Optional category filter (e.g., "authentication", "core", "endpoints")',
      ),
      'search': McpSchema.string(
        description: 'Optional search term to filter skills by name or description',
      ),
      'source': McpSchema.enumProperty(
        values: ['all', 'built-in', 'custom'],
        description: 'Filter by skill source (default: all)',
        defaultValue: 'all',
      ),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final categoryFilter = params['category'] as String?;
    final searchTerm = params['search'] as String?;
    final sourceFilter = params['source'] as String? ?? 'all';

    // Load built-in skills from serverpod_boost package
    final builtInSkillsPath = await _findBoostSkillsPath();
    final builtInSkills = builtInSkillsPath != null
        ? await _loadBuiltInSkills(Directory(builtInSkillsPath), categoryFilter, searchTerm)
        : <SkillInfo>[];

    // Load user's custom skills from .ai/skills directory
    final userSkillsDir = _findUserSkillsDirectory();
    final userSkills = userSkillsDir != null
        ? await _loadUserSkills(userSkillsDir, categoryFilter, searchTerm)
        : <SkillInfo>[];

    // Apply source filter
    List<SkillInfo> allSkills;
    switch (sourceFilter) {
      case 'built-in':
        allSkills = builtInSkills;
        break;
      case 'custom':
        allSkills = userSkills;
        break;
      default: // 'all'
        // Merge built-in and custom, built-in first
        allSkills = [...builtInSkills, ...userSkills];
    }

    // Group by category
    final categories = <String, int>{};
    for (final skill in allSkills) {
      categories[skill.category] = (categories[skill.category] ?? 0) + 1;
    }

    return {
      'skills': allSkills.map((s) => s.toJson()).toList(),
      'count': allSkills.length,
      'builtInCount': builtInSkills.length,
      'userCount': userSkills.length,
      'categories': categories,
      if (builtInSkillsPath != null) 'builtInSkillsPath': builtInSkillsPath,
      if (userSkillsDir != null) 'userSkillsPath': userSkillsDir.path,
    };
  }

  /// Find the serverpod_boost package skills directory
  /// Supports both local development and published packages
  Future<String?> _findBoostSkillsPath() async {
    // Strategy 1: Use package_config to find lib/resources/skills
    try {
      final packageConfig = await findPackageConfig(Directory.current);
      if (packageConfig != null) {
        final boostPackage = packageConfig['serverpod_boost'];
        if (boostPackage != null) {
          final packageRoot = boostPackage.root.path;
          final resourcesPath = p.join(packageRoot, 'lib', 'resources', 'skills');
          if (await Directory(resourcesPath).exists()) {
            return resourcesPath;
          }
        }
      }
    } catch (e) {
      // Ignore and try next strategy
    }

    // Strategy 2: Try local development path (when working on boost itself)
    try {
      final currentScript = File.fromUri(Platform.script);
      final boostPackageRoot = currentScript.parent.parent.path;
      final localPath = p.join(boostPackageRoot, '.ai', 'skills');
      if (await Directory(localPath).exists()) {
        return localPath;
      }
    } catch (e) {
      // Ignore
    }

    // Strategy 3: Try resolving from current package (for published packages)
    try {
      final currentScript = File.fromUri(Platform.script);
      final binDir = currentScript.parent;
      final packageRoot = binDir.parent;
      final resourcesPath = p.join(packageRoot.path, 'lib', 'resources', 'skills');
      if (await Directory(resourcesPath).exists()) {
        return resourcesPath;
      }
    } catch (e) {
      // Ignore
    }

    return null;
  }

  /// Find the user's .ai/skills directory
  Directory? _findUserSkillsDirectory() {
    // Start from current working directory and search up
    var current = Directory.current;

    // Search up to 5 levels
    for (var i = 0; i < 5; i++) {
      final aiDir = Directory(p.join(current.path, '.ai'));
      if (aiDir.existsSync()) {
        final skillsDir = Directory(p.join(aiDir.path, 'skills'));
        if (skillsDir.existsSync()) {
          return skillsDir;
        }
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        // Reached root
        break;
      }
      current = parent;
    }

    return null;
  }

  /// Load built-in skills from serverpod_boost package
  Future<List<SkillInfo>> _loadBuiltInSkills(
    Directory skillsDir,
    String? categoryFilter,
    String? searchTerm,
  ) async {
    final skills = <SkillInfo>[];

    if (!await skillsDir.exists()) {
      return skills;
    }

    // Iterate through category directories
    for (final entity in skillsDir.listSync()) {
      if (entity is! Directory) continue;

      final category = p.basename(entity.path);

      // Apply category filter
      if (categoryFilter != null &&
          category.toLowerCase() != categoryFilter.toLowerCase()) {
        continue;
      }

      // Load skills from this category
      final categorySkills = await _loadSkillsFromCategory(
        entity,
        category,
        isBuiltIn: true,
      );
      skills.addAll(categorySkills);
    }

    // Apply search filter
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final lowerSearch = searchTerm.toLowerCase();
      return skills.where((skill) =>
        skill.name.toLowerCase().contains(lowerSearch) ||
        skill.description.toLowerCase().contains(lowerSearch)
      ).toList();
    }

    return skills;
  }

  /// Load user's custom skills from .ai/skills directory
  Future<List<SkillInfo>> _loadUserSkills(
    Directory skillsDir,
    String? categoryFilter,
    String? searchTerm,
  ) async {
    final skills = <SkillInfo>[];

    // Iterate through category directories
    for (final entity in skillsDir.listSync()) {
      if (entity is! Directory) continue;

      final category = p.basename(entity.path);

      // Apply category filter
      if (categoryFilter != null &&
          category.toLowerCase() != categoryFilter.toLowerCase()) {
        continue;
      }

      // Load skills from this category
      final categorySkills = await _loadSkillsFromCategory(
        entity,
        category,
        isBuiltIn: false,
      );
      skills.addAll(categorySkills);
    }

    // Apply search filter
    if (searchTerm != null && searchTerm.isNotEmpty) {
      final lowerSearch = searchTerm.toLowerCase();
      return skills.where((skill) =>
        skill.name.toLowerCase().contains(lowerSearch) ||
        skill.description.toLowerCase().contains(lowerSearch)
      ).toList();
    }

    return skills;
  }

  /// Load skills from a specific category directory
  Future<List<SkillInfo>> _loadSkillsFromCategory(
    Directory categoryDir,
    String category, {
    required bool isBuiltIn,
  }) async {
    final skills = <SkillInfo>[];

    for (final entity in categoryDir.listSync()) {
      if (entity is! Directory) continue;

      final skillName = p.basename(entity.path);

      // Look for SKILL.md.mustache file
      final skillFile = File(p.join(entity.path, 'SKILL.md.mustache'));
      if (!skillFile.existsSync()) {
        // Try lowercase variant
        final altFile = File(p.join(entity.path, 'skill.md.mustache'));
        if (!altFile.existsSync()) {
          continue;
        }
      }

      // Extract description from skill file
      final description = await _extractDescription(skillFile.existsSync()
          ? skillFile
          : File(p.join(entity.path, 'skill.md.mustache')));

      skills.add(SkillInfo(
        name: skillName,
        category: category,
        description: description,
        path: skillFile.existsSync() ? skillFile.path : p.join(entity.path, 'skill.md.mustache'),
        isBuiltIn: isBuiltIn,
      ));
    }

    return skills;
  }

  /// Extract a brief description from the skill file
  Future<String> _extractDescription(File skillFile) async {
    try {
      final content = await skillFile.readAsString();

      // Try to extract the first heading or paragraph
      final lines = content.split('\n');

      for (final line in lines) {
        final trimmed = line.trim();

        // Skip empty lines
        if (trimmed.isEmpty) continue;

        // Skip heading markers
        if (trimmed.startsWith('#')) {
          continue;
        }

        // Return first meaningful paragraph (max 200 chars)
        if (trimmed.length > 20) {
          return trimmed.length > 200
              ? '${trimmed.substring(0, 197)}...'
              : trimmed;
        }
      }

      // Fallback to first non-empty line
      for (final line in lines) {
        if (line.trim().isNotEmpty) {
          return line.trim().replaceAll(RegExp(r'^#+\s*'), '');
        }
      }
    } catch (e) {
      // If reading fails, return a generic description
    }

    return 'No description available';
  }
}
