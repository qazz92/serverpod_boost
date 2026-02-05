<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# ServerPod Boost

## Purpose

ServerPod Boost is an MCP (Model Context Protocol) server that provides AI assistants with deep semantic understanding of ServerPod projects. It enables high-quality code generation through context-aware tool access, giving AI assistants project awareness, endpoint intelligence, model understanding, database context, and code search capabilities.

## Key Files

| File | Description |
|------|-------------|
| `pubspec.yaml` | Package metadata and dependencies (v0.1.0) |
| `README.md` | Project documentation with quick start guide |
| `CHANGELOG.md` | Version history and release notes |
| `LICENSE` | MIT license |
| `CONTRIBUTING.md` | Contribution guidelines |
| `analysis_options.yaml` | Dart analyzer configuration |
| `.gitignore` | Git ignore patterns |
| `.pubignore` | Pub publish ignore patterns |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `bin/` | Executable entry points (see `bin/AGENTS.md`) |
| `lib/` | Main source code (see `lib/AGENTS.md`) |
| `test/` | Test suites (see `test/AGENTS.md`) |
| `test_integration/` | Integration tests |
| `doc/` | User documentation (see `doc/AGENTS.md`) |
| `example/` | Example configurations and usage |
| `coverage/` | Test coverage reports |

## For AI Agents

### Working In This Directory

- **Version**: 0.1.0 (Foundation Release)
- **Dart SDK**: >= 3.8.0 < 4.0.0
- **Dependencies**: ServerPod 3.2.3+, mcp_server 1.0.3+
- Run `dart pub get` after modifying `pubspec.yaml`
- Run `dart analyze` before committing
- Run `dart test` to run all tests (400+ tests)

### Project Structure

ServerPod Boost follows Dart package conventions:
- `bin/` - CLI executables
- `lib/` - All source code organized by module
- `test/` - Mirror of `lib/` structure with test files

### Testing Requirements

- All tests must pass before committing
- Target: 400+ tests covering tools, MCP protocol, file provisioning
- Run `dart test --coverage=coverage` for coverage reports
- Integration tests in `test_integration/` test against real ServerPod projects

### Common Patterns

- Use async/await for all async operations
- Return structured data objects (Maps/Lists) for MCP tools
- Use `logger` from `lib/shared/logger.dart` for colored output
- Follow Dart style guide (https://dart.dev/guides/language/effective-dart)

### Critical Invariants

- **MCP Protocol**: Must comply with MCP spec (JSON-RPC 2.0 over stdio)
- **Tool Names**: Must be lowercase with underscores (e.g., `application_info`)
- **Error Handling**: Always return structured errors in MCP responses
- **Project Detection**: Support ServerPod v3 monorepo structure only

## Dependencies

### External

- `serverpod: ^3.2.3` - ServerPod framework integration
- `mcp_server: ^1.0.3` - MCP protocol implementation
- `yaml: ^3.1.2` - YAML parsing for config/model files
- `path: ^1.8.3` - Path manipulation
- `mustache_template: ^2.0.0` - Template rendering for generated files
- `args: ^2.4.2` - CLI argument parsing
- `console: ^4.1.0` - Console formatting
- `http: ^1.6.0` - HTTP client for endpoint testing
- `postgres: ^3.0.0` - PostgreSQL connection for database queries

### Development

- `lints: ^3.0.0` - Dart lints
- `test: ^1.25.5` - Testing framework

## Architecture Overview

```
Boost Entry Point (bin/boost.dart)
    ↓
CLI Layer (lib/cli/, lib/commands/)
    ↓
Service Locator (lib/serverpod/serverpod_locator.dart)
    ↓
Tool Registry (lib/tool_registry.dart)
    ↓
MCP Server (lib/mcp/) → 20 Tools → ServerPod Project Analysis
```

## Related Projects

- **ServerPod**: https://serverpod.dev - Backend framework
- **Laravel Boost**: https://github.com/joelbutcher/laravel_boost - Inspiration
- **MCP Protocol**: https://modelcontextprotocol.io - Protocol spec

<!-- MANUAL: Custom project notes can be added below -->
