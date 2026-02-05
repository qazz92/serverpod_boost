/// Tests for GuidelineComposer
library serverpod_boost.test.guidelines.guideline_composer_test;

import 'package:test/test.dart';
import 'package:serverpod_boost/guidelines/guideline_composer.dart';
import 'package:serverpod_boost/guidelines/agent_type.dart';
import 'package:serverpod_boost/project_context.dart';
import 'package:serverpod_boost/skills/skill_composer.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';
import 'package:serverpod_boost/skills/skill.dart';
import 'package:serverpod_boost/skills/skill_metadata.dart';
import 'package:serverpod_boost/skills/template_renderer.dart';

void main() {
  group('GuidelineComposer', () {
    late GuidelineComposer composer;
    late ProjectContext testContext;

    setUp(() {
      // Create a test skill composer
      final loader = _TestSkillLoader();
      final renderer = const TemplateRenderer(
        context: ProjectContext(
          projectName: 'test_project',
          serverpodVersion: '3.2.3',
          rootPath: '/test/path',
        ),
      );
      final skillComposer = SkillComposer(loader: loader, renderer: renderer);
      composer = GuidelineComposer(skillComposer: skillComposer);

      // Create a test project context
      testContext = const ProjectContext(
        projectName: 'test_project',
        serverpodVersion: '3.2.3',
        rootPath: '/test/path',
        databaseType: DatabaseType.postgres,
        hasEndpoints: true,
        hasModels: true,
        hasMigrations: true,
        usesRedis: true,
        endpoints: [
          EndpointInfo(name: 'user', file: '/test/user_endpoint.dart'),
          EndpointInfo(name: 'auth', file: '/test/auth_endpoint.dart'),
        ],
        models: [
          ModelInfo(name: 'User', file: '/test/user.dart'),
          ModelInfo(name: 'Session', file: '/test/session.dart'),
        ],
        migrations: [
          MigrationInfo(name: '001_initial.sql', file: '/test/001_initial.sql'),
        ],
      );
    });

    test('composeForAgent creates guidelines for Claude Code', () async {
      final result = await composer.composeForAgent(
        AgentType.claudeCode,
        ['endpoint_basics'],
        testContext,
      );

      expect(result, contains('# Claude Code Guidelines for ServerPod'));
      expect(result, contains('test_project'));
      expect(result, contains('3.2.3'));
      expect(result, contains('## Project Context'));
    });

    test('composeForAgent creates guidelines for OpenCode', () async {
      final result = await composer.composeForAgent(
        AgentType.openCode,
        ['endpoint_basics'],
        testContext,
      );

      expect(result, contains('# OpenCode Guidelines for ServerPod'));
      expect(result, contains('test_project'));
    });

    test('composeForAgent creates guidelines for Cursor', () async {
      final result = await composer.composeForAgent(
        AgentType.cursor,
        ['endpoint_basics'],
        testContext,
      );

      expect(result, contains('# Cursor Guidelines for ServerPod'));
      expect(result, contains('## Quick Reference'));
    });

    test('composeForAgent creates guidelines for Copilot', () async {
      final result = await composer.composeForAgent(
        AgentType.copilot,
        ['endpoint_basics'],
        testContext,
      );

      expect(result, contains('# GitHub Copilot Guidelines for ServerPod'));
    });

    test('composeForAgent includes project context', () async {
      final result = await composer.composeForAgent(
        AgentType.claudeCode,
        ['endpoint_basics'],
        testContext,
      );

      expect(result, contains('### Project Structure'));
      expect(result, contains('**Endpoints:** 2'));
      expect(result, contains('**Models:** 2'));
      expect(result, contains('**Migrations:** 1'));
      expect(result, contains('### Endpoints'));
      expect(result, contains('### Models'));
      expect(result, contains('### Migrations'));
    });

    test('composeForAgent includes Redis note when applicable', () async {
      final result = await composer.composeForAgent(
        AgentType.claudeCode,
        ['endpoint_basics'],
        testContext,
      );

      expect(result, contains('uses Redis for caching'));
    });
  });

  group('AgentType', () {
    test('has correct display names', () {
      expect(AgentType.claudeCode.displayName, equals('Claude Code'));
      expect(AgentType.openCode.displayName, equals('OpenCode'));
      expect(AgentType.cursor.displayName, equals('Cursor'));
      expect(AgentType.copilot.displayName, equals('GitHub Copilot'));
    });

    test('has correct identifiers', () {
      expect(AgentType.claudeCode.identifier, equals('claude-code'));
      expect(AgentType.openCode.identifier, equals('opencode'));
      expect(AgentType.cursor.identifier, equals('cursor'));
      expect(AgentType.copilot.identifier, equals('copilot'));
    });

    test('correctly identifies streaming support', () {
      expect(AgentType.claudeCode.supportsStreaming, isTrue);
      expect(AgentType.openCode.supportsStreaming, isTrue);
      expect(AgentType.cursor.supportsStreaming, isTrue);
      expect(AgentType.copilot.supportsStreaming, isFalse);
    });

    test('correctly identifies file system access', () {
      expect(AgentType.claudeCode.hasFileSystemAccess, isTrue);
      expect(AgentType.openCode.hasFileSystemAccess, isTrue);
      expect(AgentType.cursor.hasFileSystemAccess, isTrue);
      expect(AgentType.copilot.hasFileSystemAccess, isFalse);
    });
  });

  group('GuidelineComposer static methods', () {
    test('parseAgentType parses valid agent types', () {
      expect(
        GuidelineComposer.parseAgentType('claude-code'),
        equals(AgentType.claudeCode),
      );
      expect(
        GuidelineComposer.parseAgentType('claudeCode'),
        equals(AgentType.claudeCode),
      );
      expect(
        GuidelineComposer.parseAgentType('opencode'),
        equals(AgentType.openCode),
      );
      expect(
        GuidelineComposer.parseAgentType('cursor'),
        equals(AgentType.cursor),
      );
      expect(
        GuidelineComposer.parseAgentType('copilot'),
        equals(AgentType.copilot),
      );
    });

    test('parseAgentType throws for invalid type', () {
      expect(
        () => GuidelineComposer.parseAgentType('invalid-agent'),
        throwsA(isA<InvalidAgentTypeException>()),
      );
    });

    test('getSupportedAgentTypes returns all types', () {
      final types = GuidelineComposer.getSupportedAgentTypes();
      expect(types.length, equals(4));
      expect(types, contains(AgentType.claudeCode));
      expect(types, contains(AgentType.openCode));
      expect(types, contains(AgentType.cursor));
      expect(types, contains(AgentType.copilot));
    });

    test('isAgentTypeSupported works correctly', () {
      expect(
        GuidelineComposer.isAgentTypeSupported(AgentType.claudeCode),
        isTrue,
      );
      expect(
        GuidelineComposer.isAgentTypeSupported(AgentType.openCode),
        isTrue,
      );
    });
  });
}

/// Test skill loader that returns mock skills
class _TestSkillLoader extends SkillLoader {
  _TestSkillLoader() : super(skillsPath: '/test/path');

  @override
  Future<Skill?> loadSkill(String name) async {
    return Skill(
      name: name,
      description: 'Test skill for $name',
      template: '''
# $name Skill

This is a test skill template for **$name**.

## Usage
Use this skill for $name-related tasks.
''',
      metadata: SkillMetadata(
        description: 'Test skill for $name',
        version: '1.0.0',
        tags: const ['test'],
      ),
    );
  }
}
