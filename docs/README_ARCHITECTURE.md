# ServerPod Boost - Complete Architecture Package

## Summary

This document serves as an index to the complete ServerPod Boost architecture design. ServerPod Boost is an AI-acceleration package for ServerPod applications, inspired by Laravel Boost, designed to help LLMs generate high-quality, idiomatic ServerPod code.

---

## Document Structure

| Document | Purpose | Audience |
|----------|---------|----------|
| **README_ARCHITECTURE.md** (this file) | Overview and index | All |
| **ARCHITECTURE.md** | Complete technical architecture | Architects, developers |
| **DESIGN_SUMMARY.md** | Executive summary and decisions | Stakeholders, PMs |
| **DIAGRAMS.md** | Visual system diagrams | Visual learners |
| **AGENTS.md** | AI assistant usage guide | AI assistants, users |

---

## Quick Reference

### Project Purpose

ServerPod Boost provides AI assistants with:
- **Context** - Real-time project state via MCP tools
- **Knowledge** - Domain-specific skills for common patterns
- **Guidance** - Context-aware best practice guidelines
- **Safety** - Read-only project inspection (mostly)

### Key Components

```
ServerPod Boost
├── MCP Server (11 tools for project inspection)
├── Skills System (5 core domains + community)
├── Guideline System (8 context-aware composers)
└── CLI (install, configure, manage)
```

### Technology Stack

- **Language**: Dart 3.0+
- **Framework**: ServerPod 2.0+
- **Protocol**: MCP (Model Context Protocol)
- **Config**: YAML
- **Package Manager**: Pub

### File Locations

| File/Directory | Purpose |
|----------------|---------|
| `ARCHITECTURE.md` | Complete technical design |
| `DESIGN_SUMMARY.md` | Executive summary |
| `DIAGRAMS.md` | System diagrams |
| `AGENTS.md` | AI usage guide |
| `.ai/` | Local skill definitions |
| `boost.yaml` | Configuration |

---

## Architecture Highlights

### 1. MCP Tools (11 total)

**Discovery Tools:**
- `list_endpoints` - List all endpoints
- `list_models` - List all models
- `list_migrations` - List migrations
- `get_config` - Get configuration

**Inspection Tools:**
- `get_database_schema` - Database structure
- `read_logs` - ServerPod logs
- `validate_endpoint` - Validate endpoint code

**Generator Tools:**
- `generate_endpoint` - Create endpoint stub
- `generate_model` - Create model stub
- `generate_migration` - Create migration file

**Utility Tools:**
- `search_docs` - Search documentation
- `run_migrations` - Apply migrations (write operation)

### 2. Skills (5 Core Domains)

| Skill | Triggers | Purpose |
|-------|----------|---------|
| **serverpod-development** | endpoint, model, serverpod, backend | Core ServerPod patterns |
| **flutter-integration** | flutter, client, streaming | Client-side integration |
| **database-design** | migration, database, schema | Database operations |
| **auth-implementation** | auth, login, oauth | Authentication |
| **testing-best-practices** | test, testing, spec | Test patterns |

### 3. Guidelines (8 Composers)

| Guideline | Priority | When Active |
|-----------|----------|-------------|
| EndpointGuideline | 100 | In endpoint files |
| ModelGuideline | 95 | In model files |
| MigrationGuideline | 90 | In migration files |
| StreamingGuideline | 85 | With streaming methods |
| FlutterIntegrationGuideline | 80 | With Flutter integration |
| AuthenticationGuideline | 75 | With auth code |
| TestingGuideline | 50 | Always (general) |
| SecurityGuideline | 70 | With sensitive data |

---

## Comparison: Laravel Boost vs ServerPod Boost

| Aspect | Laravel Boost | ServerPod Boost |
|--------|---------------|-----------------|
| **Language** | PHP | Dart |
| **CLI** | Artisan | Serverpod CLI |
| **Config** | PHP arrays | YAML |
| **Routing** | routes/web.php | Endpoints (typed) |
| **Client** | Blade/Inertia | Flutter (generated) |
| **Skills** | `.ai/{domain}/` | `.ai/{domain}/{version}/` |
| **Guidelines** | Static | Context-aware, dynamic |
| **MCP Tools** | ~8 tools | 11 tools |
| **Streaming** | No | Yes (WebSocket) |

---

## Installation

```bash
# 1. Install globally
dart pub global activate serverpod_boost

# 2. Install in project
cd my_serverpod_project
serverpod_boost install

# 3. Start MCP server
serverpod_boost mcp:start
```

**Result:**
- `.ai/` directory created with 5 core skills
- `boost.yaml` configuration file generated
- MCP server running on `localhost:8081`
- AI assistant can now access project context

---

## Usage Example

**User Request:**
> "Create an endpoint for managing blog posts with CRUD operations"

**AI Process:**
1. Activates `serverpod-development` skill (matched: "endpoint", "CRUD")
2. Activates `database-design` skill (matched: "CRUD")
3. Calls MCP tools:
   - `list_models` → Finds `Post` model
   - `get_database_schema` → Gets `posts` table structure
   - `list_endpoints` → Confirms no `PostEndpoint` exists
4. Loads guidelines:
   - `EndpointGuideline` → ORM patterns, error handling
   - `TestingGuideline` → Test structure
5. Generates code following ServerPod conventions

**Generated Code:**
```dart
// lib/src/endpoints/post_endpoint.dart
class PostEndpoint extends Endpoint {
  Future<Post?> getPostById(Session session, int id) async {
    return await Post.db.findById(session, id);
  }

  Future<Post> createPost(Session session, Post post) async {
    post.createdAt = DateTime.now();
    return await Post.db.insertRow(session, post);
  }

  Future<Post> updatePost(Session session, Post post) async {
    return await Post.db.updateRow(session, post);
  }

  Future<void> deletePost(Session session, int id) async {
    await Post.db.delete(session, where: (p) => p.id.equals(id));
  }
}
```

---

## Key Design Decisions

### 1. Read-First MCP Tools
- **Decision**: Most tools are read-only
- **Rationale**: Prevent accidental modifications
- **Exception**: `run_migrations`, `generate_*` (explicit write ops)

### 2. Versioned Skills
- **Decision**: Skills have version numbers (`v1`, `v2`)
- **Rationale**: Allow gradual migration between versions
- **Benefit**: Multiple versions can coexist

### 3. Context-Aware Guidelines
- **Decision**: Guidelines only apply when relevant
- **Rationale**: Reduce noise, improve relevance
- **Mechanism**: `appliesTo(CodeContext)` check

### 4. Remote Skills
- **Decision**: Support fetching skills from GitHub
- **Rationale**: Community contributions, centralized updates
- **Fallback**: Local skills always available

### 5. Single Config File
- **Decision**: One `boost.yaml` file
- **Rationale**: Simple, versionable, easy to manage
- **Override**: Environment variables supported

---

## Roadmap

### Phase 1: MVP (Current)
- ✅ Core MCP tools (11 tools)
- ✅ Local skills system (5 domains)
- ✅ Basic guidelines (8 composers)
- ✅ CLI install/setup

### Phase 2: Enhancement
- ⏳ Remote skills from GitHub
- ⏳ Advanced guideline composers
- ⏳ Code generation tools
- ⏳ Test generation helpers

### Phase 3: Intelligence
- ⏳ AI-powered code review
- ⏳ Automatic refactoring suggestions
- ⏳ Performance analysis tools
- ⏳ Security scanning

### Phase 4: Community
- ⏳ Skill marketplace
- ⏳ Visual skill editor
- ⏳ Team collaboration features
- ⏳ CI/CD integration

---

## Project Structure

```
serverpod_boost/
├── lib/src/
│   ├── mcp/              # MCP server & 11 tools
│   ├── skills/           # Local + remote skills
│   ├── guidelines/       # 8 guideline composers
│   ├── cli/              # CLI commands
│   ├── config/           # Configuration management
│   ├── codegen/          # Code generation helpers
│   └── utils/            # Utilities
│
├── .ai/                  # Local skill definitions
│   ├── serverpod/1/
│   ├── flutter/1/
│   ├── database/1/
│   ├── auth/1/
│   └── testing/1/
│
├── config/               # Default configuration
│   └── boost.yaml
│
├── test/                 # Tests
│   ├── unit/
│   └── integration/
│
├── ARCHITECTURE.md       # Complete technical design
├── DESIGN_SUMMARY.md     # Executive summary
├── DIAGRAMS.md           # Visual diagrams
├── AGENTS.md             # AI usage guide
└── README_ARCHITECTURE.md # This file
```

---

## Extension Points

### Add MCP Tool
```dart
class MyTool extends Tool {
  // Implement name, description, schema, handle
}
// Register in tool_registry.dart
```

### Add Guideline
```dart
class MyGuideline extends Guideline {
  // Implement name, category, priority, appliesTo, generate
}
// Register in guideline_loader.dart
```

### Add Local Skill
```bash
mkdir -p .ai/my_domain/1/skill/my_skill
# Create SKILL.md with front matter and content
```

---

## Dependencies

```yaml
dependencies:
  serverpod: ^2.0.0
  mcp: ^0.5.0
  yaml: ^3.1.0
  http: ^1.2.0
  path: ^1.9.0
  recase: ^4.1.0

dev_dependencies:
  lints: ^3.0.0
  test: ^1.25.0
  mockito: ^5.4.0
```

---

## Contributing

1. Fork repository
2. Create feature branch
3. Follow Dart style guide
4. Add tests
5. Submit PR

For skill contributions, see `CONTRIBUTING_SKILLS.md`

---

## License

MIT License - Same as ServerPod

---

## References

- **ServerPod**: https://docs.serverpod.dev
- **Laravel Boost**: https://github.com/laravel/boost
- **MCP Protocol**: https://modelcontextprotocol.io
- **Dart Language**: https://dart.dev

---

## Document Metadata

| Document | Version | Last Updated |
|----------|---------|--------------|
| README_ARCHITECTURE.md | 1.0.0 | 2025-02-04 |
| ARCHITECTURE.md | 1.0.0 | 2025-02-04 |
| DESIGN_SUMMARY.md | 1.0.0 | 2025-02-04 |
| DIAGRAMS.md | 1.0.0 | 2025-02-04 |
| AGENTS.md | 1.0.0 | 2025-02-04 |

---

## Status

**Current Phase**: Design Complete
**Next Steps**: Implementation of Phase 1 MVP
**Target Release**: Q2 2025

---

**Maintainer**: ServerPod Boost Team
**Contact**: Via GitHub Issues
