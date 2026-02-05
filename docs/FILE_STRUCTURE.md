# ServerPod Boost - Complete File Structure

```
serverpod_boost/
│
├── README.md                            # User documentation
├── README_ARCHITECTURE.md               # Architecture overview (INDEX)
├── ARCHITECTURE.md                      # Complete technical design
├── DESIGN_SUMMARY.md                    # Executive summary
├── DIAGRAMS.md                          # Visual system diagrams
├── AGENTS.md                            # AI assistant usage guide
├── CHANGELOG.md                         # Version history
├── LICENSE.md                           # MIT License
├── CONTRIBUTING.md                      # Contribution guidelines
├── CONTRIBUTING_SKILLS.md               # Skill contribution guide
│
├── pubspec.yaml                         # Package specification
├── analysis_options.yaml                # Dart lint rules
│
├── bin/                                 # Executable scripts
│   └── serverpod_boost.dart             # Main CLI entry point
│       ├── Commands:                    # Available commands
│       │   ├── install                  # Install boost in project
│       │   ├── skills:list              # List available skills
│       │   ├── skills:update            # Update skills from remote
│       │   ├── mcp:start                # Start MCP server
│       │   ├── mcp:stop                 # Stop MCP server
│       │   ├── guidelines:show          # Show applicable guidelines
│       │   └── generate:endpoint        # Generate endpoint stub
│       │
│
├── lib/                                 # Main source code
│   └── src/
│       ├── serverpod_boost.dart         # Public API surface
│       │
│       ├── cli/                         # CLI implementation
│       │   ├── command_runner.dart      # Command routing
│       │   └── commands/
│       │       ├── install_command.dart
│       │       ├── skills_command.dart
│       │       ├── mcp_command.dart
│       │       └── guidelines_command.dart
│       │
│       ├── mcp/                         # MCP server
│       │   ├── mcp_server.dart          # Main MCP server
│       │   ├── tool_registry.dart       # Tool registration
│       │   └── tools/                   # MCP tool implementations
│       │       ├── discovery/           # Discovery tools
│       │       │   ├── list_endpoints.dart
│       │       │   ├── list_models.dart
│       │       │   ├── list_migrations.dart
│       │       │   └── get_config.dart
│       │       │
│       │       ├── inspection/          # Inspection tools
│       │       │   ├── get_database_schema.dart
│       │       │   ├── read_logs.dart
│       │       │   └── validate_endpoint.dart
│       │       │
│       │       ├── generation/          # Generation tools
│       │       │   ├── generate_endpoint.dart
│       │       │   ├── generate_model.dart
│       │       │   └── generate_migration.dart
│       │       │
│       │       └── utility/             # Utility tools
│       │           ├── search_docs.dart
│       │           └── run_migrations.dart
│       │
│       ├── skills/                      # Skills system
│       │   ├── skill.dart               # Base skill interface
│       │   ├── skill_metadata.dart      # Skill metadata model
│       │   ├── local_skill.dart         # Local file-based skill
│       │   ├── remote_skill.dart        # Remote GitHub-based skill
│       │   ├── skill_manager.dart       # Skill loader and manager
│       │   ├── skill_loader.dart        # Load skills from .ai/
│       │   └── remote_skill_loader.dart # Fetch skills from GitHub
│       │
│       ├── guidelines/                  # Guideline system
│       │   ├── guideline.dart           # Base guideline interface
│       │   ├── guideline_manager.dart   # Guideline loader
│       │   ├── code_context.dart        # Code context model
│       │   └── composers/               # Guideline composers
│       │       ├── endpoint_guideline.dart
│       │       ├── model_guideline.dart
│       │       ├── migration_guideline.dart
│       │       ├── streaming_guideline.dart
│       │       ├── flutter_integration_guideline.dart
│       │       ├── authentication_guideline.dart
│       │       ├── testing_guideline.dart
│       │       └── security_guideline.dart
│       │
│       ├── config/                      # Configuration
│       │   ├── boost_config.dart        # Configuration model
│       │   ├── config_loader.dart       # Load boost.yaml
│       │   └── default_config.yaml      # Default configuration
│       │
│       ├── codegen/                     # Code generation helpers
│       │   ├── generators/
│       │   │   ├── endpoint_generator.dart
│       │   │   ├── model_generator.dart
│       │   │   └── migration_generator.dart
│       │   └── templates/               # Code templates
│       │       ├── endpoint_template.dart
│       │       ├── model_template.dart
│       │       └── test_template.dart
│       │
│       ├── utils/                       # Utilities
│       │   ├── dart_formatter.dart      # Dart code formatter
│       │   ├── yaml_parser.dart         # YAML parsing utilities
│       │   ├── serverpod_finder.dart    # Find ServerPod project
│       │   ├── file_scanner.dart        # Scan project files
│       │   └── string_case.dart         # String case conversion
│       │
│       └── exceptions/                  # Custom exceptions
│           ├── boost_exception.dart     # Base exception
│           ├── validation_exception.dart
│           └── config_exception.dart
│
├── .ai/                                 # AI skill definitions (gitignored)
│   ├── serverpod/                       # ServerPod core skills
│   │   └── 1/                           # Version 1
│   │       └── skill/
│   │           └── serverpod-development/
│   │               ├── SKILL.md         # Skill definition (front matter + content)
│   │               └── reference/       # Supporting documentation
│   │                   ├── endpoints.md
│   │                   ├── models.md
│   │                   ├── streaming.md
│   │                   ├── sessions.md
│   │                   └── orm-patterns.md
│   │
│   ├── flutter/                         # Flutter integration skills
│   │   └── 1/
│   │       └── skill/
│   │           └── flutter-integration/
│   │               ├── SKILL.md
│   │               └── reference/
│   │                   ├── client-setup.md
│   │                   ├── endpoint-calls.md
│   │                   ├── real-time-streams.md
│   │                   ├── authentication.md
│   │                   └── error-handling.md
│   │
│   ├── database/                        # Database skills
│   │   └── 1/
│   │       └── skill/
│   │           └── database-design/
│   │               ├── SKILL.md
│   │               └── reference/
│   │                   ├── migrations.md
│   │                   ├── orm-patterns.md
│   │                   ├── query-optimization.md
│   │                   └── indexing.md
│   │
│   ├── authentication/                  # Authentication skills
│   │   └── 1/
│   │       └── skill/
│   │           └── auth-implementation/
│   │               ├── SKILL.md
│   │               └── reference/
│   │                   ├── serverpod-auth.md
│   │                   ├── oauth-providers.md
│   │                   ├── email-auth.md
│   │                   └── session-management.md
│   │
│   └── testing/                         # Testing skills
│       └── 1/
│           └── skill/
│               └── testing-best-practices/
│                   ├── SKILL.md
│                   └── reference/
│                       ├── integration-tests.md
│                       ├── endpoint-testing.md
│                       ├── database-testing.md
│                       └── mocking.md
│
├── config/                              # Package configuration
│   └── boost.yaml                       # Default boost config template
│       ├── mcp:                         # MCP server settings
│       ├── skills:                      # Skill sources
│       ├── guidelines:                  # Enabled guidelines
│       └── codegen:                     # Code generation settings
│
├── test/                                # Tests
│   ├── unit/                            # Unit tests
│   │   ├── mcp/                         # MCP tool tests
│   │   │   ├── tools/
│   │   │   │   ├── list_endpoints_test.dart
│   │   │   │   ├── list_models_test.dart
│   │   │   │   └── get_database_schema_test.dart
│   │   │   └── tool_registry_test.dart
│   │   │
│   │   ├── skills/                      # Skill system tests
│   │   │   ├── skill_manager_test.dart
│   │   │   ├── local_skill_test.dart
│   │   │   └── remote_skill_test.dart
│   │   │
│   │   ├── guidelines/                  # Guideline tests
│   │   │   ├── guideline_manager_test.dart
│   │   │   ├── endpoint_guideline_test.dart
│   │   │   └── model_guideline_test.dart
│   │   │
│   │   └── utils/                       # Utility tests
│   │       ├── dart_formatter_test.dart
│   │       └── serverpod_finder_test.dart
│   │
│   └── integration/                     # Integration tests
│       ├── cli_install_test.dart        # CLI install workflow
│       ├── mcp_server_test.dart         # MCP server integration
│       └── end_to_end_test.dart         # Full workflow tests
│
├── example/                             # Example ServerPod project
│   ├── server/                          # Example server
│   │   ├── lib/
│   │   │   └── src/
│   │   │       ├── endpoints/
│   │   │       │   ├── user_endpoint.dart
│   │   │       │   └── post_endpoint.dart
│   │   │       └── models/
│   │   │           ├── user.dart
│   │   │           └── post.dart
│   │   ├── migrations/
│   │   └── config/
│   │       └── generator.yaml
│   │
│   └── flutter/                         # Example Flutter client
│       ├── lib/
│       │   ├── main.dart
│       │   └── screens/
│       │       ├── home_screen.dart
│       │       └── profile_screen.dart
│       └── pubspec.yaml
│
├── .gitignore                           # Git ignore rules
├── .gitattributes                       # Git attributes
├── .editorconfig                        # Editor configuration
│
└── docs/                                # Additional documentation
    ├── api/                             # API documentation
    ├── guides/                          # User guides
    │   ├── getting-started.md
    │   ├── mcp-tools.md
    │   ├── creating-skills.md
    │   └── contributing-guidelines.md
    └── images/                          # Documentation images
        ├── architecture-diagram.png
        └── workflow-diagram.png
```

---

## Generated Files (After Installation)

When `serverpod_boost install` is run in a ServerPod project, these files are created:

```
my_serverpod_project/
├── .ai/                                 # Created by install
│   ├── serverpod/1/
│   ├── flutter/1/
│   ├── database/1/
│   ├── auth/1/
│   └── testing/1/
│
├── boost.yaml                           # Created by install
│   ├── mcp: { enabled: true, port: 8081 }
│   ├── skills: { local: { enabled: true } }
│   └── guidelines: { enabled: [...] }
│
└── .claude/                             # Updated (if exists)
    └── CLAUDE.md                        # Updated with MCP info
```

---

## File Size Estimates

| Category | Files | Est. Lines | Est. Size |
|----------|-------|------------|-----------|
| Core Library | ~50 | ~8,000 | ~250 KB |
| MCP Tools | ~15 | ~3,000 | ~100 KB |
| Skills System | ~10 | ~2,000 | ~70 KB |
| Guidelines | ~12 | ~2,500 | ~80 KB |
| CLI | ~8 | ~1,500 | ~50 KB |
| Tests | ~40 | ~5,000 | ~150 KB |
| Skills (.ai/) | ~20 | ~10,000 | ~300 KB |
| **Total** | **~155** | **~32,000** | **~1 MB** |

---

## Key File Descriptions

### Core Library Files

| File | Purpose | Lines |
|------|---------|-------|
| `serverpod_boost.dart` | Public API surface | ~50 |
| `mcp/mcp_server.dart` | Main MCP server | ~300 |
| `mcp/tool_registry.dart` | Tool registration | ~150 |
| `skills/skill_manager.dart` | Skill loader/manager | ~200 |
| `guidelines/guideline_manager.dart` | Guideline loader | ~150 |
| `cli/command_runner.dart` | CLI routing | ~100 |

### MCP Tool Files

| Tool | Purpose | Lines |
|------|---------|-------|
| `list_endpoints.dart` | List endpoints | ~100 |
| `list_models.dart` | List models | ~100 |
| `get_database_schema.dart` | Get schema | ~150 |
| `generate_endpoint.dart` | Generate endpoint | ~200 |
| `validate_endpoint.dart` | Validate code | ~150 |

### Skill Files

| Skill | Files | Lines |
|-------|-------|-------|
| serverpod-development | 1 SKILL.md + 5 reference | ~1,500 |
| flutter-integration | 1 SKILL.md + 5 reference | ~1,200 |
| database-design | 1 SKILL.md + 4 reference | ~1,000 |
| auth-implementation | 1 SKILL.md + 4 reference | ~800 |
| testing-best-practices | 1 SKILL.md + 4 reference | ~800 |

### Guideline Composer Files

| Guideline | Purpose | Lines |
|-----------|---------|-------|
| endpoint_guideline.dart | Endpoint patterns | ~200 |
| model_guideline.dart | Model patterns | ~150 |
| migration_guideline.dart | Migration patterns | ~150 |
| flutter_integration_guideline.dart | Flutter patterns | ~150 |

---

## Documentation Hierarchy

```
README.md (User-facing)
    ├── Quick start
    ├── Installation
    └── Basic usage

README_ARCHITECTURE.md (Index)
    ├── ARCHITECTURE.md (Complete design)
    ├── DESIGN_SUMMARY.md (Executive summary)
    ├── DIAGRAMS.md (Visual diagrams)
    └── AGENTS.md (AI usage)

docs/ (Detailed docs)
    ├── api/ (API reference)
    └── guides/ (User guides)
        ├── getting-started.md
        ├── mcp-tools.md
        ├── creating-skills.md
        └── contributing-guidelines.md
```

---

## Configuration Files

### boost.yaml

```yaml
# ServerPod Boost Configuration
mcp:
  enabled: true
  host: localhost
  port: 8081

skills:
  local:
    enabled: true
    path: .ai
  remote:
    - repo: serverpod/boost-skills
      skills:
        - serverpod-development
        - flutter-integration

guidelines:
  enabled:
    - endpoint_best_practices
    - model_design
    - migration_safety

codegen:
  endpoint_directory: lib/src/endpoints
  model_directory: lib/src/models
  generate_tests: true
```

### pubspec.yaml

```yaml
name: serverpod_boost
version: 1.0.0
description: AI-acceleration package for ServerPod

dependencies:
  serverpod: ^2.0.0
  mcp: ^0.5.0
  yaml: ^3.1.0
  http: ^1.2.0
  path: ^1.9.0

dev_dependencies:
  lints: ^3.0.0
  test: ^1.25.0
  mockito: ^5.4.0
```

---

**Document Version**: 1.0.0
**Last Updated**: 2025-02-04
