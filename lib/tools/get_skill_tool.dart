/// Get Skill Tool
///
/// Retrieves the content of a specific AI skill for ServerPod development.
library serverpod_boost.tools.get_skill_tool;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

/// Get Skill Tool - Retrieve skill content by name and category
class GetSkillTool extends McpToolBase {
  @override
  String get name => 'get_skill';

  @override
  String get description => '''
Get the content of a specific AI skill for ServerPod development.

Skills provide contextual guidance and templates for working with
ServerPod projects. Each skill contains:
- Template content with mustache variables
- Metadata (version, description, tags)
- Optional dependencies on other skills

Use this tool to retrieve skill content when you need specialized
knowledge about ServerPod features like authentication, endpoints,
models, migrations, etc.

Returns skill content as markdown with template variables populated
from the current project context.
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'skill_name': McpSchema.string(
        description: 'Name of the skill (e.g., "core", "endpoints", "models")',
        required: true,
      ),
      'category': McpSchema.string(
        description: 'Optional category (defaults to "serverpod"). '
            'Available categories: "serverpod", "remote"',
        required: false,
      ),
    },
    required: ['skill_name'],
  );

  @override
  String? validateParams(Map<String, dynamic>? params) {
    if (params == null) return 'Parameters are required';

    final skillName = params['skill_name'] as String?;
    if (skillName == null || skillName.isEmpty) {
      return 'skill_name is required and cannot be empty';
    }

    return null;
  }

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final skillName = params['skill_name'] as String;
    final category = params['category'] as String? ?? 'serverpod';

    // Get project to locate skills directory
    final project = ServerPodLocator.getProject();

    // Try to find the skill file
    final skillFile = await _findSkillFile(
      skillName,
      category,
      project?.rootPath,
    );

    if (skillFile == null) {
      return {
        'error': 'Skill not found',
        'message': 'Could not find skill "$skillName" in category "$category". '
            'Available skills can be listed using the list_skills tool.',
        'skill_name': skillName,
        'category': category,
      };
    }

    // Read skill content
    final content = await skillFile.readAsString();

    // Load metadata if available
    final metadata = await _loadMetadata(skillFile);

    // Extract template variables from the project context
    final templateVars = await _extractTemplateVars(project);

    return {
      'name': skillName,
      'category': category,
      'content': content,
      'metadata': metadata,
      'template_vars': templateVars,
      'path': skillFile.path,
    };
  }

  /// Find the skill file in various possible locations
  Future<File?> _findSkillFile(
    String skillName,
    String category,
    String? projectRoot,
  ) async {
    // Build list of possible paths to search
    final possiblePaths = <String>[];

    if (projectRoot != null) {
      // Project-local skills directory
      possiblePaths.addAll([
        p.join(projectRoot, '.ai', 'skills', category, skillName, 'SKILL.md.mustache'),
        p.join(projectRoot, 'skills', category, skillName, 'SKILL.md.mustache'),
      ]);
    }

    // Global skills directories (check relative to this package)
    final packageRoot = _getPackageRoot();
    if (packageRoot != null) {
      possiblePaths.addAll([
        p.join(packageRoot, '.ai', 'skills', category, skillName, 'SKILL.md.mustache'),
        p.join(packageRoot, 'test', 'skills', category, skillName, 'SKILL.md.mustache'),
      ]);
    }

    // Check each path
    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        return file;
      }
    }

    return null;
  }

  /// Load metadata from meta.yaml if it exists
  Future<Map<String, dynamic>> _loadMetadata(File skillFile) async {
    final dir = p.dirname(skillFile.path);
    final metaFile = File(p.join(dir, 'meta.yaml'));

    if (!await metaFile.exists()) {
      return {
        'version': '1.0.0',
        'tags': [],
      };
    }

    try {
      final yamlContent = await metaFile.readAsString();
      final yaml = loadYaml(yamlContent) as Map?;

      if (yaml == null) {
        return {'version': '1.0.0', 'tags': []};
      }

      return {
        'name': yaml['name'] as String? ?? '',
        'description': yaml['description'] as String? ?? '',
        'version': yaml['version'] as String? ?? '1.0.0',
        'tags': yaml['tags'] as List<dynamic>? ?? [],
      };
    } catch (e) {
      // Return default metadata on error
      return {
        'version': '1.0.0',
        'tags': [],
        'error': 'Failed to load metadata: $e',
      };
    }
  }

  /// Extract template variables from project context
  Future<Map<String, dynamic>> _extractTemplateVars(ServerPodProject? project) async {
    if (project == null || !project.isValid) {
      return {
        'project_name': 'serverpod_project',
        'serverpod_version': 'latest',
      };
    }

    // Get ServerPod version
    final serverPath = project.serverPath;
    if (serverPath == null) {
      return {
        'project_name': p.basename(project.rootPath).replaceAll('_server', ''),
        'serverpod_version': 'latest',
      };
    }

    final serverpodVersion = await _getServerpodVersion(serverPath);

    return {
      'project_name': p.basename(project.rootPath).replaceAll('_server', ''),
      'serverpod_version': serverpodVersion,
      'has_endpoints': project.endpointFiles.isNotEmpty,
      'endpoint_count': project.endpointFiles.length,
      'has_migrations': project.migrationsPath != null,
      'uses_postgres': await _usesPostgres(project),
      'uses_sqlite': await _usesSQLite(project),
    };
  }

  /// Get ServerPod version from pubspec.yaml
  Future<String> _getServerpodVersion(String serverPath) async {
    final pubspec = File(p.join(serverPath, 'pubspec.yaml'));
    if (await pubspec.exists()) {
      final content = await pubspec.readAsString();
      final match = RegExp(r'serverpod:\s*\^?([\d.]+)').firstMatch(content);
      return match?.group(1) ?? 'latest';
    }
    return 'latest';
  }

  /// Check if project uses PostgreSQL
  Future<bool> _usesPostgres(ServerPodProject project) async {
    final configFile = project.getConfigFile('development');
    if (configFile == null) return false;

    try {
      final content = await configFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;
      final db = yaml?['database'] as YamlMap?;
      return db?['host'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if project uses SQLite
  Future<bool> _usesSQLite(ServerPodProject project) async {
    final configFile = project.getConfigFile('development');
    if (configFile == null) return false;

    try {
      final content = await configFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;
      final db = yaml?['database'] as YamlMap?;
      return db?['host'] == null && db?['name'] != null;
    } catch (e) {
      return false;
    }
  }

  /// Get the package root directory
  String? _getPackageRoot() {
    try {
      // Get the current working directory
      final cwd = Directory.current.path;

      // If we're in the project, use it
      if (File(p.join(cwd, 'pubspec.yaml')).existsSync()) {
        return cwd;
      }

      // Try parent directory
      final parent = p.dirname(cwd);
      if (File(p.join(parent, 'pubspec.yaml')).existsSync()) {
        return parent;
      }

      return cwd;
    } catch (e) {
      return null;
    }
  }
}
