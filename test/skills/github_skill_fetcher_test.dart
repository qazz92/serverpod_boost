/// Unit tests for GitHubSkillFetcher
library serverpod_boost.test.skills.github_skill_fetcher_test;

import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:serverpod_boost/skills/skill.dart';
import 'package:serverpod_boost/skills/skill_metadata.dart';
import 'package:serverpod_boost/skills/github_skill_fetcher.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';

void main() {
  group('GitHubSkillFetcher', () {
    late GitHubSkillFetcher fetcher;
    late Directory tempDir;
    late String cacheDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('github_skill_fetcher_test_');
      cacheDir = '${tempDir.path}/cache';
      fetcher = GitHubSkillFetcher(
        cacheDir: cacheDir,
        skillsPath: tempDir.path,
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('fetchSkill()', () {
      test('handles network errors gracefully', () async {
        // Test with a non-existent repository
        try {
          await fetcher.fetchSkill('nonexistent/repo', 'skill-name');
          expect(true, isFalse); // Should not reach here
        } catch (e) {
          expect(e, isInstanceOf<SkillLoadException>());
          expect((e as SkillLoadException).message, contains('Failed to fetch skill'));
        }
      });

      test('loads from cache on second call', () async {
        // Create cache manually
        final cacheKey = 'test-repo-main-test-skill';
        final cacheFile = File('$cacheDir/$cacheKey.md');
        await Directory(cacheDir).create(recursive: true);
        await cacheFile.writeAsString('Cached template');

        // Fetch the skill - should use cache
        final skill = await fetcher.fetchSkill('test/repo', 'test-skill');
        
        expect(skill, isNotNull);
        expect(skill!.template, 'Cached template');
      });
    });

    group('listSkills()', () {
      test('handles invalid repository', () async {
        // Test with invalid repo - should throw exception but not crash
        try {
          final skills = await fetcher.listSkills('invalid/invalid');
          expect(skills, isEmpty);
        } catch (e) {
          // The implementation catches the exception and returns empty list
          expect(e, isInstanceOf<SkillLoadException>());
        }
      });
    });

    group('skillExists()', () {
      test('checks if skill exists in repository', () async {
        // Test with non-existent skill
        expect(await fetcher.skillExists('test/repo', 'nonexistent'), isFalse);
      });
    });

    group('clearCache()', () {
      test('clears cache for specific skill', () async {
        // Create cache file
        final cacheFile = File('$cacheDir/test-repo-main-skill.md');
        await cacheFile.create(recursive: true);
        await cacheFile.writeAsString('test');

        await fetcher.clearCache('test/repo', 'skill');

        expect(cacheFile.existsSync(), isFalse);
      });
    });

    group('clearAllCache()', () {
      test('clears all cache', () async {
        // Create cache directory and files
        await Directory(cacheDir).create(recursive: true);
        await File('$cacheDir/test1.md').writeAsString('test1');
        await File('$cacheDir/test2.md').writeAsString('test2');

        await fetcher.clearAllCache();

        expect(Directory(cacheDir).existsSync(), isFalse);
      });
    });

    group('getCacheSize()', () {
      test('returns cache size in bytes', () async {
        // Create cache directory
        await Directory(cacheDir).create(recursive: true);
        await File('$cacheDir/test1.md').writeAsString('test1');
        await File('$cacheDir/test2.md').writeAsString('test2');

        final size = await fetcher.getCacheSize();
        expect(size, greaterThan(0));
      });

      test('returns 0 when no cache', () async {
        // Remove cache directory if it exists
        final cacheDirObj = Directory(cacheDir);
        if (await cacheDirObj.exists()) {
          await cacheDirObj.delete(recursive: true);
        }
        
        final size = await fetcher.getCacheSize();
        expect(size, equals(0));
      });
    });
  });
}
