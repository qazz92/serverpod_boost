# ServerPod Boost - Architecture Diagrams

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           AI Assistant                                   │
│                        (Claude, GPT, etc.)                               │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                │ MCP Protocol
                                │ (localhost:8081)
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        ServerPod Boost                                  │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                     MCP Server                                 │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │  ┌──────────────────────────────────────────────────────────┐ │    │
│  │  │              Tool Registry                               │ │    │
│  │  │  - list_endpoints                                        │ │    │
│  │  │  - list_models                                           │ │    │
│  │  │  - get_database_schema                                   │ │    │
│  │  │  - run_migrations                                        │ │    │
│  │  │  - read_logs                                             │ │    │
│  │  │  - get_config                                            │ │    │
│  │  │  - search_docs                                           │ │    │
│  │  │  - validate_endpoint                                     │ │    │
│  │  │  - generate_endpoint                                     │ │    │
│  │  │  - generate_model                                        │ │    │
│  │  └──────────────────────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                    Skills Manager                              │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │  ┌─────────────────┐  ┌──────────────────────────────────┐   │    │
│  │  │   Local Skills  │  │       Remote Skills              │   │    │
│  │  ├─────────────────┤  ├──────────────────────────────────┤   │    │
│  │  │ • serverpod-    │  │ • serverpod/boost-skills         │   │    │
│  │  │   development   │  │ • community/skills               │   │    │
│  │  │ • flutter-      │  │                                 │   │    │
│  │  │   integration   │  │                                 │   │    │
│  │  │ • database-     │  │                                 │   │    │
│  │  │   design        │  │                                 │   │    │
│  │  │ • auth-         │  │                                 │   │    │
│  │  │   implementation│  │                                 │   │    │
│  │  └─────────────────┘  └──────────────────────────────────┘   │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                 Guideline System                               │    │
│  ├────────────────────────────────────────────────────────────────┤    │
│  │  ┌──────────────────────────────────────────────────────────┐ │    │
│  │  │              Guideline Composers                         │ │    │
│  │  ├──────────────────────────────────────────────────────────┤ │    │
│  │  │ • EndpointGuideline      (endpoint_best_practices)       │ │    │
│  │  │ • ModelGuideline         (model_design)                  │ │    │
│  │  │ • MigrationGuideline     (migration_safety)              │ │    │
│  │  │ • FlutterIntegration     (flutter_client_patterns)       │ │    │
│  │  │ • StreamingGuideline     (realtime_streams)              │ │    │
│  │  │ • TestingGuideline       (testing_best_practices)        │ │    │
│  │  │ • AuthenticationGuideline (auth_implementation)          │ │    │
│  │  └──────────────────────────────────────────────────────────┘ │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │                   Configuration                                │    │
│  │  (boost.yaml)                                                  │    │
│  │  - MCP settings                                                │    │
│  │  - Skill sources                                               │    │
│  │  - Enabled guidelines                                          │    │
│  │  - Code generation preferences                                 │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                │ Project Access
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      ServerPod Project                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────┐ │
│  │   lib/src/          │  │    migrations/      │  │   config/       │ │
│  ├─────────────────────┤  ├─────────────────────┤  ├─────────────────┤ │
│  │ • endpoints/        │  │ • 20240101_init/   │  │ • generator.yaml│ │
│  │ • models/           │  │ • 20240102_.../     │  │ • passwords.yaml│ │
│  │ • generated/        │  │                     │  │ • config.yaml   │ │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────┘ │
│                                                                          │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                     Database (PostgreSQL)                        │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow: User Request to Generated Code

```
┌─────────────────────────────────────────────────────────────────────────┐
│ Step 1: User Request                                                     │
│                                                                          │
│  "Create an endpoint to manage blog posts with CRUD operations"         │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Step 2: AI Analyzes Request                                              │
│                                                                          │
│  • Detects keywords: "endpoint", "blog posts", "CRUD"                    │
│  • Identifies domain: ServerPod backend                                 │
│  • Activates skills: serverpod-development                              │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Step 3: Skill Activation                                                 │
│                                                                          │
│  Active Skills:                                                          │
│  ✓ serverpod-development (matched: "endpoint", "CRUD")                   │
│  ✓ database-design (matched: "CRUD" implies database operations)        │
│  ✗ flutter-integration (not matched: no client mention)                 │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Step 4: MCP Tool Calls (Parallel)                                        │
│                                                                          │
│  1. list_models → Checks if Post model exists                            │
│  2. get_database_schema → Gets posts table structure                     │
│  3. list_endpoints → Checks for existing PostEndpoint                    │
│  4. get_config → Gets project configuration                              │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Step 5: Context Assembly                                                 │
│                                                                          │
│  From Skills:                                                            │
│  • serverpod-development/SKILL.md → Endpoint patterns, ORM usage         │
│  • database-design/SKILL.md → Migration patterns, validation            │
│                                                                          │
│  From Guidelines:                                                        │
│  • endpoint_best_practices → Session handling, error handling            │
│  • model_design → Field naming, types, relationships                     │
│                                                                          │
│  From MCP Tools:                                                         │
│  • Post model: id, title, content, authorId, createdAt, isPublished     │
│  • posts table: Schema matches model                                    │
│  • No existing PostEndpoint → Safe to create                            │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Step 6: Code Generation                                                  │
│                                                                          │
│  AI generates idiomatic ServerPod code:                                  │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  lib/src/endpoints/post_endpoint.dart                           │    │
│  │  ─────────────────────────────────────────────────────────────  │    │
│  │  class PostEndpoint extends Endpoint {                           │    │
│  │    // CREATE                                                      │    │
│  │    Future<Post> createPost(Session session, Post post) async {   │    │
│  │      post.createdAt = DateTime.now();                             │    │
│  │      return await Post.db.insertRow(session, post);               │    │
│  │    }                                                               │    │
│  │                                                                    │    │
│  │    // READ                                                         │    │
│  │    Future<Post?> getPostById(Session session, int id) async {     │    │
│  │      return await Post.db.findById(session, id);                  │    │
│  │    }                                                               │    │
│  │                                                                    │    │
│  │    // UPDATE                                                       │    │
│  │    Future<Post> updatePost(Session session, Post post) async {    │    │
│  │      return await Post.db.updateRow(session, post);               │    │
│  │    }                                                               │    │
│  │                                                                    │    │
│  │    // DELETE                                                       │    │
│  │    Future<void> deletePost(Session session, int id) async {       │    │
│  │      await Post.db.delete(session, where: (p) => p.id.equals(id));│    │
│  │    }                                                               │    │
│  │  }                                                                 │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  test/integration/post_endpoint_test.dart                       │    │
│  │  ─────────────────────────────────────────────────────────────  │    │
│  │  void main() {                                                   │    │
│  │    withServerpod('PostEndpoint', (sessionBuilder, endpoints) {   │    │
│  │      test('createPost creates a new post', () async { ... });    │    │
│  │      test('getPostById returns the post', () async { ... });     │    │
│  │    });                                                            │    │
│  │  }                                                                 │    │
│  └────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Skill Loading Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                   Skill Manager Initialization                           │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Load Local Skills                                                        │
│                                                                          │
│  .ai/serverpod/1/skill/serverpod-development/SKILL.md                   │
│  .ai/flutter/1/skill/flutter-integration/SKILL.md                       │
│  .ai/database/1/skill/database-design/SKILL.md                          │
│  .ai/auth/1/skill/auth-implementation/SKILL.md                          │
│  .ai/testing/1/skill/testing-best-practices/SKILL.md                    │
│                                                                          │
│  Each skill includes:                                                    │
│  • YAML front matter (name, description, triggers)                      │
│  • Markdown content (when to apply, patterns, code snippets)            │
│  • Reference docs in reference/ subdirectory                            │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Load Remote Skills (Optional)                                           │
│                                                                          │
│  boost.yaml:                                                            │
│    skills:                                                              │
│      remote:                                                            │
│        - repo: serverpod/boost-skills                                   │
│          skills: [serverpod-development, ...]                           │
│                                                                          │
│  Fetch from GitHub:                                                     │
│  • GET /repo/serverpod/boost-skills/contents/skills/{name}/{version}    │
│  • Parse SKILL.md from each skill                                       │
│  • Cache locally for offline use                                        │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Skill Registry                                                           │
│                                                                          │
│  Available Skills:                                                       │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  serverpod-development                                          │    │
│  │  triggers: [endpoint, model, serverpod, backend, api]           │    │
│  │  version: 1                                                     │    │
│  │  source: local                                                 │    │
│  └────────────────────────────────────────────────────────────────┘    │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  flutter-integration                                           │    │
│  │  triggers: [flutter, client, streaming, realtime]              │    │
│  │  version: 1                                                     │    │
│  │  source: local                                                 │    │
│  └────────────────────────────────────────────────────────────────┘    │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  database-design                                               │    │
│  │  triggers: [migration, database, schema, sql]                  │    │
│  │  version: 1                                                     │    │
│  │  source: local                                                 │    │
│  └────────────────────────────────────────────────────────────────┘    │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Skill Activation (When Request Received)                                │
│                                                                          │
│  User Request: "Create a chat endpoint with real-time messaging"        │
│                                                                          │
│  Matching Skills:                                                        │
│  ✓ serverpod-development (matches: "endpoint", "messaging")             │
│  ✓ flutter-integration (matches: "real-time", "messaging")              │
│  ✗ database-design (no match)                                           │
│  ✗ auth-implementation (no match)                                       │
│                                                                          │
│  Active Skills: [serverpod-development, flutter-integration]            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Guideline Application Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    Code Context Analysis                                 │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Analyze Current File                                                     │
│                                                                          │
│  File: lib/src/endpoints/user_endpoint.dart                             │
│  Class: UserEndpoint                                                     │
│  Type: Endpoint                                                          │
│  Imports: [serverpod, generated protocol]                               │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Check Guideline Applicability                                            │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  EndpointGuideline                                             │    │
│  │  appliesTo(): fileType == Endpoint ✓                           │    │
│  │  priority: 100                                                 │    │
│  │  status: ACTIVE                                                │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  ModelGuideline                                                │    │
│  │  appliesTo(): fileType == Model ✗                              │    │
│  │  priority: 90                                                  │    │
│  │  status: INACTIVE                                              │    │
│  └────────────────────────────────────────────────────────────────┘    │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────┐    │
│  │  TestingGuideline                                               │    │
│  │  appliesTo(): always true ✓                                    │    │
│  │  priority: 50 (general)                                         │    │
│  │  status: ACTIVE (but lower priority than EndpointGuideline)    │    │
│  └────────────────────────────────────────────────────────────────┘    │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Generate Active Guidelines (Priority Order)                              │
│                                                                          │
│  1. EndpointGuideline (priority: 100)                                   │
│     • Session parameter handling                                        │
│     • ORM method usage                                                   │
│     • Error handling patterns                                            │
│     • Logging conventions                                                │
│                                                                          │
│  2. TestingGuideline (priority: 50)                                     │
│     • Test structure with withServerpod                                  │
│     • Session builder usage                                              │
│     • Endpoint testing patterns                                          │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ Combine with Skills and Provide to AI                                    │
│                                                                          │
│  Active Skills: [serverpod-development]                                  │
│  Active Guidelines: [EndpointGuideline, TestingGuideline]               │
│  MCP Tools: [list_models, get_database_schema, list_endpoints]          │
│                                                                          │
│  → AI has complete context for endpoint development                     │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## MCP Tool Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        MCP Server                                        │
│                     (localhost:8081)                                     │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    Tool Registry                                         │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        │                       │                       │
        ▼                       ▼                       ▼
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  Discovery    │     │   Inspector   │     │  Generator    │
│   Tools       │     │    Tools      │     │    Tools      │
├───────────────┤     ├───────────────┤     ├───────────────┤
│list_endpoints │     │get_database   │     │generate_      │
│list_models    │     │_schema        │     │endpoint       │
│list_migrations│     │read_logs      │     │generate_model │
│get_config     │     │validate_      │     │generate_      │
│               │     │endpoint       │     │migration      │
└───────────────┘     └───────────────┘     └───────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                     ServerPod Project                                    │
│                                                                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
│  │  Endpoints      │  │   Models        │  │   Database      │        │
│  │  (read)         │  │   (read)        │  │   (read)        │        │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘        │
│                                                                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
│  │  Migrations     │  │   Logs          │  │   Config        │        │
│  │  (read/write)   │  │   (read)        │  │   (read)        │        │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘        │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Installation Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│ User executes: dart pub global activate serverpod_boost                  │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ServerPod Boost installed globally                                       │
│  • Binary: ~/.pub-cache/bin/serverpod_boost                             │
│  • Version: 1.0.0                                                       │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ User navigates to ServerPod project: cd my_serverpod_project            │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ User executes: serverpod_boost install                                   │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ ServerPod Boost Installer                                                │
├─────────────────────────────────────────────────────────────────────────┤
│  1. Detect ServerPod project structure                                   │
│     ✓ Found: lib/src/endpoints/                                         │
│     ✓ Found: lib/src/models/                                            │
│     ✓ Found: migrations/                                                │
│     ✓ Found: config/generator.yaml                                      │
│                                                                          │
│  2. Create .ai/ directory structure                                      │
│     ✓ Created: .ai/serverpod/1/skill/serverpod-development/             │
│     ✓ Created: .ai/flutter/1/skill/flutter-integration/                 │
│     ✓ Created: .ai/database/1/skill/database-design/                    │
│     ✓ Created: .ai/auth/1/skill/auth-implementation/                    │
│     ✓ Created: .ai/testing/1/skill/testing-best-practices/              │
│                                                                          │
│  3. Copy default skills from package                                    │
│     ✓ Copied: SKILL.md for each domain                                  │
│     ✓ Copied: reference/ documentation for each domain                  │
│                                                                          │
│  4. Generate boost.yaml configuration                                   │
│     ✓ Created: boost.yaml with default settings                         │
│     ✓ Detected: serverpod_project_path                                  │
│                                                                          │
│  5. Update .claude/CLAUDE.md (if exists)                                │
│     ✓ Added: MCP server connection info                                 │
│     ✓ Added: Available skills description                               │
│                                                                          │
│  6. Initialize Git                                                      │
│     ✓ Added: .ai/ to .gitignore (optional, prompts user)                │
│                                                                          │
│  Installation complete!                                                  │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ User starts MCP server: serverpod_boost mcp:start                        │
└───────────────────────────────┬─────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ MCP Server Running                                                       │
│  • Listening on: localhost:8081                                         │
│  • Loaded skills: 5                                                     │
│  • Registered tools: 11                                                 │
│  • Ready for AI connections                                             │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Component Interaction Matrix

| Component | MCP Server | Skills | Guidelines | Config | Project |
|-----------|------------|--------|------------|--------|---------|
| **MCP Server** | - | Loads skill context | Loads guidelines | Reads settings | Reads/Writes |
| **Skills** | Provides context | - | Provides patterns | N/A | Reads (via tools) |
| **Guidelines** | Provides best practices | Uses skill patterns | - | Reads enabled list | Reads (via tools) |
| **Config** | Provides connection info | N/A | N/A | - | Validates paths |
| **Project** | State source | N/A | N/A | N/A | - |

---

## Data Structures

### MCP Tool Request/Response

```dart
// Request
class ToolRequest {
  final String toolName;
  final Map<String, dynamic> params;
}

// Response
class ToolResponse {
  final dynamic data;
  final bool success;
  final String? error;
}
```

### Skill Metadata

```dart
class SkillMetadata {
  final String name;
  final String description;
  final List<String> triggers;
  final int version;
  final SkillSource source;  // local or remote
  final String? repository;   // for remote skills
}
```

### Guideline Context

```dart
class CodeContext {
  final String filePath;
  final FileType fileType;
  final String? currentClass;
  final List<String> imports;
  final List<String> activeSkills;
}
```

---

## Extension Points

### Adding a New MCP Tool

```dart
// 1. Create tool class
class MyCustomTool extends Tool {
  @override
  String get name => 'my_custom_tool';

  @override
  String get description => 'Does something custom';

  @override
  Map<String, dynamic> get schema => {
    'param': {'type': 'string'},
  };

  @override
  Future<Response> handle(Request request) async {
    // Implementation
  }
}

// 2. Register in tool_registry.dart
registry.registerTool('my_custom_tool', MyCustomTool());
```

### Adding a New Guideline Composer

```dart
// 1. Create composer class
class MyCustomGuideline extends Guideline {
  @override
  String get name => 'my_custom_guideline';

  @override
  String get category => 'custom';

  @override
  int get priority => 75;

  @override
  bool appliesTo(CodeContext context) {
    return context.fileType == FileType.custom;
  }

  @override
  Future<String> generate(CodeContext context) async {
    return '''
## Custom Guideline
Follow these patterns...
''';
  }
}

// 2. Register in guideline_loader.dart
guidelines.add(MyCustomGuideline());
```

### Adding a New Local Skill

```bash
# 1. Create skill directory
mkdir -p .ai/my_domain/1/skill/my_skill

# 2. Create SKILL.md
cat > .ai/my_domain/1/skill/my_skill/SKILL.md << 'EOF'
---
name: my_skill
description: My custom skill
triggers:
  - my_trigger
---

# My Skill

## When to Apply
Activate when user mentions "my_trigger".

## Patterns
...
EOF

# 3. Restart MCP server
serverpod_boost mcp:restart
```

---

**Document Version**: 1.0.0
**Last Updated**: 2025-02-04
