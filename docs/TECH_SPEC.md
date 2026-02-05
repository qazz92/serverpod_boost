# ServerPod Boost - Technical Specification

## Executive Summary

ServerPod Boost is an MCP (Model Context Protocol) server implementation for ServerPod v3, inspired by Laravel Boost. It provides AI assistants with deep context awareness of ServerPod projects, enabling high-quality code generation through semantic understanding of endpoints, protocols, database schemas, configurations, and project structure.

**Reference Projects:**
- Laravel Boost: `/Users/musinsa/always_summer/boost`
- ServerPod: `/Users/musinsa/always_summer/serverpod`
- Test Target: `/Users/musinsa/always_summer/pilly`

---

## 1. Tech Stack

### 1.1 Core Technologies

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **Dart** | ^3.8.0 | Primary language | Matches ServerPod v3 requirement, pure Dart implementation (no external dependencies) |
| **ServerPod** | 3.2.3 | Server framework | Target framework for boost integration |
| **MCP Protocol** | Latest | AI communication | Standard for AI assistant communication (via stdio) |
| **YAML** | ^3.1.2 | Configuration parsing | ServerPod uses YAML for config files |
| **path** | ^1.8.3 | File path operations | Cross-platform path handling |

### 1.2 Why Pure Dart?

Following Laravel Boost's architecture (pure PHP implementation):
- **Simplicity**: No external runtime dependencies
- **Performance**: Native Dart execution without bridge overhead
- **Compatibility**: Seamless integration with ServerPod projects
- **Maintainability**: Single language throughout the stack

### 1.3 MCP Implementation Strategy

Unlike Laravel Boost which uses `laravel/mcp` package, ServerPod Boost will implement:
- **MCP Protocol directly** via stdio (JSON-RPC 2.0)
- **Tool Registry pattern** for automatic tool discovery
- **Subprocess execution** for isolated tool execution
- **Response serialization** matching MCP specification

---

## 2. Architecture Overview

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AI Assistant (Claude)                     │
└────────────────────────┬────────────────────────────────────┘
                         │ stdio (JSON-RPC 2.0)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  ServerPod Boost (MCP Server)                │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Boost.dart (Main Entry)                  │   │
│  │  - Tool Registry                                      │   │
│  │  - Resource Registry                                  │   │
│  │  - Prompt Registry                                    │   │
│  └────────────┬─────────────────────────────────────────┘   │
│               │                                               │
│  ┌────────────▼─────────────────────────────────────────┐   │
│  │            ToolExecutor (Isolated Execution)          │   │
│  └────────────┬─────────────────────────────────────────┘   │
└───────────────┼───────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│                    ServerPod Project                          │
│  - Endpoints (lib/src/)                                       │
│  - Protocol (lib/src/generated/)                              │
│  - Config (config/*.yaml)                                     │
│  - Migrations (migrations/)                                   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Component Architecture

```
serverpod_boost/
├── lib/
│   ├── boost.dart                    # Main MCP server entry point
│   ├── tool_executor.dart            # Isolated tool execution
│   ├── tool_registry.dart            # Tool discovery & registration
│   ├── mcp/
│   │   ├── protocol.dart             # MCP protocol implementation
│   │   ├── server.dart               # Base MCP server class
│   │   └── transport.dart            # stdio transport layer
│   ├── tools/                        # MCP tool implementations
│   │   ├── application_info.dart
│   │   ├── list_endpoints.dart
│   │   ├── database_schema.dart
│   │   ├── protocol_inspector.dart
│   │   ├── config_reader.dart
│   │   ├── migration_scanner.dart
│   │   └── project_structure.dart
│   ├── resources/                    # MCP resource implementations
│   └── prompts/                      # MCP prompt templates
└── bin/
    └── boost.dart                    # CLI entry point
```

### 2.3 Data Flow

```
1. AI sends request via stdio
   ↓
2. Boost.dart receives JSON-RPC request
   ↓
3. ToolRegistry resolves tool class
   ↓
4. ToolExecutor spawns isolated Dart process
   ↓
5. Tool executes with Serverpod project access
   ↓
6. Response serialized to MCP format
   ↓
7. Response sent via stdio to AI
```

---

## 3. File Structure

### 3.1 Installation Location

ServerPod Boost installs to: `{project_root}/.ai/boost/`

Example for Pilly project:
```
/Users/musinsa/always_summer/pilly/.ai/boost/
├── bin/
│   └── boost.dart                   # Executable entry point
├── lib/
│   └── (source files)
├── pubspec.yaml
└── analysis_options.yaml
```

### 3.2 Complete Directory Structure

```
serverpod_boost/
├── bin/
│   └── boost.dart                    # CLI entry point
├── lib/
│   ├── boost.dart                    # Main MCP server
│   ├── boost_exception.dart          # Custom exceptions
│   ├── tool_executor.dart            # Subprocess execution
│   ├── tool_registry.dart            # Tool discovery
│   ├── mcp/
│   │   ├── mcp_protocol.dart         # MCP protocol types
│   │   ├── mcp_server.dart           # Base server class
│   │   ├── mcp_transport.dart        # stdio transport
│   │   ├── mcp_request.dart          # Request wrapper
│   │   ├── mcp_response.dart         # Response wrapper
│   │   └── mcp_tool.dart             # Base tool interface
│   ├── tools/
│   │   ├── tools.dart                # Tool export barrel
│   │   ├── application_info.dart     # Project metadata
│   │   ├── endpoints/
│   │   │   ├── list_endpoints.dart   # List all endpoints
│   │   │   ├── endpoint_methods.dart # Get endpoint methods
│   │   │   └── call_endpoint.dart    # Call endpoint (testing)
│   │   ├── protocol/
│   │   │   ├── list_models.dart      # List protocol models
│   │   │   ├── model_inspector.dart  # Model field details
│   │   │   └── enum_inspector.dart   # Enum definitions
│   │   ├── database/
│   │   │   ├── schema_reader.dart    # Database schema
│   │   │   ├── migration_scanner.dart # Migration files
│   │   │   └── table_info.dart       # Table structure
│   │   ├── config/
│   │   │   ├── config_reader.dart    # Read yaml configs
│   │   │   ├── env_vars.dart         # Environment variables
│   │   │   └── service_config.dart   # Service config
│   │   └── project/
│   │       ├── project_structure.dart # File tree
│   │       ├── find_files.dart       # File search
│   │       └── read_file.dart        # File content
│   ├── resources/
│   │   └── resources.dart
│   └── prompts/
│       └── prompts.dart
├── test/
│   ├── unit/
│   └── integration/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

### 3.3 ServerPod Integration Points

```
pilly_server/
├── lib/
│   ├── server.dart                   # Server entry point
│   ├── src/
│   │   ├── generated/                # Auto-generated
│   │   │   ├── endpoints.dart
│   │   │   ├── protocol.dart
│   │   │   └── (endpoint files)
│   │   └── (user endpoints)
│   └── (user models)
├── config/
│   ├── development.yaml
│   ├── production.yaml
│   ├── passwords.yaml
│   └── generator.yaml
├── migrations/
│   └── (migration files)
├── web/
│   ├── static/
│   └── app/
└── .ai/
    └── boost/                        # Boost installation
        ├── bin/boost
        └── lib/
```

---

## 4. Dependencies

### 4.1 Production Dependencies

```yaml
# pubspec.yaml
name: serverpod_boost
version: 0.1.0
description: ServerPod Boost - MCP server for AI-assisted ServerPod development
environment:
  sdk: '^3.8.0'

dependencies:
  # MCP Protocol (via stdio - no external MCP package)
  # We'll implement JSON-RPC 2.0 directly

  # ServerPod
  serverpod: ^3.2.3

  # YAML Parsing (ServerPod config)
  yaml: ^3.1.2

  # File Operations
  path: ^1.8.3

  # Process Execution (for tool isolation)
  # No package needed - use Dart's Process class

dev_dependencies:
  lints: ^3.0.0
  test: ^1.25.5
```

### 4.2 Why No MCP Package?

Unlike Laravel Boost which uses `laravel/mcp`, ServerPod Boost will implement MCP protocol directly because:
- No official Dart MCP package exists
- MCP protocol is simple (JSON-RPC 2.0 over stdio)
- Full control over implementation
- Zero external dependencies

---

## 5. MCP Tools Specification

### 5.1 Core Tool Interface

```dart
/// Base interface for all MCP tools
abstract class McpTool {
  /// Tool name (must be unique)
  String get name;

  /// Tool description for AI
  String get description;

  /// Input schema (JSON Schema format)
  Map<String, dynamic> get inputSchema;

  /// Execute the tool
  Future<McpResponse> execute(McpRequest request);
}
```

### 5.2 Tool Registry

```dart
/// Automatic tool discovery and registration
class ToolRegistry {
  /// Discover all tools in the tools/ directory
  static List<McpTool> discoverTools();

  /// Check if tool is allowed to execute
  static bool isToolAllowed(String toolName);

  /// Get tool by name
  static McpTool? getTool(String name);

  /// List all available tool names
  static List<String> getToolNames();
}
```

### 5.3 Tool List (Priority Order)

#### Tier 1: Essential Tools (Must Have)

| Tool Name | Description | Input | Output |
|-----------|-------------|-------|--------|
| **application_info** | Get project info (ServerPod version, Dart version, endpoints, models) | None | JSON with metadata |
| **list_endpoints** | List all endpoints in the project | filter: string? | List of endpoint names and paths |
| **endpoint_methods** | Get methods for a specific endpoint | endpoint_name: string | Method signatures, parameters, return types |
| **list_models** | List all protocol models | None | List of model names and fields |
| **model_inspector** | Get detailed model field information | model_name: string | Field types, relations, serialization info |
| **config_reader** | Read ServerPod YAML configuration | config_file: string, environment: string | Parsed YAML config |
| **database_schema** | Get database schema (tables, columns, indexes) | table_filter: string? | Database structure |
| **migration_scanner** | List migration files | None | Migration history, table changes |

#### Tier 2: Enhanced Tools (Should Have)

| Tool Name | Description | Input | Output |
|-----------|-------------|-------|--------|
| **project_structure** | Get project file tree | directory: string?, depth: int? | File tree structure |
| **find_files** | Find files by pattern | pattern: string, path: string? | List of matching files |
| **read_file** | Read file content | file_path: string | File content |
| **search_code** | Search code content | query: string, file_pattern: string? | Matches with line numbers |
| **call_endpoint** | Call endpoint method for testing | endpoint: string, method: string, params: object | Result or error |
| **list_migrations** | Get migration history | None | Ordered list of migrations |
| **service_config** | Get service (redis/database) config | service: 'redis' \| 'database' | Connection parameters |

#### Tier 3: Advanced Tools (Nice to Have)

| Tool Name | Description | Input | Output |
|-----------|-------------|-------|--------|
| **endpoint_tester** | Generate test code for endpoint | endpoint: string, method: string | Generated test code |
| **model_generator** | Generate model code | fields: object | Generated model class |
| **migration_generator** | Generate migration from schema diff | changes: object | Migration file content |
| **log_analyzer** | Analyze ServerPod logs | log_level: string? | Structured log entries |
| **validation_helper** | Validate model data | model_name: string, data: object | Validation result |

---

## 6. API/Interfaces

### 6.1 Main Boost Server

```dart
/// Main MCP Server for ServerPod Boost
class Boost extends McpServer {
  /// Server name
  @override
  String get name => 'ServerPod Boost';

  /// Server version
  @override
  String get version => '0.1.0';

  /// Instructions for AI
  @override
  String get instructions => '''
    ServerPod ecosystem MCP server offering endpoint inspection,
    protocol model analysis, database schema access, configuration
    reading, and project structure understanding. Boost helps with
    high-quality ServerPod code generation.
  ''';

  /// Bootstrap the server
  @override
  Future<void> boot() async {
    // Register tools
    tools = await ToolRegistry.discoverTools();

    // Register resources (optional, future enhancement)
    // resources = await ResourceRegistry.discoverResources();

    // Register prompts (optional, future enhancement)
    // prompts = await PromptRegistry.discoverPrompts();
  }
}
```

### 6.2 Tool Executor (Isolated Execution)

```dart
/// Execute tools in isolated subprocess (security & stability)
class ToolExecutor {
  /// Execute a tool class with given arguments
  Future<McpResponse> execute(String toolClass, Map<String, dynamic> arguments);

  /// Build command for subprocess execution
  List<String> buildCommand(String toolClass, Map<String, dynamic> arguments);

  /// Get timeout for tool execution
  int getTimeout(Map<String, dynamic> arguments);

  /// Reconstruct response from subprocess output
  McpResponse reconstructResponse(Map<String, dynamic> data);
}
```

### 6.3 MCP Protocol Implementation

```dart
/// JSON-RPC 2.0 Request
class McpRequest {
  String jsonrpc = '2.0';
  String id;
  String method;
  Map<String, dynamic>? params;
}

/// JSON-RPC 2.0 Response
class McpResponse {
  String jsonrpc = '2.0';
  String id;
  dynamic result;  // McpToolResult or McpErrorResponse
  bool get isError => result is McpErrorResponse;
}

/// Tool execution result
class McpToolResult {
  required String content;
  bool get is-error => false;
}

/// Error response
class McpErrorResponse {
  required String message;
  Map<String, dynamic>? details;
  bool get is-error => true;
}

/// stdio Transport
class McpTransport {
  /// Read request from stdin
  Future<McpRequest> readRequest();

  /// Write response to stdout
  Future<void> writeResponse(McpResponse response);
}
```

### 6.4 Tool Implementations (Examples)

#### Application Info Tool

```dart
class ApplicationInfoTool extends McpTool {
  @override
  String get name => 'application_info';

  @override
  String get description => '''
    Get comprehensive ServerPod application information including:
    - Dart SDK version
    - ServerPod version
    - Database configuration
    - All endpoints with their methods
    - All protocol models
    Use this tool at the start of each conversation to understand the project.
  ''';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {},
  };

  @override
  Future<McpResponse> execute(McpRequest request) async {
    final info = {
      'dart_version': _getDartVersion(),
      'serverpod_version': _getServerpodVersion(),
      'database': await _getDatabaseConfig(),
      'endpoints': await _listEndpoints(),
      'models': await _listModels(),
    };
    return McpResponse.fromData(info);
  }
}
```

#### Endpoint Inspector Tool

```dart
class EndpointMethodsTool extends McpTool {
  @override
  String get name => 'endpoint_methods';

  @override
  String get description => '''
    Get detailed information about an endpoint's methods:
    - Method names
    - Parameter types and names
    - Return types
    - Access controls (if any)
    Pass the endpoint name (e.g., 'greeting', 'emailIdp').
  ''';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'endpoint_name': {
        'type': 'string',
        'description': 'Name of the endpoint (e.g., "greeting")'
      }
    },
    'required': ['endpoint_name']
  };

  @override
  Future<McpResponse> execute(McpRequest request) async {
    final endpointName = request.params!['endpoint_name'] as String;
    final methods = await _inspectEndpoint(endpointName);
    return McpResponse.fromData(methods);
  }
}
```

#### Config Reader Tool

```dart
class ConfigReaderTool extends McpTool {
  @override
  String get name => 'config_reader';

  @override
  String get description => '''
    Read ServerPod YAML configuration files (development.yaml, production.yaml, etc.)
    Returns parsed configuration as JSON. Useful for understanding service setup,
    database connections, Redis configuration, and server ports.
  ''';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'environment': {
        'type': 'string',
        'enum': ['development', 'production', 'staging', 'test'],
        'description': 'Environment to read config for',
        'default': 'development'
      },
      'section': {
        'type': 'string',
        'description': 'Specific config section (optional)',
        'enum': ['apiServer', 'insightsServer', 'webServer', 'database', 'redis']
      }
    }
  };

  @override
  Future<McpResponse> execute(McpRequest request) async {
    final env = request.params!['environment'] as String? ?? 'development';
    final section = request.params['section'] as String?;
    final config = await _readConfig(env, section);
    return McpResponse.fromData(config);
  }
}
```

---

## 7. Installation & Configuration

### 7.1 Installation Process

```bash
# In ServerPod project root (e.g., /Users/musinsa/always_summer/pilly)
dart pub global activate serverpod_boost

# Or install locally to project
cd /Users/musinsa/always_summer/pilly
mkdir -p .ai/boost
cd .ai/boost
dart pub add serverpod_boost
```

### 7.2 Configuration File

```yaml
# .ai/boost/config.yaml
serverpod:
  project_path: ".."  # Relative to .ai/boost
  config_dir: "config"
  lib_dir: "lib"
  migrations_dir: "migrations"

mcp:
  tools:
    exclude: []  # Tools to disable
    include: []  # Additional tools to load

  resources:
    exclude: []
    include: []

  prompts:
    exclude: []
    include: []
```

---

## 8. Integration with AI Assistants

### 8.1 MCP Server Configuration (Claude Desktop)

```json
// Claude Desktop MCP config
{
  "mcpServers": {
    "serverpod-boost": {
      "command": "dart",
      "args": [
        "/Users/musinsa/always_summer/pilly/.ai/boost/bin/boost.dart"
      ],
      "env": {
        "SERVERPOD_PROJECT_PATH": "/Users/musinsa/always_summer/pilly"
      }
    }
  }
}
```

### 8.2 Usage Example for AI

```
USER: Create a new endpoint for user management

AI (with Boost):
1. Calls application_info to understand project
2. Calls list_endpoints to see existing endpoints
3. Calls model_inspector to understand User model
4. Generates appropriate endpoint code
5. Calls endpoint_tester to validate structure
```

---

## 9. Security Considerations

### 9.1 Tool Isolation

- Each tool executes in isolated subprocess
- Timeout protection (default 180s, max 600s)
- No direct file system writes (read-only operations)

### 9.2 Access Control

- Configuration-based tool whitelisting/blacklisting
- No database modification tools (read-only schema access)
- Safe code execution (no eval/exec)

---

## 10. Development Roadmap

### Phase 1: MVP (Week 1-2)
- [ ] MCP protocol implementation
- [ ] Tool registry system
- [ ] application_info tool
- [ ] list_endpoints tool
- [ ] Basic integration testing with Pilly project

### Phase 2: Core Tools (Week 3-4)
- [ ] Protocol model inspection
- [ ] Config reader
- [ ] Database schema reader
- [ ] Migration scanner
- [ ] Documentation

### Phase 3: Advanced Features (Week 5-6)
- [ ] Code search capabilities
- [ ] Endpoint testing
- [ ] Code generation helpers
- [ ] Prompt templates

### Phase 4: Polish (Week 7-8)
- [ ] Error handling improvements
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] Public release

---

## 11. Testing Strategy

### 11.1 Unit Tests
- Tool execution logic
- Response serialization
- Schema validation

### 11.2 Integration Tests
- Real ServerPod project (Pilly)
- All tools against actual project
- MCP protocol compliance

### 11.3 Test Coverage
```
test/
├── unit/
│   ├── tool_registry_test.dart
│   ├── tool_executor_test.dart
│   └── mcp_protocol_test.dart
└── integration/
    ├── application_info_test.dart
    ├── endpoint_inspector_test.dart
    └── config_reader_test.dart
```

---

## 12. Documentation

### 12.1 User Documentation
- Installation guide
- Configuration reference
- Tool API reference
- Usage examples

### 12.2 Developer Documentation
- Architecture overview
- Adding new tools
- MCP protocol details
- Testing guidelines

---

## 13. Comparison: Laravel Boost vs ServerPod Boost

| Aspect | Laravel Boost | ServerPod Boost |
|--------|---------------|-----------------|
| Language | PHP | Dart |
| MCP Package | laravel/mcp | Custom implementation |
| Tool Location | src/Mcp/Tools | lib/tools/ |
| Tool Registry | DirectoryIterator | Manual registration (future: annotation-based) |
| Config Format | PHP arrays + .env | YAML files |
| Project Structure | Laravel-specific | ServerPod 3-package (server/client/flutter) |
| Database | Eloquent ORM | ServerPod Database |
| Endpoints | Routes/Controllers | Endpoints with typed methods |

---

## 14. Success Criteria

### 14.1 Functional Requirements
- ✅ Successfully connects to AI assistant via MCP
- ✅ Reads ServerPod project structure
- ✅ Lists all endpoints and methods
- ✅ Inspects protocol models
- ✅ Reads YAML configurations
- ✅ Provides database schema information

### 14.2 Quality Requirements
- ✅ Zero external MCP dependencies
- ✅ Type-safe Dart code (null safety)
- ✅ Comprehensive error handling
- ✅ Isolated tool execution
- ✅ Clear, helpful tool descriptions

### 14.3 Integration Requirements
- ✅ Works with Pilly project
- ✅ Compatible with ServerPod 3.2.3+
- ✅ Compatible with Dart 3.8.0+
- ✅ No modification to ServerPod core

---

## Appendix A: File References

### Laravel Boost Reference Files
- `/Users/musinsa/always_summer/boost/src/Mcp/Boost.php` - Main MCP server
- `/Users/musinsa/always_summer/boost/src/Mcp/ToolRegistry.php` - Tool registry
- `/Users/musinsa/always_summer/boost/src/Mcp/ToolExecutor.php` - Subprocess execution
- `/Users/musinsa/always_summer/boost/src/Mcp/Tools/ApplicationInfo.php` - Example tool
- `/Users/musinsa/always_summer/boost/src/Mcp/Tools/DatabaseSchema.php` - DB schema tool

### ServerPod Reference Files
- `/Users/musinsa/always_summer/serverpod/packages/serverpod/pubspec.yaml` - Dependencies
- `/Users/musinsa/always_summer/pilly/pilly_server/lib/server.dart` - Server entry
- `/Users/musinsa/always_summer/pilly/pilly_server/lib/src/greetings/greeting_endpoint.dart` - Example endpoint
- `/Users/musinsa/always_summer/pilly/pilly_server/config/development.yaml` - Config example
- `/Users/musinsa/always_summer/pilly/pilly_server/config/generator.yaml` - Generator config

---

## Appendix B: Key Design Decisions

1. **Pure Dart Implementation**: Following Laravel Boost's philosophy of pure language implementation
2. **No External MCP Package**: Implementing JSON-RPC 2.0 directly for full control
3. **Subprocess Execution**: Isolating tool execution for security and stability
4. **Tool Registry Pattern**: Automatic discovery similar to Laravel Boost
5. **YAML Configuration**: Matching ServerPod's native configuration format
6. **Installation in .ai/boost/**: Non-intrusive installation, doesn't pollute project root

---

## Appendix C: ServerPod v3 Specific Patterns (Pilly Research)

**Source**: Research conducted on `/Users/musinsa/always_summer/pilly` (2025-02-04)

### C.1 Monorepo Structure

ServerPod v3 projects use a **3-package monorepo** structure:

```
pilly/                          # Monorepo root
├── pilly_server/               # Server package (source of truth)
│   ├── lib/src/
│   │   ├── generated/          # Auto-generated (DO NOT EDIT)
│   │   │   ├── endpoints.dart
│   │   │   └── protocol.dart
│   │   ├── greetings/
│   │   │   └── greeting_endpoint.dart
│   │   └── auth/
│   ├── config/
│   │   ├── development.yaml
│   │   ├── production.yaml
│   │   └── generator.yaml
│   └── migrations/
├── pilly_client/               # Client package (generated)
│   └── lib/src/protocol/
│       ├── greetings/
│       │   └── greeting.dart
│       └── protocol.dart
├── pilly_flutter/              # Flutter app package
└── .ai/
    └── boost/                  # Boost installs here (monorepo root)
```

**Boost Installation**: `{monorepo_root}/.ai/boost/`
- Allows boost to see all 3 packages
- Server package detected as `*_server` or `server` subdirectory

### C.2 Endpoint Method Signatures

**Pattern**: `Future<ReturnType> methodName(Session session, [params...])`

**Example from Pilly**:
```dart
// pilly_server/lib/src/greetings/greeting_endpoint.dart
Future<Greeting> hello(Session session, String name) async {
  return Greeting(
    message: 'Hello $name',
    author: 'Serverpod',
    timestamp: DateTime.now(),
  );
}
```

**RegExp Pattern**:
```dart
static final _methodPattern = RegExp(
  r'Future\s*<(\w+(?:<[^>]+>)?)>\s*'      // Return type (e.g., <Greeting>)
  r'(\w+)\s*'                              // Method name (e.g., hello)
  r'\(\s*Session\s+session\s*,\s*'         // First param (required)
  r'([^)]+)\)'                             // Remaining params
);
```

**Caveat - Auth Endpoints**: Auth endpoints inherit from base classes:
- `EmailIdpEndpoint` extends from `serverpod_auth_idp_server`
- `JwtRefreshEndpoint` extends from `serverpod_auth_core_server`
- Source method signatures are NOT in project files
- **Solution**: Include base class method signatures or parse ServerPod documentation

### C.3 Protocol Models (.spy.yaml Format)

**Critical Finding**: ServerPod v3 uses **`.spy.yaml`** files as SOURCE OF TRUTH

**Example Source File**:
```yaml
# pilly_server/lib/src/greetings/greeting.spy.yaml
class: Greeting

fields:
  message: String
  author: String
  timestamp: DateTime
```

**Generated Client Model** (for reference only):
```dart
// pilly_client/lib/src/protocol/greetings/greeting.dart
abstract class Greeting implements SerializableModel {
  String message;
  String author;
  DateTime timestamp;
}
```

**Field Extraction RegExp** (for .spy.yaml):
```dart
// Match field definitions in YAML
final fieldPattern = RegExp(r'^\s+(\w+):\s*(\S+)');
// Example: "  message: String" -> ["message", "String"]
```

**File Locations**:
- **Source**: `{server}/lib/src/**/*.spy.yaml`
- **Generated (Server)**: `{server}/lib/src/generated/protocol.dart`
- **Generated (Client)**: `{client}/lib/src/protocol/`

### C.4 File Search Patterns

| Target | Pattern | Exclude |
|--------|---------|---------|
| Endpoints | `**/lib/src/**/*endpoint*.dart` | `**/generated/**` |
| Models (Source) | `**/lib/src/**/*.spy.yaml` | - |
| Models (Generated) | `**/lib/src/protocol/**/*.dart` | - |
| Configs | `**/config/*.yaml` | `passwords.yaml` |
| Migrations | `**/migrations/*.dart` | - |

### C.5 Generated Code Markers

All generated files contain:
```dart
/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */
```

**Use these markers to**: Skip generated files when searching for user code

### C.6 Client vs Server Method Signatures

ServerPod generates different signatures for client:

```dart
// Server (user code)
Future<Greeting> hello(Session session, String name) async { ... }

// Client (generated)
Future<Greeting> hello(String name) { ... }  // No Session param
```

**Implication**: When generating client code, omit the `Session session` parameter

### C.7 Project Root Detection Strategy

```dart
String detectProjectRoot(String currentPath) {
  // 1. Check environment variable
  final envRoot = Platform.environment['SERVERPOD_BOOST_PROJECT_ROOT'];
  if (envRoot != null) return envRoot;

  // 2. If in .ai/boost/, navigate up to monorepo root
  if (currentPath.contains('.ai/boost')) {
    return currentPath.split('.ai/boost')[0];
  }

  // 3. Detect *_server package (go up to find monorepo root)
  final serverMatch = RegExp(r'(.+/)\w+_server').firstMatch(currentPath);
  if (serverMatch != null) {
    return serverMatch.group(1)!;
  }

  // 4. Fallback to current directory
  return currentPath;
}
```

### C.8 Code Generation Workflow

```
1. User defines .spy.yaml model
   ↓
2. User writes endpoint method
   ↓
3. Run: serverpod generate
   ↓
4. Generates:
   - server/lib/src/generated/protocol.dart
   - server/lib/src/generated/endpoints.dart
   - client/lib/src/protocol/*.dart
   - client/lib/src/protocol/protocol.dart
```

**Boost Tools Must**:
- Parse `.spy.yaml` for model definitions (source of truth)
- Parse endpoint files for method signatures
- Skip generated files when searching for user code

---

**Document Version**: 1.1
**Last Updated**: 2025-02-04
**Status**: Validated against Pilly project
