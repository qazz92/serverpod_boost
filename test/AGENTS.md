<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-02-05 | Updated: 2026-02-05 -->

# test

## Purpose

Comprehensive test suite covering all 20 MCP tools, MCP protocol compliance, CLI commands, skills infrastructure, and integration tests against real ServerPod projects. Contains 400+ tests.

## Key Files

| File | Description |
|------|-------------|
| `test_tools.dart` | Shared test utilities and fixtures |
| `tools_integration_test.dart` | Integration tests for all tools |

## Subdirectories

| Directory | Purpose |
|-----------|---------|
| `tools/` | Tool-specific tests (see `test/tools/AGENTS.md`) |
| `mcp/` | MCP protocol tests (see `test/mcp/AGENTS.md`) |
| `cli/` | CLI command tests (see `test/cli/AGENTS.md`) |
| `serverpod/` | ServerPod detection tests (see `test/serverpod/AGENTS.md`) |
| `skills/` | Skills system tests (see `test/skills/AGENTS.md`) |
| `agents/` | Agent utility tests (see `test/agents/AGENTS.md`) |
| `guidelines/` | Template rendering tests (see `test/guidelines/AGENTS.md`) |
| `unit/` | Unit tests for utilities (see `test/unit/AGENTS.md`) |
| `integration/` | End-to-end integration tests (see `test/integration/AGENTS.md`) |

## For AI Agents

### Working In This Directory

- Mirror structure of `lib/` directory
- Test file: `<module>_test.dart`
- Integration test: `<module>_integration_test.dart`
- Use `test_tools.dart` for shared fixtures

### Running Tests

```bash
# All tests
dart test

# Specific directory
dart test test/tools/

# Coverage
dart test --coverage=coverage

# Specific test file
dart test test/tools/tools_integration_test.dart
```

### Test Coverage

- 20 tools × multiple scenarios each
- MCP protocol compliance
- Error handling and edge cases
- File provisioning
- CLI commands

<!-- MANUAL: -->
