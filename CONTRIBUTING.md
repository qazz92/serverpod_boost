# Contributing to ServerPod Boost

Thank you for your interest in contributing to ServerPod Boost!

## Development Setup

1. Fork and clone the repository
2. Install dependencies: `dart pub get`
3. Run tests: `dart test`
4. Analyze code: `dart analyze`

## Code Style

- Follow Dart style guide
- Run `dart fix --apply` before committing
- Add tests for new features
- Update documentation

## Pull Requests

1. Create a descriptive branch name
2. Make your changes
3. Add/update tests
4. Ensure all tests pass
5. Submit a pull request with a clear description

## Tool Development

To add a new MCP tool:

1. Create tool class in `lib/tools/`
2. Extend `McpToolBase`
3. Implement `name`, `description`, `inputSchema`, and `executeImpl`
4. Register in `lib/tool_registry.dart`
5. Add tests in `test/tools/`

See existing tools for examples.
