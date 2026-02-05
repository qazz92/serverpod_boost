<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# lib

## Purpose

Main source code directory for ServerPod Boost. Contains all Dart modules organized by responsibility: MCP server implementation, 20 analysis tools, CLI commands, ServerPod integration, skills system, and file provisioning.

## Key Files

| File | Description |
|------|-------------|
| `boost.dart` | Main library export file |
| `tool_registry.dart` | Central registry for all 20 MCP tools |
| `shared/logger.dart` | Colored logging utility |
| `shared/models.dart` | Shared data models |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `mcp/` | MCP server implementation (see `lib/mcp/AGENTS.md`) |
| `tools/` | 20 MCP tools for ServerPod analysis (see `lib/tools/AGENTS.md`) |
| `cli/` | CLI infrastructure (see `lib/cli/AGENTS.md`) |
| `commands/` | CLI command handlers (see `lib/commands/AGENTS.md`) |
| `serverpod/` | ServerPod project detection (see `lib/serverpod/AGENTS.md`) |
| `skills/` | Skills system framework (see `lib/skills/AGENTS.md`) |
| `agents/` | AI agent utilities (see `lib/agents/AGENTS.md`) |
| `install/` | File provisioning system (see `lib/install/AGENTS.md`) |
| `guidelines/` | Documentation templates (see `lib/guidelines/AGENTS.md`) |
| `prompts/` | AI prompt templates (see `lib/prompts/AGENTS.md`) |
| `resources/` | Static resource files (see `lib/resources/AGENTS.md`) |

## For AI Agents

### Working In This Directory

- All tools must be registered in `tool_registry.dart`
- Use `shared/logger.dart` for consistent logging
- Export public APIs via `boost.dart`
- Follow module boundaries - each directory has a specific purpose

### Testing Requirements

- Each module has corresponding tests in `test/`
- Run `dart test test/lib/<module>` for specific module tests

## Dependencies

### External

- `mcp_server` - MCP protocol implementation
- `serverpod` - ServerPod integration

<!-- MANUAL: -->
