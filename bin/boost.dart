/// ServerPod Boost - Main entry point
///
/// This is the main entry point for the ServerPod Boost CLI and MCP server.
///
/// Usage:
/// ```bash
/// # Run as MCP server (default)
/// dart run serverpod_boost:boost
/// dart run serverpod_boost:boost --verbose
///
/// # Run CLI commands
/// dart run serverpod_boost:boost skill:list
/// dart run serverpod_boost:boost skill:show <skill-name>
/// dart run serverpod_boost:boost skill:render <skill-name>
/// ```
library serverpod_boost.bin;

import 'package:serverpod_boost/cli/cli_app.dart';

/// Main entry point for the Boost CLI and MCP server
Future<void> main(List<String> args) async {
  final app = CLIApp();
  await app.run(args);
}
