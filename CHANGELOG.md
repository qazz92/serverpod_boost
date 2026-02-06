# Changelog

All notable changes to ServerPod Boost will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.html).

## [0.1.5] - 2026-02-06

### Added
- **Wrapper Script Installation**: Install command now creates `run-boost.sh` wrapper script
  - Automatically created at project root during installation
  - Handles directory navigation to server folder automatically
  - Works reliably with all MCP clients regardless of `cwd` support
  - Simple project-local setup with no user-specific paths

### Changed
- **MCP Configuration**: Simplified to use wrapper script approach
  - `.mcp.json` now references `run-boost.sh` instead of complex configurations
  - No need for `cwd`, `env`, or `dart pub global run` commands
  - Works consistently across all platforms and users

### Fixed
- **MCP Connection**: Fixed connection issues when `.mcp.json` is in project root
  - Wrapper script ensures boost runs from correct directory
  - Resolves issues with clients that don't support `cwd` option properly

## [0.1.4] - 2026-02-06

### Fixed
- **Documentation**: Updated all documentation to reflect new `--path` option
  - Updated USER_GUIDE.md with new MCP configuration format
  - Updated CLI_REFERENCE.md with `--path` option documentation
  - Updated example config files to use `--path` instead of `cwd` + `env`
- **OpenCode Agent**: Updated to use `--path` option for consistency
- **Tests**: Updated all test files for new MCP configuration format
  - Removed assertions for old `cwd` and `env` parameters
  - Added assertions for new `--path` argument

## [0.1.3] - 2026-02-06

### Added
- **MCP Server `--path` Option**: Allow specifying ServerPod project path via command-line argument
  - Use `--path=/path/to/project` to specify project root
  - Enables MCP server to run from any directory
  - Useful when `.mcp.json` is in project root but server is in subdirectory

### Fixed
- **MCP Server Verbose Logging**: Fixed verbose flag not being passed through properly
  - `--verbose` flag now correctly enables detailed logging
  - Shows project detection, server path, and tool count

## [0.1.2] - 2026-02-05

### Fixed
- **Install Command**: Fixed skills not accessible when package is published to pub.dev
  - Moved skills from `.ai/skills/` to `lib/resources/skills/` for package accessibility
  - Updated `_findBoostSkillsPath()` to use `package_config` for path resolution
  - Skills are now properly bundled and accessible in published packages
- **Dependencies**: Added `package_config: ^2.1.0` for package path resolution

## [0.1.1] - 2026-02-05

### Fixed
- **Install Command**: Fixed skills not being copied to user projects
  - Corrected path calculation from `.parent.parent.parent` to `.parent.parent`
  - Added `.ai/skills/` as package assets in `pubspec.yaml`
  - Skills are now properly copied during installation
- **Install Command**: Made interactive mode the default behavior
  - Added `--non-interactive` flag for silent installation
  - Removed `--interactive` flag (now default)
- **Install Command**: Added `install` executable alongside `boost`
  - Users can now run `dart run serverpod_boost:install`
  - Created `bin/install.dart` entry point
- **Install Command**: Fixed skill selection flow
  - Handles missing skills directory gracefully
  - Copies all built-in skills when selection list is empty
- **Code Quality**: Fixed all dart analyze warnings (41 warnings → 0)
  - Removed duplicate exports and unused imports
  - Fixed deprecated MCP imports
  - Replaced print() statements with stdout.writeln()
  - Fixed null safety issues and unnecessary casts
- **Analysis Options**: Removed undefined lint rule `prefer_async_await`

### Changed
- Package URLs updated to use `qazz92/serverpod_boost` repository

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
