# ServerPod Boost

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/dart-3.8.0+-blue.svg)](https://dart.dev)
[![Tests](https://img.shields.io/badge/tests-400%2B-brightgreen.svg)](https://github.com/qazz92/serverpod_boost)

> AI acceleration for ServerPod development via MCP (Model Context Protocol)

ServerPod Boost is an MCP server that provides AI assistants (like Claude) with deep semantic understanding of ServerPod projects, enabling high-quality code generation through context-aware tool access.

## Version 0.1.3 - MCP Path Option

ServerPod Boost now supports running from any directory with the `--path` option, making it easier to use when your `.mcp.json` is in your project root but your ServerPod server is in a subdirectory.

## Version 0.1.2 - Published Package Fix

This is the first public release of ServerPod Boost, providing the core infrastructure for AI-assisted ServerPod development. The skills system framework is in place, with pre-built skills coming in future releases.

## What is ServerPod Boost?

Inspired by [Laravel Boost](https://github.com/joelbutcher/laravel_boost), ServerPod Boost gives AI assistants:

- **Project Awareness**: Automatic detection of ServerPod v3 monorepo structure
- **Endpoint Intelligence**: Parse and understand all endpoint methods with signatures
- **Model Understanding**: Read protocol model definitions from source `.spy.yaml` files
- **Database Context**: Access migration files and database schemas
- **Configuration Access**: Read all YAML config files
- **Code Search**: Full-text search across source code
- **Skills Infrastructure**: Framework for extensible workflows (pre-built skills coming soon)

## Quick Start

### 1. Install Boost

```bash
# Navigate to your ServerPod project's server directory
cd your_project_server

# Add as dev dependency
dart pub add serverpod_boost --dev

# Install everything (guidelines, skills, MCP config)
dart run serverpod_boost:install

# Or using the boost command
dart run serverpod_boost:boost install
```

That's it! The installer will:
- ✓ Detect your ServerPod project structure
- ✓ Create the `.ai/boost` directory
- ✓ Copy all necessary files
- ✓ Set up local development overrides
- ✓ Generate AGENTS.md and CLAUDE.md documentation
- ✓ Configure Claude Desktop automatically
- ✓ Install default skills

### 2. Configure Claude Desktop

The install command automatically creates a wrapper script `run-boost.sh` in your project. Add this to your Claude Desktop configuration:

```json
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "/path/to/your/project/run-boost.sh"
    }
  }
}
```

The `run-boost.sh` wrapper script is automatically created by the install command and handles all the complexity for you - no need to worry about global installations or system-specific paths.

**Configuration file locations:**
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%\Claude\claude_desktop_config.json`
- **Linux**: `~/.config/Claude/claude_desktop_config.json`

See [examples/](examples/) directory for complete configuration samples.

### 3. Restart Claude & Start Coding

Ask Claude anything about your ServerPod project:
- "What endpoints exist in this project?"
- "Create a new endpoint for user management"
- "Show me the database schema for the users table"
- "Generate a test for the greeting endpoint"
- "Use the endpoint_creator skill to add a user profile endpoint"

## Features

### 20 Built-in Tools

| Tool | Description |
|------|-------------|
| `application_info` | Complete project overview |
| `list_endpoints` | List all endpoints |
| `endpoint_methods` | Get endpoint method details |
| `list_models` | List all protocol models |
| `model_inspector` | Inspect model fields |
| `config_reader` | Read YAML configs |
| `database_schema` | Get database schema |
| `migration_scanner` | List migrations |
| `project_structure` | File tree browser |
| `find_files` | Find files by pattern |
| `read_file` | Read file content |
| `search_code` | Search code content |
| `call_endpoint` | Test endpoints |
| `service_config` | Service configuration |
| `list_skills` | List available skills |
| `get_skill` | Get skill content |
| `log_reader` | Read ServerPod logs |
| `database_query` | Query database |
| `cli_commands` | List CLI commands |
| `tinker` | Execute Dart code |

### Skills Infrastructure

ServerPod Boost includes the infrastructure for an extensible skills system. The framework is in place for creating and managing reusable workflows that combine multiple tools. Pre-built skills will be available in future releases.

## CLI Commands

```bash
# Installation
dart run serverpod_boost:install              # Install (interactive by default)
dart run serverpod_boost:install --non-interactive  # Silent install
dart run serverpod_boost:boost install        # Same as above

# Skills
dart run serverpod_boost:boost skill:list     # List available skills
dart run serverpod_boost:boost skill:show <name>  # Show skill details
```

## Project Structure

ServerPod Boost understands ServerPod's 3-package monorepo:

```
your_project/
├── project_server/    # Source of truth
│   ├── lib/src/
│   │   ├── **/*_endpoint.dart
│   │   └── **/*.spy.yaml
│   └── config/
├── project_client/    # Generated (Boost reads this too)
└── project_flutter/   # Flutter app
```

Boost creates these directories:

```
your_project/
├── .ai/
│   ├── boost/
│   │   ├── bin/              # Boost executable
│   │   ├── skills/           # Local skills directory
│   │   └── config/           # Local configuration
│   ├── AGENTS.md             # Generated AI documentation
│   └── CLAUDE.md             # Generated Claude instructions
```

## Requirements

- **Dart**: 3.8.0 or higher
- **ServerPod**: 3.2.3 or higher
- **Project**: Valid ServerPod v3 monorepo structure

## Development

```bash
# Run tests
dart test

# Run with coverage
dart test --coverage=coverage

# Analyze code
dart analyze

# Run with verbose output
dart run bin/boost.dart --verbose

# Using the boost command wrapper
boost info
boost endpoints --detailed
boost models
```

## Documentation

- **[사용자 가이드 (User Guide)](doc/USER_GUIDE.md)** - 완전한 사용 설명서 (설치, 빠른 시작, MCP 도구, 스킬 시스템, CLI 명령어)
- **[CLI 명령어 레퍼런스 (CLI Reference)](doc/CLI_REFERENCE.md)** - 모든 CLI 명령어 상세 설명
- **[MCP 도구 레퍼런스 (MCP Tools Reference)](doc/MCP_TOOLS_REFERENCE.md)** - 20개 MCP 도구 상세 문서
- **[스킬 개발 가이드 (Skills Development Guide)](doc/SKILLS_DEVELOPMENT_GUIDE.md)** - 커스텀 스킬 만들기
- [AGENTS.md](AGENTS.md) - AI 에이전트를 위한 프로젝트 문서

## Testing

Boost includes 400+ tests covering:

- Tool functionality (20 tools × multiple scenarios)
- Skills system infrastructure
- File provisioning
- MCP protocol compliance
- Error handling and edge cases

```bash
# Run all tests
dart test

# Run specific test suite
dart test test/tools/tools_integration_test.dart
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

- Inspired by [Laravel Boost](https://github.com/joelbutcher/laravel_boost)
- Built for [ServerPod](https://serverpod.dev)
- Uses [MCP Protocol](https://modelcontextprotocol.io)

## Roadmap

- [ ] Web UI for skill management
- [ ] Skill marketplace
- [ ] Visual workflow builder
- [ ] Integration with other AI assistants
- [ ] Performance monitoring and analytics

---

**Made with ❤️ for the ServerPod community**

**Version**: 0.1.3 | **Tests**: 400+ | **Tools**: 20
