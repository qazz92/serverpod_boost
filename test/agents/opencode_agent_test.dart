import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import '../../lib/agents/opencode_agent.dart';
import '../../lib/serverpod/serverpod_locator.dart';

void main() {
  group('OpenCodeAgent', () {
    late ServerPodProject mockProject;
    late TempDirectory tempDir;
    late OpenCodeAgent agent;

    setUp(() async {
      tempDir = await TempDirectory.create();
      mockProject = ServerPodProject(
        rootPath: tempDir.path,
        serverPath: p.join(tempDir.path, 'server'),
        clientPath: p.join(tempDir.path, 'client'),
      );

      agent = OpenCodeAgent();
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('generateMcpConfig', () {
      test('creates valid MCP config', () {
        final config = agent.generateMcpConfig(mockProject);

        expect(config, isA<Map<String, dynamic>>());
        expect(config['servers'], isA<Map<String, dynamic>>());
        expect(config['servers']['serverpod-boost'], isA<Map<String, dynamic>>());
      });

      test('includes correct command and args', () {
        final config = agent.generateMcpConfig(mockProject);
        final server = config['servers']['serverpod-boost'];

        expect(server['command'], equals('dart'));
        expect(server['args'], equals(['run', 'serverpod_boost:boost']));
      });

      test('includes environment variables', () {
        final config = agent.generateMcpConfig(mockProject);
        final server = config['servers']['serverpod-boost'];

        expect(server['env']['SERVERPOD_BOOST_PROJECT_ROOT'],
            equals(mockProject.rootPath));
      });

      test('includes current working directory', () {
        final config = agent.generateMcpConfig(mockProject);
        final server = config['servers']['serverpod-boost'];

        expect(server['cwd'], equals(mockProject.rootPath));
      });
    });

    group('writeMcpConfig', () {
      test('creates new config file', () async {
        final config = agent.generateMcpConfig(mockProject);

        // Write the config
        await agent.writeMcpConfig(mockProject, config);

        // Verify file was created
        final configFile = File(p.join(mockProject.rootPath, '.opencode', 'mcp_config.json'));
        expect(await configFile.exists(), isTrue);

        final content = await configFile.readAsString();
        expect(content, contains('serverpod-boost'));
        expect(content, contains('dart'));
      });

      test('merges with existing config', () async {
        final existingConfig = {
          'servers': {
            'other-server': {
              'command': 'other',
              'args': ['arg1'],
            }
          }
        };

        final newConfig = {
          'servers': {
            'serverpod-boost': {
              'command': 'dart',
              'args': ['run', 'serverpod_boost:boost'],
            }
          }
        };

        // Create existing config
        final configDir = Directory(p.join(mockProject.rootPath, '.opencode'));
        await configDir.create(recursive: true);
        final configFile = File(p.join(mockProject.rootPath, '.opencode', 'mcp_config.json'));
        await configFile.writeAsString(jsonEncode(existingConfig));

        // Write new config (should merge)
        await agent.writeMcpConfig(mockProject, newConfig);

        // Verify merge
        final content = await configFile.readAsString();
        expect(content, contains('other-server'));
        expect(content, contains('serverpod-boost'));
      });
    });

    group('mergeConfig', () {
      test('merges existing and new configs', () {
        final existing = {
          'servers': {
            'server1': {'command': 'cmd1'},
          },
          'otherField': 'value',
        };

        final generated = {
          'servers': {
            'server2': {'command': 'cmd2'},
          },
        };

        final merged = agent.mergeConfig(existing, generated);

        expect(merged['servers']['server1'], equals({'command': 'cmd1'}));
        expect(merged['servers']['server2'], equals({'command': 'cmd2'}));
        expect(merged['otherField'], equals('value'));
      });

      test('handles null existing config', () {
        final generated = {
          'servers': {
            'server1': {'command': 'cmd1'},
          },
        };

        final merged = agent.mergeConfig({}, generated);

        expect(merged['servers']['server1'], equals({'command': 'cmd1'}));
      });

      test('handles null generated config', () {
        final existing = {
          'servers': {
            'server1': {'command': 'cmd1'},
          },
        };

        final merged = agent.mergeConfig(existing, {});

        expect(merged['servers']['server1'], equals({'command': 'cmd1'}));
      });

      test('uses servers key not mcpServers', () {
        final existing = {
          'servers': {
            'existing': {'command': 'cmd'},
          },
        };

        final generated = {
          'servers': {
            'new': {'command': 'newcmd'},
          },
        };

        final merged = agent.mergeConfig(existing, generated);

        expect(merged, isNot(contains('mcpServers')));
        expect(merged['servers'], hasLength(2));
      });
    });

    group('isInstalled', () {
      test('returns Future<bool> for installation check', () async {
        // Test that the method returns a Future<bool>
        final result = await agent.isInstalled();
        expect(result, isA<bool>());
      });
    });

    group('displayName', () {
      test('returns correct name', () {
        expect(agent.displayName, equals('OpenCode'));
      });
    });

    group('configPath', () {
      test('returns correct path', () {
        expect(agent.configPath, equals('.opencode/mcp_config.json'));
      });
    });

    group('userConfigPath', () {
      test('returns null for OpenCode', () {
        expect(agent.userConfigPath, isNull);
      });
    });

    group('supportedFileTypes', () {
      test('returns correct file types', () {
        expect(agent.supportedFileTypes, equals(['.dart', '.yaml']));
      });
    });
  });
}

/// Helper class for temporary directory management
class TempDirectory {
  final Directory _dir;

  TempDirectory(this._dir);

  static Future<TempDirectory> create() async {
    final dir = Directory.systemTemp.createTemp('opencode_agent_test_');
    return TempDirectory(await dir);
  }

  String get path => _dir.path;

  Future<void> delete({recursive = true}) async {
    if (await _dir.exists()) {
      await _dir.delete(recursive: recursive);
    }
  }
}