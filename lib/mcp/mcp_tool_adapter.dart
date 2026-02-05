import 'dart:convert';
import 'package:mcp_server/mcp_server.dart';
import 'package:serverpod_boost/mcp/mcp_tool.dart';
// ignore: deprecated_member_use_from_same_package
import 'package:serverpod_boost/mcp/mcp_protocol.dart';

/// Adapter to add McpTool to mcp_server Server
void adaptMcpToolToServer(McpTool boostTool, Server server) {
  server.addTool(
    name: boostTool.name,
    description: boostTool.description,
    inputSchema: boostTool.inputSchema,
    handler: (params) async {
      try {
        // Create request from params
        final request = McpRequest.call(
          boostTool.name,
          params: params,
        );

        // Execute using existing tool logic
        final response = await boostTool.execute(request);

        // Convert response to CallToolResult
        if (response.isError) {
          return CallToolResult(
            content: [
              TextContent(
                text: response.error?.message ?? 'Unknown error',
              ),
            ],
            isError: true,
          );
        }

        // Return text content with result
        return CallToolResult(
          content: [
            TextContent(
              text: _formatResult(response.result),
            ),
          ],
        );
      } catch (e) {
        return CallToolResult(
          content: [
            TextContent(
              text: e.toString(),
            ),
          ],
          isError: true,
        );
      }
    },
  );
}

String _formatResult(dynamic result) {
  if (result == null) return '';
  if (result is String) return result;
  if (result is Map || result is List) {
    return const JsonEncoder.withIndent('  ').convert(result);
  }
  return result.toString();
}

/// Adapter to convert McpTool to mcp_server Tool format (for metadata only)
Tool adaptMcpTool(McpTool boostTool) {
  return Tool(
    name: boostTool.name,
    description: boostTool.description,
    inputSchema: boostTool.inputSchema,
  );
}
