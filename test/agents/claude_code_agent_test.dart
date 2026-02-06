import 'dart:io';

import 'package:test/test.dart';

import 'package:serverpod_boost/agents/claude_code_agent.dart';
import 'package:serverpod_boost/serverpod/serverpod_locator.dart';

void main() {
  group('ClaudeCodeAgent', () {
    late ClaudeCodeAgent agent;
    late ServerPodProject testProject;

    setUp(() {
      agent = ClaudeCodeAgent();
      testProject = ServerPodProject(
        rootPath: '/tmp/test_project',
        serverPath: '/tmp/test_project/test_server',
        clientPath: '/tmp/test_project/test_client',
      );
    });

    test('has correct name', () {
      expect(agent.name, equals('claude-code'));
    });

    test('has correct display name', () {
      expect(agent.displayName, equals('Claude Code'));
    });

    test('has correct config path', () {
      expect(agent.configPath, equals('.mcp.json'));
    });

    test('has correct user config path when HOME is set', () {
      // This test assumes HOME environment variable is set
      final userConfigPath = agent.userConfigPath;
      expect(userConfigPath, isNotNull);
      expect(userConfigPath, contains('.claude'));
      expect(userConfigPath, contains('mcp.json'));
    });

    test('generates correct MCP config', () {
      final config = agent.generateMcpConfig(testProject);

      expect(config, containsPair('mcpServers', isNotNull));

      final mcpServers = config['mcpServers'] as Map;
      expect(mcpServers, containsPair('serverpod-boost', isNotNull));

      final serverpodBoost = mcpServers['serverpod-boost'] as Map;
      expect(serverpodBoost, containsPair('command', '${testProject.rootPath}/run-boost.sh'));
      expect(serverpodBoost, containsPair('args', isNotNull));

      final args = serverpodBoost['args'] as List;
      expect(args, isEmpty);
      expect(serverpodBoost, isNot(contains('cwd')));
      expect(serverpodBoost, isNot(contains('env')));
    });

    test('supports correct file types', () {
      expect(agent.supportedFileTypes, contains('.dart'));
      expect(agent.supportedFileTypes, contains('.yaml'));
      expect(agent.supportedFileTypes.length, equals(2));
    });

    test('has correct system detection config', () {
      final config = agent.systemDetectionConfig();
      expect(config, containsPair('command', isNotNull));
      expect(config['command'], contains('claude'));
    });

    test('has correct project detection config', () {
      final config = agent.projectDetectionConfig();
      expect(config, containsPair('paths', isNotNull));
      expect(config, containsPair('files', isNotNull));

      final files = config['files'] as List;
      expect(files, contains('.mcp.json'));
      expect(files, contains('CLAUDE.md'));
    });

    test('merges configs correctly', () {
      final existing = {
        'mcpServers': {
          'other-server': {'command': 'other'},
        },
      };

      final generated = {
        'mcpServers': {
          'serverpod-boost': {'command': '/tmp/test_project/run-boost.sh', 'args': []},
        },
      };

      final merged = agent.mergeConfig(existing, generated);

      expect(merged, containsPair('mcpServers', isNotNull));
      final mcpServers = merged['mcpServers'] as Map;
      expect(mcpServers, containsPair('other-server', isNotNull));
      expect(mcpServers, containsPair('serverpod-boost', isNotNull));
    });

    test('writes config to correct file path', () async {
      final tempDir = Directory.systemTemp.createTempSync('claude_code_agent_test_');
      try {
        final project = ServerPodProject(
          rootPath: tempDir.path,
          serverPath: '${tempDir.path}/server',
        );

        final config = agent.generateMcpConfig(project);
        await agent.writeMcpConfig(project, config);

        final configFile = File('${tempDir.path}/.mcp.json');
        expect(configFile.existsSync(), isTrue);

        final content = await configFile.readAsString();
        expect(content, contains('serverpod-boost'));
        expect(content, contains('run-boost.sh'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('merges with existing config file', () async {
      final tempDir = Directory.systemTemp.createTempSync('claude_code_agent_test_');
      try {
        final project = ServerPodProject(
          rootPath: tempDir.path,
          serverPath: '${tempDir.path}/server',
        );

        // Create existing config
        final configFile = File('${tempDir.path}/.mcp.json');
        await configFile.writeAsString('''
{
  "mcpServers": {
    "existing-server": {
      "command": "existing"
    }
  }
}
''');

        // Write new config (should merge)
        final config = agent.generateMcpConfig(project);
        await agent.writeMcpConfig(project, config);

        // Verify merge
        final content = await configFile.readAsString();
        expect(content, contains('existing-server'));
        expect(content, contains('serverpod-boost'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
