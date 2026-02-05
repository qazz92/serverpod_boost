# ServerPod Boost Architecture Design

## Project Purpose

**ServerPod Boost** is an AI-acceleration package for ServerPod applications, inspired by Laravel Boost. It provides LLMs with essential context, structure, and tools to generate high-quality, ServerPod-specific code through vibe-coding assistance.

### Core Mission

Enable AI assistants to:
- Understand ServerPod project structure and conventions
- Generate idiomatic Dart/ServerPod code
- Access project state via MCP tools
- Apply domain-specific skills for common patterns
- Follow best practices without manual guidance

---

## Architecture Philosophy

### Design Principles

1. **Convention over Configuration** - Follow ServerPod's established patterns
2. **AI-First** - Structure data for LLM consumption, not humans
3. **Non-Invasive** - Optional enhancement, not framework replacement
4. **Dart-Native** - Leverage Dart's type system and patterns
5. **Flutter-Integrated** - Support full-stack ServerPod + Flutter workflow

### Key Differences from Laravel Boost

| Aspect | Laravel Boost | ServerPod Boost |
|--------|---------------|-----------------|
| Language | PHP | Dart |
| Package Manager | Composer | Pub |
| CLI | Artisan | Serverpod CLI |
| Config | PHP arrays | YAML |
| Routing | routes/web.php | Endpoints (typed methods) |
| Code Gen | Stub files | Protocol generation |
| Client Side | Blade/Inertia | Flutter (generated) |

---

## Project Structure

```
serverpod_boost/
├── bin/                              # Executable scripts
│   └── serverpod_boost.dart          # Main CLI entry point
│
├── lib/                              # Main source code
│   └── src/
│       ├── serverpod_boost.dart      # Public API surface
│       │
│       ├── cli/                      # CLI commands
│       │   ├── commands/
│       │   │   ├── InstallCommand.dart
│       │   │   ├── SkillsCommand.dart
│       │   │   └── McpCommand.dart
│       │   └── command_runner.dart
│       │
│       ├── mcp/                      # MCP server implementation
│       │   ├── mcp_server.dart       # Main MCP server
│       │   ├── tools/                # MCP tool implementations
│       │   │   ├── list_endpoints.dart
│       │   │   ├── list_models.dart
│       │   │   ├── get_database_schema.dart
│       │   │   ├── run_migrations.dart
│       │   │   ├── read_logs.dart
│       │   │   ├── get_config.dart
│       │   │   └── search_docs.dart
│       │   └── tool_registry.dart
│       │
│       ├── skills/                   # Skills system
│       │   ├── skill.dart            # Base skill interface
│       │   ├── local_skill.dart      # Local file-based skills
│       │   ├── remote_skill.dart     # Remote GitHub-based skills
│       │   └── skill_manager.dart
│       │
│       ├── guidelines/               # Guideline system
│       │   ├── guideline.dart        # Guideline interface
│       │   ├── guideline_loader.dart
│       │   └── composers/            # Guideline composers
│       │       ├── endpoint_guideline.dart
│       │       ├── model_guideline.dart
│       │       ├── migration_guideline.dart
│       │       └── flutter_integration_guideline.dart
│       │
│       ├── config/                   # Configuration
│       │   ├── boost_config.dart
│       │   └── config_loader.dart
│       │
│       ├── codegen/                  # Code generation helpers
│       │   ├── endpoint_generator.dart
│       │   ├── model_generator.dart
│       │   └── migration_generator.dart
│       │
│       ├── utils/                    # Utilities
│       │   ├── dart_formatter.dart
│       │   ├── yaml_parser.dart
│       │   └── serverpod_finder.dart
│       │
│       └── exceptions/               # Custom exceptions
│           ├── boost_exception.dart
│           └── validation_exception.dart
│
├── .ai/                              # AI skill definitions (gitignored)
│   ├── serverpod/                    # Core ServerPod skills
│   │   └── 1/
│   │       └── skill/
│   │           └── serverpod-development/
│   │               ├── SKILL.md
│   │               └── reference/
│   │                   ├── endpoints.md
│   │                   ├── models.md
│   │                   └── streaming.md
│   │
│   ├── flutter/                      # Flutter integration skills
│   │   └── 1/
│   │       └── skill/
│   │           └── flutter-integration/
│   │               ├── SKILL.md
│   │               └── reference/
│   │                   ├── client-setup.md
│   │                   └── real-time-streams.md
│   │
│   ├── database/                     # Database skills
│   │   └── 1/
│   │       └── skill/
│   │           └── database-design/
│   │               ├── SKILL.md
│   │               └── reference/
│   │                   ├── migrations.md
│   │                   └── orm-patterns.md
│   │
│   ├── authentication/               # Authentication skills
│   │   └── 1/
│   │       └── skill/
│   │           └── auth-implementation/
│   │               ├── SKILL.md
│   │               └── reference/
│   │                   ├── serverpod-auth.md
│   │                   └── oauth-providers.md
│   │
│   └── testing/                      # Testing skills
│       └── 1/
│           └── skill/
│               └── testing-best-practices/
│                   ├── SKILL.md
│                   └── reference/
│                       ├── integration-tests.md
│                       └── endpoint-testing.md
│
├── config/                           # Package configuration
│   └── boost.yaml                    # Default boost config
│
├── test/                             # Tests
│   ├── unit/
│   │   ├── mcp/
│   │   ├── skills/
│   │   └── guidelines/
│   └── integration/
│       └── cli_test.dart
│
├── example/                          # Example ServerPod project
│   ├── server/
│   └── flutter/
│
├── pubspec.yaml                      # Package specification
├── analysis_options.yaml             # Dart lint rules
├── README.md                         # User documentation
├── CHANGELOG.md                      # Version history
├── LICENSE.md                        # MIT License
└── AGENTS.md                         # This file - AI assistant guide
```

---

## Core Components

### 1. MCP (Model Context Protocol) Server

The MCP server provides AI assistants with real-time project state and capabilities.

#### Tool Registry

```dart
// lib/src/mcp/tool_registry.dart
class ToolRegistry {
  final Map<String, Tool> _tools = {};

  void registerTool(String name, Tool tool) {
    _tools[name] = tool;
  }

  List<Tool> getAllTools() => _tools.values.toList();
  Tool? getTool(String name) => _tools[name];
}
```

#### Available MCP Tools

| Tool | Purpose | Input | Output |
|------|---------|-------|--------|
| `list_endpoints` | List all endpoints in project | filter: string | List of endpoint definitions |
| `list_models` | List all models | filter: string | List of model definitions with fields |
| `get_database_schema` | Get current database schema | table_name?: string | Database tables and columns |
| `run_migrations` | Apply pending migrations | dry_run?: boolean | Migration status |
| `read_logs` | Read ServerPod logs | lines?: number, level?: string | Recent log entries |
| `get_config` | Get ServerPod configuration | key?: string | Config values |
| `search_docs` | Search ServerPod documentation | query: string | Relevant docs |
| `validate_endpoint` | Validate endpoint method | file: string, method: string | Validation results |
| `generate_endpoint` | Generate new endpoint stub | name: string, methods: list | Generated file path |
| `generate_model` | Generate new model stub | name: string, fields: list | Generated files |

#### MCP Tool Implementation Example

```dart
// lib/src/mcp/tools/list_endpoints.dart
class ListEndpoints extends Tool {
  @override
  String get name => 'list_endpoints';

  @override
  String get description => 'List all ServerPod endpoints with their methods';

  @override
  Map<String, dynamic> get schema => {
    'filter': {
      'type': 'string',
      'description': 'Filter endpoints by name pattern',
    },
  };

  @override
  Future<Response> handle(Request request) async {
    final filter = request.params['filter'] as String?;
    final endpoints = await EndpointScanner.scan(filter: filter);

    return Response.json({
      'endpoints': endpoints.map((e) => e.toJson()).toList(),
    });
  }
}
```

### 2. Skills System

Skills provide domain-specific knowledge to AI assistants.

#### Skill Interface

```dart
// lib/src/skills/skill.dart
abstract class Skill {
  String get name;
  String get description;
  List<String> get triggers;

  /// When this skill should be activated
  bool shouldActivate(String userMessage);

  /// Provide context/guidance for the skill
  Future<String> provideContext();

  /// Get reference documentation
  Future<List<String>> getReferences();
}
```

#### Local Skills

Loaded from `.ai/{domain}/{version}/skill/{name}/` directories:

```
.ai/serverpod/1/skill/serverpod-development/
├── SKILL.md                    # Main skill definition (front matter + markdown)
└── reference/                  # Supporting documentation
    ├── endpoints.md
    ├── models.md
    └── streaming.md
```

**SKILL.md Format:**

```yaml
---
name: serverpod-development
description: >-
  Develops ServerPod endpoints, models, and services. Activates when creating
  endpoints, working with models, database operations, streaming, or when
  the user mentions ServerPod, backend, API, or database.
triggers:
  - create endpoint
  - create model
  - add method
  - serverpod
  - backend
  - api
---

# ServerPod Development

## When to Apply

Activate this skill when:
- Creating or modifying endpoints
- Defining or updating models
- Working with database operations
- Implementing real-time streaming

## Documentation

Use `search-docs` for detailed ServerPod patterns and documentation.

## Endpoint Creation

Endpoints are defined in `lib/src/endpoints/`...

<code-snippet name="Basic Endpoint" lang="dart">
class UserEndpoint extends Endpoint {
  Future<User?> getUserById(Session session, int userId) async {
    return await User.db.findFirstRow(
      session,
      where: (p) => p.id.equals(userId),
    );
  }
}
</code-snippet>
```

#### Remote Skills

Fetched from GitHub repositories:

```dart
// lib/src/skills/remote_skill.dart
class RemoteSkill {
  final String name;
  final String repo;      // e.g., 'serverpod/boost-skills'
  final String path;      // e.g., 'skills/auth/1'

  Future<Skill> fetch() async {
    final client = GitHubClient();
    final content = await client.fetchRepositoryContents(
      repo,
      path: '$path/skill',
    );
    return _parseSkillFromGitHub(content);
  }
}
```

#### Skill Manager

```dart
// lib/src/skills/skill_manager.dart
class SkillManager {
  final List<Skill> _localSkills = [];
  final List<RemoteSkill> _remoteSkills = [];

  Future<void> loadLocalSkills(String projectPath) async {
    final aiDir = Directory('$projectPath/.ai');
    if (!await aiDir.exists()) return;

    await for (final domain in aiDir.list()) {
      await _loadSkillDomain(domain);
    }
  }

  Future<void> loadRemoteSkills(List<String> repositories) async {
    for (final repo in repositories) {
      final skills = await _fetchRemoteSkills(repo);
      _remoteSkills.addAll(skills);
    }
  }

  List<Skill> getActiveSkills(String userMessage) {
    return [
      ..._localSkills,
      ..._remoteSkills,
    ].where((skill) => skill.shouldActivate(userMessage))
     .toList();
  }
}
```

### 3. Guideline System

Guidelines are context-aware composable documentation blocks.

#### Guideline Interface

```dart
// lib/src/guidelines/guideline.dart
abstract class Guideline {
  String get name;
  String get category;

  /// Priority (higher = more specific)
  int get priority;

  /// Check if guideline applies to current context
  bool appliesTo(CodeContext context);

  /// Generate guideline content
  Future<String> generate(CodeContext context);
}
```

#### Guideline Composers

Specialized generators for different code patterns:

```dart
// lib/src/guidelines/composers/endpoint_guideline.dart
class EndpointGuideline extends Guideline {
  @override
  String get name => 'endpoint_best_practices';

  @override
  String get category => 'endpoints';

  @override
  int get priority => 100;

  @override
  bool appliesTo(CodeContext context) {
    return context.fileType == FileType.endpoint ||
           context.currentClass?.endsWith('Endpoint') == true;
  }

  @override
  Future<String> generate(CodeContext context) async {
    final endpointName = context.currentClass ?? 'Unknown';

    return '''
## Endpoint Guidelines for: $endpointName

### Required Structure
- Extend \`Endpoint\` base class
- All methods must accept \`Session session\` as first parameter
- Return \`Future<T>\` for async operations
- Use descriptive method names (getUserById, not get)

### Common Patterns

#### Database Operations
\`\`\`dart
// GOOD: Use ORM methods
final user = await User.db.findById(session, userId);

// BAD: Don't write raw SQL
final result = await session.db.query('SELECT * FROM user WHERE id = ?', [userId]);
\`\`\`

#### Error Handling
\`\`\`dart
try {
  final result = await operation(session);
  return result;
} catch (e, stackTrace) {
  session.log('Operation failed: \$e', level: LogLevel.error);
  rethrow;
}
\`\`\`

### DO/DON'T
| DO | DON'T |
|-----|--------|
| Use ORM methods | Raw SQL queries |
| Add logging | Silent failures |
| Return typed results | Return dynamic |
| Validate inputs | Trust client data |
''';
  }
}
```

#### Other Guideline Composers

- `ModelGuideline` - Model definition best practices
- `MigrationGuideline` - Database migration patterns
- `FlutterIntegrationGuideline` - Client-side integration
- `StreamingGuideline` - Real-time communication
- `TestingGuideline` - Test patterns for endpoints
- `AuthenticationGuideline` - Auth implementation patterns

### 4. Configuration System

```dart
// lib/src/config/boost_config.dart
class BoostConfig {
  // MCP Server
  final McpConfig mcp;

  // Skills
  final List<String> skillRepositories;
  final bool enableLocalSkills;

  // Guidelines
  final List<String> enabledGuidelines;

  // Code Generation
  final CodegenConfig codegen;

  // Paths
  final String serverpodProjectPath;
}

class McpConfig {
  final int port;
  final String host;
  final bool enabled;
}

class CodegenConfig {
  final String endpointDirectory;
  final String modelDirectory;
  final bool generateTests;
}
```

**Config File (boost.yaml):**

```yaml
# boost.yaml - ServerPod Boost configuration

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
        - database-design

guidelines:
  enabled:
    - endpoint_best_practices
    - model_design
    - migration_safety
    - flutter_client_patterns

codegen:
  endpoint_directory: lib/src/endpoints
  model_directory: lib/src/models
  generate_tests: true

paths:
  serverpod_project: .
```

---

## How It Works

### Installation Flow

```
1. User runs: dart pub global activate serverpod_boost
2. User runs: serverpod_boost install
3. Installer detects ServerPod project structure
4. Creates .ai/ directory structure
5. Copies default skills from package
6. Generates boost.yaml config
7. Registers MCP server with ai-assistant
```

### Development Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      User Request                           │
│                 "Create user endpoint"                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              AI Assistant (Claude, etc.)                    │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              MCP Server (serverpod_boost)                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 1. Identify Active Skills                          │   │
│  │    - serverpod-development ✓                       │   │
│  │    - flutter-integration (if relevant)              │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 2. Load Applicable Guidelines                      │   │
│  │    - endpoint_best_practices                        │   │
│  │    - model_design (if creating models too)          │   │
│  └─────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ 3. Gather Project Context via Tools                 │   │
│  │    - list_models (to see existing User model)       │   │
│  │    - get_database_schema (user table structure)     │   │
│  │    - list_endpoints (avoid naming conflicts)        │   │
│  └─────────────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                   Generated Response                        │
│  - SKILL.md content loaded                                  │
│  - Project context (models, endpoints)                      │
│  - Best practices for endpoints                             │
│  - Code snippets for patterns                               │
└─────────────────────────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              AI Generates Code                              │
│  - Creates UserEndpoint with best practices                 │
│  - Uses ORM methods correctly                               │
│  - Adds error handling and logging                          │
│  - Follows project conventions                              │
└─────────────────────────────────────────────────────────────┘
```

### MCP Tool Execution Flow

```
AI Request → MCP Server → Tool Registry → Tool Implementation → Project State → Response
```

**Example:**

```dart
// AI: "Create a method to get all active users"
//
// 1. AI calls: list_models
//    → Returns: User model with fields (id, name, email, isActive)
//
// 2. AI calls: get_database_schema
//    → Returns: user table schema
//
// 3. AI receives skill context from serverpod-development
//    → Best practices for querying with filters
//
// 4. AI generates:
class UserEndpoint extends Endpoint {
  Future<List<User>> getActiveUsers(Session session) async {
    return await User.db.find(
      session,
      where: (p) => p.isActive.equals(true),
      orderBy: (p) => p.name,
    );
  }
}
```

---

## Integration Points

### 1. With ServerPod CLI

```bash
# ServerPod Boost commands extend ServerPod CLI
serverpod boost:install          # Install boost in project
serverpod boost:skills:list      # List available skills
serverpod boost:skills:update    # Update skills from remote
serverpod boost:mcp:start        # Start MCP server
serverpod boost:guidelines       # Show applicable guidelines
```

### 2. With AI Assistants

**Claude Code Integration:**

```yaml
# .claude/CLAUDE.md
ServerPod Boost is active. MCP tools available at localhost:8081

When working on this ServerPod project:
1. Use `list_endpoints` before creating new ones
2. Use `list_models` to understand data structures
3. Activate `serverpod-development` skill for backend work
4. Activate `flutter-integration` skill for client code
```

### 3. With Flutter Client

Skills provide guidance for Flutter integration:

```dart
// .ai/flutter/1/skill/flutter-integration/SKILL.md
## Flutter Client Integration

### Endpoint Calls
\`\`\`dart
// GOOD: Use generated client
final user = await client.user.getUserById(1);

// BAD: Manual HTTP requests
final response = await http.get('/user/1');
\`\`\`

### Streaming
\`\`\`dart
// Subscribe to server stream
final subscription = client.chat.messageStream(roomId).listen(
  (message) => setState(() => messages.add(message)),
);
```

---

## File Structure Details

### Directory Naming Conventions

| Directory | Purpose | Example |
|-----------|---------|---------|
| `.ai/{domain}/{version}/` | Domain-specific skills | `.ai/serverpod/1/` |
| `lib/src/endpoints/` | Endpoint definitions | `user_endpoint.dart` |
| `lib/src/models/` | Model definitions | `user.dart` |
| `migrations/` | Database migrations | `20240101_init/` |
| `test/integration/` | Integration tests | `user_endpoint_test.dart` |

### File Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Endpoints | `{name}_endpoint.dart` | `user_endpoint.dart` |
| Models | `{name}.dart` | `user.dart` |
| Tests | `{name}_test.dart` | `user_endpoint_test.dart` |
| Skills | `SKILL.md` | `SKILL.md` |
| References | `{topic}.md` | `endpoints.md` |

---

## Migration Path from Laravel Boost

For developers familiar with Laravel Boost:

| Laravel Boost Concept | ServerPod Boost Equivalent |
|----------------------|---------------------------|
| Artisan Commands | Serverpod CLI Commands |
| Routes | Endpoints |
| Controllers | Endpoints |
| Models | Models (similar) |
| Migrations | Migrations (similar) |
| Blade/Inertia | Flutter (generated client) |
| `php artisan route:list` | `list_endpoints` MCP tool |
| `php artisan migrate` | `run_migrations` MCP tool |
| Config files | YAML config |

---

## Key Features

### 1. Zero-Config Setup

```bash
# One command to set up
serverpod_boost install
```

Automatically detects:
- ServerPod project structure
- Existing endpoints and models
- Database configuration
- Flutter client location

### 2. Skill Versioning

```
.ai/serverpod/1/  # Version 1 of serverpod skills
.ai/serverpod/2/  # Version 2 (can coexist)
```

Allows gradual migration between skill versions.

### 3. Remote Skill Distribution

```yaml
# boost.yaml
skills:
  remote:
    - repo: serverpod/boost-skills
      skills:
        - serverpod-development
        - auth-implementation
        - testing-best-practices
```

Community can share skills via GitHub repositories.

### 4. Context-Aware Guidelines

Guidelines only apply when relevant to current code context:

```dart
// Working on user_endpoint.dart
// → EndpointGuideline applies automatically
// → ModelGuideline does NOT apply (not a model file)
```

### 5. Real-Time Project State

MCP tools provide fresh project state on every request:
- Current endpoints and their methods
- Existing models with field types
- Database schema
- Recent migrations
- Config values

---

## Example Workflows

### Workflow 1: Creating a New Endpoint

```
User: "Create an endpoint for managing blog posts"

AI Process:
1. Activate serverpod-development skill
2. Call list_models (to see if Post model exists)
3. Call get_database_schema (to check posts table)
4. Call list_endpoints (to avoid naming conflicts)
5. Load endpoint_best_practices guideline
6. Generate PostEndpoint with CRUD methods

Result:
- lib/src/endpoints/post_endpoint.dart
- lib/src/models/post.dart (if needed)
- test/integration/post_endpoint_test.dart
```

### Workflow 2: Adding Real-Time Streaming

```
User: "Add real-time chat to the app"

AI Process:
1. Activate serverpod-development and flutter-integration skills
2. Load streaming_guideline
3. Generate ChatEndpoint with messageStream method
4. Generate Flutter widget with StreamSubscription
5. Provide connection handling best practices

Result:
- lib/src/endpoints/chat_endpoint.dart (with stream)
- lib/flutter/widgets/chat_widget.dart (subscribes to stream)
- Documentation on reconnection strategies
```

### Workflow 3: Database Migration

```
User: "Add a publishedAt column to posts table"

AI Process:
1. Activate database-design skill
2. Call get_database_schema (current posts table)
3. Load migration_safety guideline
4. Generate migration file
5. Provide rollback instructions

Result:
- migrations/20240204_add_published_at_to_posts/migration.sql
- Updated Post model in lib/src/models/post.dart
- Instructions to run `serverpod migrator apply`
```

---

## Future Enhancements

### Phase 1 (MVP)
- ✅ Core MCP tools (list, get, validate)
- ✅ Local skills system
- ✅ Basic guideline composers
- ✅ CLI install command

### Phase 2
- ⏳ Remote skills from GitHub
- ⏳ Advanced guideline composers
- ⏳ Code generation tools
- ⏳ Test generation helpers

### Phase 3
- ⏳ AI-powered code review
- ⏳ Automatic refactoring suggestions
- ⏳ Performance analysis tools
- ⏳ Security scanning

### Phase 4
- ⏳ Community skill marketplace
- ⏳ Visual skill editor
- ⏳ Team collaboration features
- ⏳ CI/CD integration

---

## Versioning Strategy

- **Major version**: Breaking changes to API or skill format
- **Minor version**: New features, backward compatible
- **Patch version**: Bug fixes, documentation

Skill versions are independent of package versions:
- Package: `serverpod_boost: ^1.2.0`
- Skills: `.ai/serverpod/1/`, `.ai/serverpod/2/`

---

## License

MIT License - Same as ServerPod

---

## Contributing

ServerPod Boost welcomes contributions:
1. Fork the repository
2. Create a feature branch
3. Follow Dart style guide
4. Add tests for new features
5. Submit pull request

For skill contributions, see `CONTRIBUTING_SKILLS.md`

---

## References

- **ServerPod**: https://docs.serverpod.dev
- **Laravel Boost**: https://github.com/laravel/boost
- **MCP Protocol**: https://modelcontextprotocol.io
- **Dart Language**: https://dart.dev

---

**Document Version**: 1.0.0
**Last Updated**: 2025-02-04
**Maintainer**: ServerPod Boost Team
