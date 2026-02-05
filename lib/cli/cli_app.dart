/// CLI Application
///
/// Main CLI application that routes commands.
library serverpod_boost.cli.cli_app;

import 'dart:io';
import 'package:serverpod_boost/cli/command.dart';
import 'package:serverpod_boost/commands/skill_list_command.dart';
import 'package:serverpod_boost/commands/skill_show_command.dart';
import 'package:serverpod_boost/commands/skill_render_command.dart';
import 'package:serverpod_boost/commands/skill_add_command.dart';
import 'package:serverpod_boost/commands/skill_remove_command.dart';
import 'package:serverpod_boost/commands/install_command.dart';
import 'package:serverpod_boost/mcp/mcp_server.dart';
import 'package:serverpod_boost/mcp/mcp_tool.dart';
import 'package:serverpod_boost/mcp/mcp_transport.dart';
import 'package:serverpod_boost/serverpod/serverpod_locator.dart';
import 'package:serverpod_boost/tool_registry.dart';

/// CLI application for ServerPod Boost
class CLIApp {
  /// Registered commands
  final Map<String, Command Function()> _commands;

  /// Create a new CLI app
  CLIApp()
      : _commands = {
          'skill:list': () => SkillListCommand(),
          'skill:show': () => SkillShowCommand(),
          'skill:render': () => SkillRenderCommand(),
          'skill:add': () => SkillAddCommand(),
          'skill:remove': () => SkillRemoveCommand(),
          'install': () => InstallCommand(),
        };

  /// Run the CLI app
  Future<void> run(List<String> args) async {
    try {
      // Check for help flag
      if (args.contains('-h') || args.contains('--help')) {
        _showHelp();
        return;
      }

      // Extract options and find command
      final skillsPath = _extractOption(args, '--skills-path') ?? '.ai/skills';
      final commandName = _findCommandName(args);

      // Check if running as MCP server (default behavior)
      if (commandName == null) {
        await _runMCPServer(args);
        return;
      }

      // Route to command
      final commandFactory = _commands[commandName];

      if (commandFactory == null) {
        stderr.writeln('Unknown command: $commandName');
        stderr.writeln('');
        _showHelp();
        exit(1);
      }

      // Extract command-specific args
      final commandArgs = _extractCommandArgs(commandName, args);

      // Create command with args
      Command command;
      switch (commandName) {
        case 'skill:list':
          command = SkillListCommand(skillsPath: skillsPath);
          break;
        case 'skill:show':
          command = SkillShowCommand(
            skillsPath: skillsPath,
            skillName: commandArgs.isNotEmpty ? commandArgs.first : null,
          );
          break;
        case 'skill:render':
          command = SkillRenderCommand(
            skillsPath: skillsPath,
            skillName: commandArgs.isNotEmpty ? commandArgs[0] : null,
            outputPath: commandArgs.length > 1 ? commandArgs[1] : null,
          );
          break;
        case 'skill:add':
          command = SkillAddCommand(
            skillsPath: skillsPath,
            repo: commandArgs.isNotEmpty ? commandArgs[0] : null,
            skillName: commandArgs.length > 1 ? commandArgs[1] : null,
            force: args.contains('--force'),
          );
          break;
        case 'skill:remove':
          command = SkillRemoveCommand(
            skillsPath: skillsPath,
            skillName: commandArgs.isNotEmpty ? commandArgs.first : null,
            force: args.contains('--force'),
          );
          break;
        default:
          command = commandFactory();
      }

      await command.run();
    } on FormatException catch (e) {
      stderr.writeln('Error: ${e.message}');
      stderr.writeln('');
      _showHelp();
      exit(1);
    } catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    }
  }

  /// Find the command name in args (skipping options)
  String? _findCommandName(List<String> args) {
    for (final arg in args) {
      if (arg.startsWith('skill:') ||
          arg.startsWith('install') ||
          _isCommand(arg)) {
        return arg;
      }
    }
    return null;
  }

  /// Extract option value from args
  String? _extractOption(List<String> args, String option) {
    for (var i = 0; i < args.length; i++) {
      if (args[i].startsWith(option)) {
        final parts = args[i].split('=');
        if (parts.length > 1) return parts[1];
      }
    }
    return null;
  }

  /// Check if a string is a known command
  bool _isCommand(String str) {
    return _commands.containsKey(str);
  }

  /// Extract command-specific arguments
  List<String> _extractCommandArgs(String commandName, List<String> args) {
    // Remove the command name and return the rest
    if (args.isEmpty) return [];

    final firstArg = args.first;
    if (firstArg == commandName) {
      return args.skip(1).toList();
    }

    return args;
  }

  /// Run the MCP server (default mode)
  Future<void> _runMCPServer(List<String> args) async {
    final verbose = args.contains('--verbose') ||
        args.contains('-v') ||
        Platform.environment['SERVERPOD_BOOST_VERBOSE'] == 'true';

    // Detect ServerPod project
    final project = ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      _logError('Not a valid ServerPod project!', verbose);
      _logError(
          'ServerPod Boost must be run from within a ServerPod project.', verbose);
      _logError('', verbose);
      _logError('Project structure should be:', verbose);
      _logError('  monorepo_root/', verbose);
      _logError('  ├── project_server/   (required)', verbose);
      _logError('  ├── project_client/   (optional)', verbose);
      _logError('  └── project_flutter/  (optional)', verbose);
      _logError('', verbose);
      _logError(
          'Set SERVERPOD_BOOST_PROJECT_ROOT environment variable to override detection.',
          verbose);
      exit(1);
    }

    // Create server configuration with project info
    final config = MCPServerConfig(
      name: 'serverpod-boost',
      version: '0.1.0',
    );

    // Create stdio transport
    final transport = StdioTransport();

    // Create server with tool registry
    final registry = McpToolRegistry();
    BoostToolRegistry.registerAll(registry);

    final server = MCPServer(
      transport: transport,
      config: config,
      toolRegistry: registry,
    );

    // Handle shutdown signals
    ProcessSignal.sigint.watch().listen((_) async {
      await _shutdown(server, verbose);
    });

    ProcessSignal.sigterm.watch().listen((_) async {
      await _shutdown(server, verbose);
    });

    // Start the server
    _log('ServerPod Boost v${config.version}', verbose);
    _log('Project: ${project.rootPath}', verbose);
    _log('Server: ${project.serverPath}', verbose);
    _log('Tools: ${registry.count}', verbose);
    _log('', verbose);
    _log('MCP server ready, listening for requests...', verbose);

    await server.start();

    // Keep running until shutdown signal
  }

  Future<void> _shutdown(MCPServer server, bool verbose) async {
    _log('', verbose);
    _log('Shutting down ServerPod Boost...', verbose);
    await server.stop();
    exit(0);
  }

  void _log(String message, bool verbose) {
    if (verbose) {
      stderr.writeln('[INFO] $message');
    }
  }

  void _logError(String message, bool verbose) {
    if (verbose) {
      stderr.writeln('[ERROR] $message');
    } else {
      stderr.writeln(message);
    }
  }

  /// Show help message
  void _showHelp() {
    print('ServerPod Boost - AI acceleration for ServerPod development');
    print('');
    print('Usage:');
    print('  boost <command> [options]');
    print('  boost [mcp-options]        # Run as MCP server (default)');
    print('');
    print('Commands:');
    print('  install                     Install ServerPod Boost (guidelines, skills, MCP config)');
    print('  skill:list                  List all available skills');
    print('  skill:show <skill-name>     Show details of a specific skill');
    print('  skill:add <repo> [skill]    Add a skill from a GitHub repository');
    print('  skill:remove <name>         Remove a skill from local directory');
    print('  skill:render <skill-name>   Render a skill template');
    print('');
    print('Options:');
    print('  --skills-path=<path>        Path to skills directory');
    print('                              (default: .ai/skills)');
    print('  -v, --verbose               Enable verbose logging');
    print('  -h, --help                  Show this help message');
    print('');
    print('MCP Server Options:');
    print('  --verbose                   Enable verbose logging');
    print('');
    print('Examples:');
    print('  boost install                         # Install ServerPod Boost');
    print('  boost skill:list                      # List all skills');
    print('  boost skill:show create-endpoint      # Show skill details');
    print('  boost skill:add username/repo         # List skills from a GitHub repo');
    print('  boost skill:add username/repo skill   # Add a specific skill');
    print('  boost skill:remove my-skill           # Remove a skill');
    print('  boost skill:render create-endpoint    # Render skill to stdout');
    print('  boost skill:render create-endpoint output.md  # Write to file');
    print('  boost --verbose                       # Run MCP server with verbose logging');
  }
}
