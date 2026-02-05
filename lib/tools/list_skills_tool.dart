/// List Skills Tool
///
/// List all available AI skills for the ServerPod project.
library serverpod_boost.tools.list_skills_tool;

import 'dart:io';
import 'package:path/path.dart' as p;

import '../mcp/mcp_tool.dart';

/// Information about a single skill
class SkillInfo {
  SkillInfo({
    required this.name,
    required this.category,
    required this.description,
    required this.path,
  });

  /// Skill name (directory name)
  final String name;

  /// Category (serverpod, remote, etc.)
  final String category;

  /// Description extracted from skill file
  final String description;

  /// Path to the skill template file
  final String path;

  /// Convert to JSON-serializable map
  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'description': description,
    'path': path,
  };

  @override
  String toString() => 'SkillInfo(name: $name, category: $category)';
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

Returns a list of skills with their names, categories, descriptions, and file paths.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'category': McpSchema.string(
        description: 'Optional category filter (e.g., "serverpod", "remote")',
      ),
      'search': McpSchema.string(
        description: 'Optional search term to filter skills by name or description',
      ),
    },
  );

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final categoryFilter = params['category'] as String?;
    final searchTerm = params['search'] as String?;

    // Find the .ai/skills directory
    final skillsDir = _findSkillsDirectory();
    if (skillsDir == null) {
      return {
        'error': 'Skills directory not found',
        'message': 'Could not locate .ai/skills directory in the project',
      };
    }

    // Load all skills
    final skills = await _loadSkills(skillsDir, categoryFilter, searchTerm);

    // Group by category
    final categories = <String, List<SkillInfo>>{};
    for (final skill in skills) {
      categories.putIfAbsent(skill.category, () => []).add(skill);
    }

    return {
      'skills': skills.map((s) => s.toJson()).toList(),
      'count': skills.length,
      'categories': categories.map(
        (cat, skillList) => MapEntry(cat, skillList.length),
      ),
      'skillsDirectory': skillsDir.path,
    };
  }

  /// Find the .ai/skills directory
  Directory? _findSkillsDirectory() {
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

  /// Load all skills from the skills directory
  Future<List<SkillInfo>> _loadSkills(
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
      final categorySkills = await _loadSkillsFromCategory(entity, category);
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
    String category,
  ) async {
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
