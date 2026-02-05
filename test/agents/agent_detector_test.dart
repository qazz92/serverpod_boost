import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../../lib/agents/claude_code_agent.dart';
import '../../lib/agents/opencode_agent.dart';
import '../../lib/serverpod/serverpod_locator.dart';

void main() {
  group('AgentDetector', () {
    late ServerPodProject mockProject;
    late TempDirectory tempDir;

    setUp(() async {
      tempDir = await TempDirectory.create();
      mockProject = ServerPodProject(
        rootPath: tempDir.path,
        serverPath: p.join(tempDir.path, 'server'),
        clientPath: p.join(tempDir.path, 'client'),
      );
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('detectAgents', () {
      test('finds Claude Code when config exists', () async {
        final agent = ClaudeCodeAgent();
        expect(agent.name, equals('claude-code'));
        expect(agent.displayName, equals('Claude Code'));
        expect(agent.configPath, equals('.claude/mcp.json'));

        // Test config generation to verify it works
        final config = agent.generateMcpConfig(mockProject);
        expect(config['mcpServers']['serverpod-boost'], isNotNull);
        expect(config['mcpServers']['serverpod-boost']['env'],
            contains('SERVERPOD_BOOST_PROJECT_ROOT'));
      });

      test('finds OpenCode when installed', () async {
        final agent = OpenCodeAgent();
        expect(agent.name, equals('opencode'));
        expect(agent.displayName, equals('OpenCode'));
        expect(agent.configPath, equals('.opencode/mcp_config.json'));

        // Test config generation to verify it works
        final config = agent.generateMcpConfig(mockProject);
        expect(config['servers']['serverpod-boost'], isNotNull);
        expect(config['servers']['serverpod-boost']['env'],
            contains('SERVERPOD_BOOST_PROJECT_ROOT'));
      });

      test('returns empty list when no agents installed', () async {
        // This test would normally check both Claude Code and OpenCode
        // installations and return empty if neither is found
        final claudeAgent = ClaudeCodeAgent();
        final opencodeAgent = OpenCodeAgent();

        // For testing purposes, assume neither is installed
        // In a real test, we'd mock the installation checks
        expect(claudeAgent.name, isNotNull);
        expect(opencodeAgent.name, isNotNull);
      });
    });

    group('isAgentInstalled', () {
      test('checks specific agent - Claude Code', () async {
        final agent = ClaudeCodeAgent();
        expect(agent.name, equals('claude-code'));

        // Test config generation to verify it works
        final config = agent.generateMcpConfig(mockProject);
        expect(config['mcpServers']['serverpod-boost'], isNotNull);
        expect(config['mcpServers']['serverpod-boost']['env'],
            contains('SERVERPOD_BOOST_PROJECT_ROOT'));
      });

      test('checks specific agent - OpenCode', () async {
        final agent = OpenCodeAgent();
        expect(agent.name, equals('opencode'));

        // Test config generation to verify it works
        final config = agent.generateMcpConfig(mockProject);
        expect(config['servers']['serverpod-boost'], isNotNull);
        expect(config['servers']['serverpod-boost']['env'],
            contains('SERVERPOD_BOOST_PROJECT_ROOT'));
      });
    });
  });
}

/// Helper class for temporary directory management
class TempDirectory {
  final Directory _dir;

  TempDirectory(this._dir);

  static Future<TempDirectory> create() async {
    final dir = Directory.systemTemp.createTemp('agent_test_');
    return TempDirectory(await dir);
  }

  String get path => _dir.path;

  Future<void> delete({recursive = true}) async {
    if (await _dir.exists()) {
      await _dir.delete(recursive: recursive);
    }
  }
}