# Changelog

All notable changes to ServerPod Boost will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.html).

## [0.1.0] - 2026-02-05

### Added
- **20 MCP Tools** for comprehensive ServerPod project analysis:
  - Tier 1 - Essential Tools: `application_info`, `list_endpoints`, `endpoint_methods`, `list_models`, `list_skills`, `get_skill`, `model_inspector`, `config_reader`, `database_schema`, `migration_scanner`
  - Tier 2 - Enhanced Tools: `project_structure`, `find_files`, `read_file`, `search_code`, `call_endpoint`, `service_config`, `log_reader`
  - Tier 3 - Database Tools: `database_query`
  - Tier 4 - CLI Tools: `cli_commands`
  - Tier 5 - Developer Tools: `tinker`
- **MCP Server Implementation** using `package:mcp_server` (v1.0.3) with JSON-RPC 2.0 over stdio
- **Project Detection Capabilities** for ServerPod v3 monorepos with automatic root, server, client, and Flutter app discovery
- **YAML Parser** for reading `.spy.yaml` protocol model definitions with full field extraction including types, persistence, and serialization settings
- **Method Signature Parser** for endpoint methods with return types, parameter names/types, and documentation extraction
- **Service Locator** (`ServerPodLocator`) for centralized project access and validation
- **Database Query Tool** for executing SQL queries against ServerPod databases
- **CLI Commands Tool** for executing ServerPod CLI commands (migrate, generate, etc.)
- **Log Reader Tool** for reading ServerPod server logs
- **Tinker Tool** for interactive code evaluation
- **Comprehensive Test Coverage** with integration tests

### Implemented
- MCP protocol compliance with tools, resources, and prompts support
- Tool adapter layer for converting Boost tools to MCP server format
- Colored logging system with configurable verbosity
- Configuration management with local override support
- Error handling and validation throughout
- Migration framework from legacy MCP implementation to `package:mcp_server`

### Tested
- Tool functionality across all 20 tools
- MCP server initialization and communication
- Project detection and validation
- YAML parsing for model definitions
- Method signature extraction
- Integration tests against real ServerPod projects
