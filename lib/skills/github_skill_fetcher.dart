/// GitHub skill fetcher
///
/// Fetches skills from GitHub repositories with caching support.
library serverpod_boost.skills.github_skill_fetcher;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'skill.dart';
import 'skill_metadata.dart';
import 'skill_loader.dart';

/// Fetches skills from GitHub repositories
class GitHubSkillFetcher {

  /// Create a new GitHub skill fetcher
  GitHubSkillFetcher({
    http.Client? client,
    String? cacheDir,
    String? skillsPath,
    String? githubApiUrl,
    String? githubRawUrl,
  }) : client = client ?? http.Client(),
       cacheDir = cacheDir ?? '.ai/skills/remote',
       skillsPath = skillsPath ?? '.ai/skills',
       githubApiUrl = githubApiUrl ?? 'https://api.github.com',
       githubRawUrl = githubRawUrl ?? 'https://raw.githubusercontent.com';
  /// HTTP client for making requests
  final http.Client client;

  /// Directory for caching fetched skills
  final String cacheDir;

  /// Local skills path for fallback
  final String skillsPath;

  /// GitHub API base URL
  final String githubApiUrl;

  /// GitHub raw content base URL
  final String githubRawUrl;

  /// Fetch skill from GitHub repository
  ///
  /// [repo] Repository in format 'owner/repo'
  /// [skillName] Name of the skill to fetch
  /// [branch] Git branch to fetch from (default: 'main')
  Future<Skill> fetchSkill(
    String repo,
    String skillName, {
    String branch = 'main',
  }) async {
    final cacheKey = '$repo-$branch-$skillName';

    // Try loading from cache first
    final cached = await _loadFromCache(cacheKey);
    if (cached != null) {
      return cached;
    }

    // Fetch from GitHub
    final url = Uri.parse(
      '$githubRawUrl/$repo/$branch/.ai/skills/$skillName/SKILL.md.mustache',
    );

    final response = await client.get(url);

    if (response.statusCode != 200) {
      throw SkillLoadException(
        'Failed to fetch skill: HTTP ${response.statusCode}',
        url.toString(),
      );
    }

    final content = response.body;

    // Cache the skill content
    await _saveToCache(cacheKey, content);

    // Try to fetch metadata
    final metaUrl = Uri.parse(
      '$githubRawUrl/$repo/$branch/.ai/skills/$skillName/meta.yaml',
    );

    SkillMetadata metadata;
    try {
      final metaResponse = await client.get(metaUrl);
      if (metaResponse.statusCode == 200) {
        metadata = _parseMetadata(metaResponse.body);
      } else {
        metadata = SkillMetadata.defaults;
      }
    } catch (e) {
      metadata = SkillMetadata.defaults;
    }

    return Skill(
      name: skillName,
      description: metadata.description,
      template: content,
      metadata: metadata.copyWith(source: SkillSource.github(repo)),
    );
  }

  /// List available skills from repository
  ///
  /// [repo] Repository in format 'owner/repo'
  /// [branch] Git branch to list from (default: 'main')
  Future<List<String>> listSkills(String repo, {String branch = 'main'}) async {
    final url = Uri.parse(
      '$githubApiUrl/repos/$repo/contents/.ai/skills?ref=$branch',
    );

    final response = await client.get(url);

    if (response.statusCode != 200) {
      throw SkillLoadException(
        'Failed to list skills: HTTP ${response.statusCode}',
        url.toString(),
      );
    }

    final List<dynamic> json;
    try {
      json = jsonDecode(response.body) as List;
    } catch (e) {
      throw SkillLoadException(
        'Failed to parse GitHub API response',
        url.toString(),
      );
    }

    // Filter to only directories (skill folders)
    return json
        .where((item) => item['type'] == 'dir')
        .map((item) => item['name'] as String)
        .toList()
      ..sort();
  }

  /// Fetch multiple skills from a repository
  ///
  /// [repo] Repository in format 'owner/repo'
  /// [skillNames] List of skill names to fetch
  /// [branch] Git branch to fetch from (default: 'main')
  Future<List<Skill>> fetchSkills(
    String repo,
    List<String> skillNames, {
    String branch = 'main',
  }) async {
    final skills = <Skill>[];

    for (final skillName in skillNames) {
      try {
        final skill = await fetchSkill(repo, skillName, branch: branch);
        skills.add(skill);
      } catch (e) {
        // Continue fetching other skills even if one fails
        // TODO: Add logging
        continue;
      }
    }

    return skills;
  }

  /// Fetch all available skills from a repository
  ///
  /// [repo] Repository in format 'owner/repo'
  /// [branch] Git branch to fetch from (default: 'main')
  Future<List<Skill>> fetchAllSkills(
    String repo, {
    String branch = 'main',
  }) async {
    final skillNames = await listSkills(repo, branch: branch);
    return fetchSkills(repo, skillNames, branch: branch);
  }

  /// Check if a skill exists in the repository
  ///
  /// [repo] Repository in format 'owner/repo'
  /// [skillName] Name of the skill to check
  /// [branch] Git branch to check in (default: 'main')
  Future<bool> skillExists(
    String repo,
    String skillName, {
    String branch = 'main',
  }) async {
    final url = Uri.parse(
      '$githubRawUrl/$repo/$branch/.ai/skills/$skillName/SKILL.md.mustache',
    );

    final response = await client.head(url);
    return response.statusCode == 200;
  }

  /// Clear the cache for a specific skill
  ///
  /// [repo] Repository in format 'owner/repo'
  /// [skillName] Name of the skill to uncache
  /// [branch] Git branch (default: 'main')
  Future<void> clearCache(
    String repo,
    String skillName, {
    String branch = 'main',
  }) async {
    final cacheKey = '$repo-$branch-$skillName';
    final cacheFile = File(p.join(cacheDir, '$cacheKey.md'));

    if (await cacheFile.exists()) {
      await cacheFile.delete();
    }
  }

  /// Clear all cached skills
  Future<void> clearAllCache() async {
    final cacheDirObj = Directory(cacheDir);
    if (await cacheDirObj.exists()) {
      await cacheDirObj.delete(recursive: true);
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    final cacheDirObj = Directory(cacheDir);
    if (!await cacheDirObj.exists()) {
      return 0;
    }

    int totalSize = 0;
    await for (final entity in cacheDirObj.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// Load a skill from cache
  Future<Skill?> _loadFromCache(String key) async {
    final cacheFile = File(p.join(cacheDir, '$key.md'));
    if (!await cacheFile.exists()) {
      return null;
    }

    try {
      final content = await cacheFile.readAsString();
      return Skill(
        name: key.split('-').last,
        template: content,
        metadata: const SkillMetadata(source: SkillSource.cached()),
      );
    } catch (e) {
      // If cache is corrupted, ignore it
      return null;
    }
  }

  /// Save a skill to cache
  Future<void> _saveToCache(String key, String content) async {
    final cacheDirObj = Directory(cacheDir);
    if (!await cacheDirObj.exists()) {
      await cacheDirObj.create(recursive: true);
    }

    final cacheFile = File(p.join(cacheDir, '$key.md'));
    await cacheFile.writeAsString(content);
  }

  /// Parse metadata from YAML content
  SkillMetadata _parseMetadata(String yamlContent) {
    final lines = yamlContent.split('\n');
    final metadata = <String, dynamic>{};

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex > 0 && colonIndex < trimmed.length - 1) {
        final key = trimmed.substring(0, colonIndex).trim();
        final value = trimmed.substring(colonIndex + 1).trim();

        // Handle arrays (dependencies, tags)
        if (value.startsWith('[') && value.endsWith(']')) {
          final arrayContent = value.substring(1, value.length - 1);
          final items = arrayContent
              .split(',')
              .map((e) => e.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''))
              .where((e) => e.isNotEmpty)
              .toList();
          metadata[key] = items;
        } else {
          // Handle strings
          metadata[key] = value.replaceAll(RegExp(r'''^['"]|['"]$'''), '');
        }
      }
    }

    // Parse dependencies
    final deps = <String>[];
    if (metadata['dependencies'] is List) {
      deps.addAll((metadata['dependencies'] as List).cast<String>());
    }

    // Parse tags
    final tags = <String>[];
    if (metadata['tags'] is List) {
      tags.addAll((metadata['tags'] as List).cast<String>());
    }

    return SkillMetadata(
      description: metadata['description'] as String? ?? '',
      version: metadata['version'] as String? ?? '1.0.0',
      minServerpodVersion: metadata['minServerpodVersion'] as String?,
      dependencies: deps,
      tags: tags,
    );
  }

  /// Close the HTTP client
  void close() {
    client.close();
  }
}
