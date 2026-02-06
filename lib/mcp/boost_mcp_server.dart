import 'dart:io';
import 'package:mcp_server/mcp_server.dart';
import 'package:serverpod_boost/serverpod/serverpod_locator.dart';
import 'package:serverpod_boost/tool_registry.dart';
import 'package:serverpod_boost/mcp/mcp_tool_adapter.dart';

/// Boost MCP Server - wrapper around package:mcp_server
class BoostMcpServer {
  /// Private constructor
  BoostMcpServer._({
    required Server server,
    required ServerPodProject project,
    required bool verbose,
  })  : _server = server,
        _project = project,
        _verbose = verbose;

  final Server _server;
  final ServerPodProject _project;
  final bool _verbose;

  /// Create and configure the server
  static Future<BoostMcpServer> create({
    String? projectPath,
    bool verbose = false,
  }) async {
    // Set project root from argument if provided
    if (projectPath != null && projectPath.isNotEmpty) {
      // Temporarily set environment variable for detection
      // Note: This won't modify Platform.environment directly
      // Instead, we'll pass it to ServerPodLocator
    }

    // Detect ServerPod project
    final project = projectPath != null && projectPath.isNotEmpty
        ? ServerPodLocator.getProject(currentPath: projectPath)
        : ServerPodLocator.getProject();

    if (project == null || !project.isValid) {
      throw StateError('Not a valid ServerPod project');
    }

    // Create server with name, version, and capabilities
    final server = Server(
      name: 'serverpod-boost',
      version: '0.1.0',
      capabilities: ServerCapabilities.simple(
        tools: true,
        resources: false,
        prompts: false,
      ),
    );

    // Register all tools via adapter
    for (final tool in BoostToolRegistry.allTools()) {
      adaptMcpToolToServer(tool, server);
    }

    return BoostMcpServer._(
      server: server,
      project: project,
      verbose: verbose,
    );
  }

  /// Start the server
  Future<void> start() async {
    if (_verbose) {
      stderr.writeln('[INFO] ServerPod Boost starting...');
      stderr.writeln('[INFO] Project: ${_project.rootPath}');
      stderr.writeln('[INFO] Server: ${_project.serverPath}');
      stderr.writeln('[INFO] Tools: ${BoostToolRegistry.allTools().length}');
    }

    // Create stdio transport and connect
    final transportResult = McpServer.createTransport(
      const TransportConfig.stdio(),
    );

    // Get the transport future or throw error
    final transportFuture = transportResult.get();
    final transport = await transportFuture;

    _server.connect(transport);

    if (_verbose) {
      stderr.writeln('[INFO] MCP server ready');
    }
  }

  /// Stop the server
  Future<void> stop() async {
    _server.dispose();
  }
}
