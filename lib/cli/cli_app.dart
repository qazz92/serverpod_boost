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
import 'package:serverpod_boost/mcp/boost_mcp_server.dart';

/// CLI application for ServerPod Boost
class CLIApp {
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

  /// Registered commands
  final Map<String, Command Function()> _commands;

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
    // Extract options
    final verbose = args.contains('--verbose') || args.contains('-v');
    final projectPath = _extractOption(args, '--path');

    try {
      // Create and start server
      final server = await BoostMcpServer.create(
        projectPath: projectPath,
        verbose: verbose,
      );
      await server.start();

      // Handle shutdown signals
      ProcessSignal.sigint.watch().listen((_) async {
        await _shutdown(server);
      });

      ProcessSignal.sigterm.watch().listen((_) async {
        await _shutdown(server);
      });

      // Keep running until shutdown signal
      // The server.start() handles all logging and stays alive
    } on StateError catch (e) {
      _logError(e.message, verbose);
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
    } catch (e) {
      _logError('Failed to start MCP server: $e', verbose);
      exit(1);
    }
  }

  Future<void> _shutdown(BoostMcpServer server) async {
    stderr.writeln('');
    stderr.writeln('Shutting down ServerPod Boost...');
    await server.stop();
    exit(0);
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
    stderr.writeln('ServerPod Boost - AI acceleration for ServerPod development');
    stderr.writeln('');
    stderr.writeln('Usage:');
    stderr.writeln('  boost <command> [options]');
    stderr.writeln('  boost [mcp-options]        # Run as MCP server (default)');
    stderr.writeln('');
    stderr.writeln('Commands:');
    stderr.writeln('  install                     Install ServerPod Boost (guidelines, skills, MCP config)');
    stderr.writeln('  skill:list                  List all available skills');
    stderr.writeln('  skill:show <skill-name>     Show details of a specific skill');
    stderr.writeln('  skill:add <repo> [skill]    Add a skill from a GitHub repository');
    stderr.writeln('  skill:remove <name>         Remove a skill from local directory');
    stderr.writeln('  skill:render <skill-name>   Render a skill template');
    stderr.writeln('');
    stderr.writeln('Options:');
    stderr.writeln('  --skills-path=<path>        Path to skills directory');
    stderr.writeln('                              (default: .ai/skills)');
    stderr.writeln('  -v, --verbose               Enable verbose logging');
    stderr.writeln('  -h, --help                  Show this help message');
    stderr.writeln('');
    stderr.writeln('MCP Server Options:');
    stderr.writeln('  --path=<project_path>       Path to ServerPod project root');
    stderr.writeln('  --verbose                   Enable verbose logging');
    stderr.writeln('');
    stderr.writeln('Examples:');
    stderr.writeln('  boost install                         # Install ServerPod Boost');
    stderr.writeln('  boost skill:list                      # List all skills');
    stderr.writeln('  boost skill:show create-endpoint      # Show skill details');
    stderr.writeln('  boost skill:add username/repo         # List skills from a GitHub repo');
    stderr.writeln('  boost skill:add username/repo skill   # Add a specific skill');
    stderr.writeln('  boost skill:remove my-skill           # Remove a skill');
    stderr.writeln('  boost skill:render create-endpoint    # Render skill to stdout');
    stderr.writeln('  boost skill:render create-endpoint output.md  # Write to file');
    stderr.writeln('  boost --verbose                       # Run MCP server with verbose logging');
  }
}
