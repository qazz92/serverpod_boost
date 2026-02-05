/// Tool Registry - Manual registration approach
///
/// BLOCKER 2 RESOLUTION: Manual tool registration map instead of
/// dynamic discovery. This provides:
/// - Type-safe compile-time checking
/// - Explicit tool visibility
/// - No reflection/magic required
/// - Simple and reliable
library serverpod_boost.tool_registry;

import 'mcp/mcp_tool.dart';
import 'tools/tools.dart';

/// Tool Registry - Manual registration approach
///
/// BLOCKER 2 RESOLUTION: Manual tool registration map instead of
/// dynamic discovery. This provides:
/// - Type-safe compile-time checking
/// - Explicit tool visibility
/// - No reflection/magic required
/// - Simple and reliable
class BoostToolRegistry {
  /// Manually registered tools map (BLOCKER 2 RESOLUTION)
  static final Map<String, McpTool> _tools = {
    // Essential Tools (Tier 1)
    'application_info': ApplicationInfoTool(),
    'list_endpoints': ListEndpointsTool(),
    'endpoint_methods': EndpointMethodsTool(),
    'list_models': ListModelsTool(),
    'model_inspector': ModelInspectorTool(),
    'config_reader': ConfigReaderTool(),
    'database_schema': DatabaseSchemaTool(),
    'migration_scanner': MigrationScannerTool(),

    // Enhanced Tools (Tier 2)
    'project_structure': ProjectStructureTool(),
    'find_files': FindFilesTool(),
    'read_file': ReadFileTool(),
    'search_code': SearchCodeTool(),
    'call_endpoint': CallEndpointTool(),
    'service_config': ServiceConfigTool(),
  };

  /// Get tool by name
  static McpTool? getTool(String name) => _tools[name];

  /// Get all tools
  static List<McpTool> allTools() => _tools.values.toList();

  /// Check if tool is allowed
  static bool isToolAllowed(String toolName) => _tools.containsKey(toolName);

  /// Get tool metadata for MCP tools/list
  static List<Map<String, dynamic>> getToolsMetadata() {
    return _tools.entries.map((entry) {
      final tool = entry.value;
      return {
        'name': tool.name,
        'description': tool.description,
        'inputSchema': tool.inputSchema,
      };
    }).toList();
  }

  /// Register all tools with the given registry
  static void registerAll(McpToolRegistry registry) {
    for (final tool in _tools.values) {
      registry.register(tool);
    }
  }
}
