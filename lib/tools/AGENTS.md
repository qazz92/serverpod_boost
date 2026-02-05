<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# tools

## Purpose

20 MCP tools for comprehensive ServerPod project analysis. Each tool is a self-contained module that provides specific project insight (endpoints, models, database, configs, etc.).

## Key Files

| File | Description |
|------|-------------|
| `tools.dart` | Tool registry and exports |
| `application_info_tool.dart` | Project overview |
| `list_endpoints_tool.dart` | List all endpoints |
| `endpoint_methods_tool.dart` | Get endpoint method details |
| `list_models_tool.dart` | List protocol models |
| `model_inspector_tool.dart` | Inspect model fields |
| `config_reader_tool.dart` | Read YAML configs |
| `database_schema_tool.dart` | Get database schema |
| `migration_scanner_tool.dart` | List migrations |
| `project_structure_tool.dart` | File tree browser |
| `find_files_tool.dart` | Find files by pattern |
| `read_file_tool.dart` | Read file content |
| `search_code_tool.dart` | Search code content |
| `call_endpoint_tool.dart` | Test endpoints |
| `service_config_tool.dart` | Service configuration |
| `list_skills_tool.dart` | List available skills |
| `get_skill_tool.dart` | Get skill content |
| `log_reader_tool.dart` | Read ServerPod logs |
| `database_query_tool.dart` | Query database |
| `cli_commands_tool.dart` | List CLI commands |
| `tinker_tool.dart` | Execute Dart code |

## For AI Agents

### Working In This Directory

- Each file = one tool
- Tool name format: `snake_case`
- Must return Map<String, dynamic> with `content` field
- All tools registered in `tool_registry.dart`

### Tool Categories

**Tier 1 - Essential** (10 tools):
- application_info, list_endpoints, endpoint_methods, list_models, list_skills, get_skill, model_inspector, config_reader, database_schema, migration_scanner

**Tier 2 - Enhanced** (5 tools):
- project_structure, find_files, read_file, search_code, call_endpoint, service_config, log_reader

**Tier 3 - Database** (1 tool):
- database_query

**Tier 4 - CLI** (1 tool):
- cli_commands

**Tier 5 - Developer** (1 tool):
- tinker

## Dependencies

### Internal

- `lib/serverpod/` - ServerPod project access
- `lib/shared/` - Utilities

<!-- MANUAL: -->
