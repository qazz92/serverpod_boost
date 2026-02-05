# ServerPod Boost - Architecture Design Summary

## Executive Summary

ServerPod Boost is an AI-acceleration package that enables LLMs to generate high-quality ServerPod code by providing structured context, domain-specific skills, and MCP tools for real-time project state access.

---

## Key Architectural Decisions

### 1. Project Structure

```
serverpod_boost/
├── lib/src/
│   ├── mcp/              # MCP server and tools
│   ├── skills/           # Skills system (local + remote)
│   ├── guidelines/       # Guideline composers
│   ├── cli/              # Command-line interface
│   ├── config/           # Configuration management
│   ├── codegen/          # Code generation helpers
│   └── utils/            # Utilities
├── .ai/                  # AI skill definitions
└── config/               # Default configuration
```

**Decision Rationale:**
- Mirrors Laravel Boost structure for familiarity
- Separates concerns (MCP, Skills, Guidelines, CLI)
- Supports both local and remote skills
- Clear extension points for community contributions

### 2. MCP Tool Design

**Core Principle:** Tools provide READ-ONLY access to project state

| Tool | Purpose | Read-Only |
|------|---------|-----------|
| `list_endpoints` | Discover endpoints | ✓ |
| `list_models` | Discover models | ✓ |
| `get_database_schema` | Get database structure | ✓ |
| `read_logs` | Read logs | ✓ |
| `get_config` | Get configuration | ✓ |
| `run_migrations` | Apply migrations (write) | ✗ |
| `generate_endpoint` | Generate code (write) | ✗ |

**Decision Rationale:**
- Most tools are read-only for safety
- Write operations (`run_migrations`, `generate_*`) are explicit
- Follows Laravel Boost's pattern
- AI cannot accidentally modify project state

### 3. Skills System

**Two Types of Skills:**

1. **Local Skills** - Loaded from `.ai/{domain}/{version}/`
   - Versioned (v1, v2, etc.)
   - Project-specific
   - Immediate availability
   - No network dependency

2. **Remote Skills** - Fetched from GitHub
   - Community contributions
   - Centralized updates
   - Discoverable via registry
   - Can be pinned to specific versions

**Skill Format (SKILL.md):**

```yaml
---
name: serverpod-development
description: Develops ServerPod endpoints, models, and services
triggers:
  - create endpoint
  - serverpod
  - backend
---

# ServerPod Development

## When to Apply
Activate when creating endpoints, models, or working with database operations.

## Documentation
Use `search-docs` for detailed patterns.

## Code Snippets
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

**Decision Rationale:**
- Front matter enables programmatic skill discovery
- Markdown supports both humans and AI
- Code snippets with syntax highlighting
- Trigger keywords for automatic activation
- Reference docs for deep dives

### 4. Guideline System

**Design Philosophy:** Guidelines are context-aware and composable

```dart
abstract class Guideline {
  String get name;
  String get category;
  int get priority;              // Higher = more specific
  bool appliesTo(CodeContext);   // Context check
  Future<String> generate(CodeContext);
}
```

**Example Composers:**
- `EndpointGuideline` - Endpoint best practices
- `ModelGuideline` - Model design patterns
- `MigrationGuideline` - Database migration safety
- `FlutterIntegrationGuideline` - Client integration
- `StreamingGuideline` - Real-time communication

**Decision Rationale:**
- Context-aware (only applies when relevant)
- Composable (multiple guidelines can apply)
- Priority-based (specific guidelines override general ones)
- Dynamic generation (adapts to project state)

### 5. Configuration

**Single File Configuration (boost.yaml):**

```yaml
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
      skills: [serverpod-development, flutter-integration]

guidelines:
  enabled: [endpoint_best_practices, model_design]

codegen:
  endpoint_directory: lib/src/endpoints
  model_directory: lib/src/models
  generate_tests: true
```

**Decision Rationale:**
- YAML familiar to ServerPod developers
- Single source of truth
- Easy to version control
- Supports override via environment variables

---

## Comparison with Laravel Boost

| Aspect | Laravel Boost | ServerPod Boost |
|--------|---------------|-----------------|
| **Language** | PHP | Dart |
| **Package Manager** | Composer | Pub |
| **CLI** | Artisan | Serverpod CLI |
| **Config** | PHP arrays | YAML |
| **Routing** | routes/web.php | Endpoints (typed) |
| **Code Generation** | Stub files | Protocol generation |
| **Client Side** | Blade/Inertia | Flutter (generated) |
| **MCP Tools** | route:list, db:show | list_endpoints, get_database_schema |
| **Skills** | .ai/{domain}/ | .ai/{domain}/{version}/ |
| **Guidelines** | N/A | Composable, context-aware |

**Key Improvements:**
1. **Versioned skills** - Multiple skill versions coexist
2. **Context-aware guidelines** - Only applies when relevant
3. **Type-safe** - Leverages Dart's type system
4. **Flutter integration** - First-class client support
5. **Streaming support** - Real-time communication patterns

---

## Technology Stack

### Core Dependencies

```yaml
# pubspec.yaml
dependencies:
  serverpod: ^2.0.0
  mcp: ^0.5.0              # Model Context Protocol SDK
  yaml: ^3.1.0             # YAML parsing
  http: ^1.2.0             # GitHub API calls
  path: ^1.9.0             # Path manipulation
  recase: ^4.1.0           # String case conversion

dev_dependencies:
  lints: ^3.0.0            # Dart lints
  test: ^1.25.0            # Testing framework
  mockito: ^5.4.0          # Mocking
```

### Optional Dependencies

```yaml
# For advanced features
dependencies:
  analyzer: ^6.0.0         # Code analysis
  code_builder: ^4.5.0     # Code generation
  dart_style: ^2.0.0       # Dart formatting
```

---

## Development Workflow

### Installation

```bash
# 1. Activate package globally
dart pub global activate serverpod_boost

# 2. Install in ServerPod project
cd my_serverpod_project
serverpod_boost install

# 3. Start MCP server (in background)
serverpod_boost mcp:start
```

### Usage by AI

```
User Request → AI Assistant
     ↓
AI identifies relevant skills (serverpod-development)
     ↓
AI calls MCP tools:
  - list_models (to understand data)
  - get_database_schema (to see structure)
  - list_endpoints (to avoid conflicts)
     ↓
AI receives skill context and guidelines
     ↓
AI generates idiomatic ServerPod code
```

### Example: Creating an Endpoint

**User Prompt:** "Create an endpoint to manage blog posts"

**AI Process:**
1. Activates `serverpod-development` skill
2. Calls `list_models` → Discovers `Post` model
3. Calls `get_database_schema` → Sees `posts` table structure
4. Calls `list_endpoints` → Confirms no `PostEndpoint` exists
5. Loads `endpoint_best_practices` guideline
6. Generates code following patterns

**Generated Code:**
```dart
// lib/src/endpoints/post_endpoint.dart
class PostEndpoint extends Endpoint {
  Future<Post?> getPostById(Session session, int postId) async {
    return await Post.db.findFirstRow(
      session,
      where: (p) => p.id.equals(postId),
    );
  }

  Future<List<Post>> getPublishedPosts(Session session) async {
    return await Post.db.find(
      session,
      where: (p) => p.isPublished.equals(true),
      orderBy: (p) => p.publishedAt,
      orderDescending: true,
    );
  }

  Future<Post> createPost(Session session, Post post) async {
    post.createdAt = DateTime.now();
    return await Post.db.insertRow(session, post);
  }
}
```

---

## Phase 1 MVP Scope

### Features
- ✅ Core MCP tools (list, get, validate)
- ✅ Local skills system with versioning
- ✅ Basic guideline composers (endpoint, model)
- ✅ CLI install/setup commands
- ✅ Configuration management

### Not in MVP
- ⏳ Remote skills from GitHub
- ⏳ Advanced guideline composers
- ⏳ Code generation tools
- ⏳ Test generation helpers
- ⏳ Community skill marketplace

---

## Success Metrics

1. **Adoption** - Number of ServerPod projects using Boost
2. **Quality** - Reduction in AI-generated code errors
3. **Speed** - Time saved on common tasks
4. **Community** - Number of community-contributed skills
5. **Satisfaction** - Developer feedback scores

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **AI Hallucination** | High | Read-only MCP tools, validation before code gen |
| **Skill Compatibility** | Medium | Versioned skills, backward compatibility checks |
| **Performance** | Medium | Lazy loading, caching of project state |
| **Maintenance Burden** | High | Community skill contributions, clear documentation |

---

## Future Roadmap

### Phase 2 (Q2 2025)
- Remote skills from GitHub
- Advanced guideline composers
- Code generation tools
- Test generation helpers

### Phase 3 (Q3 2025)
- AI-powered code review
- Automatic refactoring suggestions
- Performance analysis tools
- Security scanning

### Phase 4 (Q4 2025)
- Community skill marketplace
- Visual skill editor
- Team collaboration features
- CI/CD integration

---

## References

- **Full Architecture**: [ARCHITECTURE.md](./ARCHITECTURE.md)
- **ServerPod Docs**: https://docs.serverpod.dev
- **Laravel Boost**: https://github.com/laravel/boost
- **MCP Protocol**: https://modelcontextprotocol.io

---

**Document Version**: 1.0.0
**Last Updated**: 2025-02-04
**Status**: Design Complete - Ready for Implementation
