# ServerPod Boost V2

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/dart-3.8.0+-blue.svg)](https://dart.dev)
[![Tests](https://img.shields.io/badge/tests-277%20passing-brightgreen.svg)](https://github.com/serverpod/boost)

> AI acceleration for ServerPod development via MCP (Model Context Protocol)

ServerPod Boost V2 is an MCP server that provides AI assistants (like Claude) with deep semantic understanding of ServerPod projects, enabling high-quality code generation through context-aware tool access and an extensible skills system.

## What's New in V2?

- **Skills System**: 8 built-in skills for common workflows
- **Remote Skills**: Load skills from GitHub repositories
- **Interactive Installation**: `boost install` CLI with auto-configuration
- **File Provisioning**: Auto-generate AGENTS.md and CLAUDE.md
- **Smart Merge**: Intelligent merging of documentation files
- **MCP Auto-Config**: Automatic Claude Desktop configuration
- **277 Tests**: Comprehensive test coverage

## What is ServerPod Boost?

Inspired by [Laravel Boost](https://github.com/joelbutcher/laravel_boost), ServerPod Boost gives AI assistants:

- **Project Awareness**: Automatic detection of ServerPod v3 monorepo structure
- **Endpoint Intelligence**: Parse and understand all endpoint methods with signatures
- **Model Understanding**: Read protocol model definitions from source `.spy.yaml` files
- **Database Context**: Access migration files and database schemas
- **Configuration Access**: Read all YAML config files
- **Code Search**: Full-text search across source code
- **Extensible Skills**: Create and share reusable workflows
- **Remote Capabilities**: Load skills from GitHub repositories

## Quick Start

### 1. Install Boost

```bash
# Navigate to your ServerPod project root
cd your_serverpod_project

# Add as dev dependency
dart pub add serverpod_boost --dev

# Install everything (guidelines, skills, MCP config)
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

### Alternative: Manual Installation

```bash
cd your_serverpod_project
mkdir -p .ai/boost
cd .ai/boost
dart pub add serverpod_boost --path=/path/to/serverpod_boost
```

### 2. Configure Claude Desktop

If you didn't use the interactive installer, add this to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "dart",
      "args": [".ai/boost/bin/boost.dart"],
      "cwd": "/path/to/your/project"
    }
  }
}
```

See [examples/](examples/) directory for complete configuration samples.

### 3. Restart Claude & Start Coding

Ask Claude anything about your ServerPod project:
- "What endpoints exist in this project?"
- "Create a new endpoint for user management"
- "Show me the database schema for the users table"
- "Generate a test for the greeting endpoint"
- "Use the endpoint_creator skill to add a user profile endpoint"

## Features

### 14 Built-in Tools

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

### 8 Built-in Skills

Skills are pre-built workflows that combine multiple tools for common tasks:

| Skill | Description |
|-------|-------------|
| `core` | Core ServerPod development patterns |
| `endpoints` | Endpoint creation and patterns |
| `models` | Protocol model definitions |
| `migrations` | Database migration patterns |
| `testing` | Testing best practices |
| `authentication` | Authentication patterns |
| `webhooks` | Webhook handling |
| `redis` | Redis caching |

### Remote Skills from GitHub

Load skills from any GitHub repository:

```bash
boost skill:add username/repo skill-name
boost skill:list
boost skill:show skill-name
```

See [doc/SKILLS_DEVELOPMENT_GUIDE.md](doc/SKILLS_DEVELOPMENT_GUIDE.md) for creating and sharing skills.

## CLI Commands

```bash
boost install                  # Install everything (guidelines, skills, MCP)
boost skill:list               # List available skills
boost skill:show <name>        # Show skill details
boost skill:render <name>      # Render skill
boost skill:add <repo> [skill] # Add remote skill from GitHub
boost skill:remove <name>      # Remove skill
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
│   │   ├── skills/           # Local skills
│   │   │   └── default/      # 8 built-in skills
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
- **[MCP 도구 레퍼런스 (MCP Tools Reference)](doc/MCP_TOOLS_REFERENCE.md)** - 14개 MCP 도구 상세 문서
- **[스킬 개발 가이드 (Skills Development Guide)](doc/SKILLS_DEVELOPMENT_GUIDE.md)** - 커스텀 스킬 만들기
- [AGENTS.md](AGENTS.md) - AI 에이전트를 위한 프로젝트 문서

## Testing

Boost V2 includes 277 tests covering:

- Tool functionality (14 tools × multiple scenarios)
- Skills system (8 built-in skills)
- Remote skill loading
- File provisioning
- MCP protocol compliance
- Error handling and edge cases

```bash
# Run all tests
dart test

# Run specific test suite
dart test test/skills_composer_simple.dart
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

**Version**: 2.0.0 | **Tests**: 277 passing | **Tools**: 14 | **Skills**: 8
