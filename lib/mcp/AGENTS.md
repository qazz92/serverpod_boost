<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# mcp

## Purpose

MCP (Model Context Protocol) server implementation using package:mcp_server v1.0.3. Handles JSON-RPC 2.0 communication over stdio, tool registration, and request/response routing.

## Key Files

| File | Description |
|------|-------------|
| `mcp_server.dart` | Main MCP server - handles initialize, tools/call, shutdown |
| `mcp_tool_adapter.dart` | Adapts Boost tools to MCP tool format |
| `mcp_transport.dart` | STDIO transport layer |

## For AI Agents

### Working In This Directory

- MCP protocol compliance is critical
- All tools must be registered via `mcp_tool_adapter.dart`
- Uses package:mcp_server - not custom implementation
- JSON-RPC 2.0 over stdio

### MCP Methods

- `initialize` - Protocol handshake
- `tools/list` - List available tools
- `tools/call` - Execute a tool
- `resources/list` - List resources (future)
- `prompts/list` - List prompts (future)

## Dependencies

### External

- `mcp_server: ^1.0.3` - Official MCP package

<!-- MANUAL: -->
