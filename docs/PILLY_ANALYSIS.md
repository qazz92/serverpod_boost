# ServerPod Multi-Package Architecture Analysis
## Pilly Project - Complete Technical Analysis

**Analysis Date**: 2025-02-04
**Project**: Pilly (Reference ServerPod Project)
**Location**: `/Users/musinsa/always_summer/pilly`
**ServerPod Version**: 3.2.3
**Dart SDK**: 3.10.4

---

## Executive Summary

The Pilly project demonstrates ServerPod's **3-package monorepo architecture** with automatic code generation flowing from server → client → flutter app. This architecture enables type-safe communication between backend and frontend while maintaining clear separation of concerns.

**Key Insight**: ServerPod's code generation is **unidirectional** - it flows from the server package to the client package, but the Flutter app consumes the client package as a standard dependency.

---

## Complete Directory Tree

```
pilly/                                          # Monorepo Root
├── .github/                                    # GitHub workflows
│
├── pilly_server/                               # [SERVER PACKAGE] - Source of Truth
│   ├── bin/
│   │   └── main.dart                          # Server entry point
│   │
│   ├── config/
│   │   ├── generator.yaml                     # ⚡ CODE GEN CONFIG (CRITICAL)
│   │   ├── development.yaml                   # Dev server config
│   │   ├── production.yaml                    # Production config
│   │   ├── staging.yaml                       # Staging config
│   │   ├── test.yaml                          # Test config
│   │   └── passwords.yaml                     # Database passwords
│   │
│   ├── lib/
│   │   ├── server.dart                        # Server initialization
│   │   └── src/
│   │       ├── auth/
│   │       │   ├── email_idp_endpoint.dart    # Email auth endpoint
│   │       │   └── jwt_refresh_endpoint.dart  # JWT refresh endpoint
│   │       │
│   │       ├── generated/                     # 🤖 GENERATED CODE (DO NOT EDIT)
│   │       │   ├── endpoints.dart             # Generated endpoint dispatchers
│   │       │   ├── protocol.dart              # Protocol serialization
│   │       │   ├── protocol.yaml              # Protocol specification
│   │       │   └── greetings/
│   │       │       └── greeting.dart          # Generated data models
│   │       │
│   │       ├── greetings/
│   │       │   └── greeting_endpoint.dart     # 📝 Custom endpoint code
│   │       │
│   │       └── web/
│   │           ├── routes/
│   │           └── widgets/
│   │
│   ├── migrations/                            # Database migrations
│   ├── test/
│   │   └── integration/
│   │       └── test_tools/                    # Server test tools
│   │
│   ├── web/                                   # Static web assets
│   │   ├── app/                              # Flutter web build output
│   │   ├── static/
│   │   ├── templates/
│   │   └── pages/
│   │
│   ├── pubspec.yaml                           # Server dependencies
│   └── Dockerfile                             # Container config
│
├── pilly_client/                              # [CLIENT PACKAGE] - Generated Protocol
│   ├── lib/
│   │   ├── pilly_client.dart                  # Main export file
│   │   └── src/
│   │       └── protocol/                      # 🤖 GENERATED CODE (DO NOT EDIT)
│   │           ├── protocol.dart              # Protocol serialization
│   │           ├── client.dart                # Generated client methods
│   │           └── greetings/
│   │               └── greeting.dart          # Generated data models
│   │
│   ├── doc/
│   │   └── endpoint.md                        # Generated endpoint docs
│   │
│   └── pubspec.yaml                           # Client dependencies
│
└── pilly_flutter/                             # [FLUTTER APP] - Frontend Application
    ├── lib/
    │   ├── main.dart                          # Flutter entry point
    │   └── screens/
    │       ├── greetings_screen.dart          # Example: uses client.greeting.hello()
    │       └── sign_in_screen.dart            # Authentication screen
    │
    ├── assets/
    │   └── config.json                        # Server URL configuration
    │
    ├── ios/                                   # iOS platform code
    ├── android/                               # Android platform code
    ├── web/                                   # Web platform code
    ├── macos/                                 # macOS platform code
    ├── linux/                                 # Linux platform code
    │
    └── pubspec.yaml                           # Flutter dependencies (includes pilly_client)
```

---

## Package Relationships & Dependencies

### Dependency Graph

```
┌─────────────────┐
│  pilly_flutter  │  (Flutter Application)
│  - UI Layer     │  - Uses: pilly_client (local path dependency)
└────────┬────────┘  - Uses: serverpod_flutter
         │            - Uses: serverpod_auth_idp_flutter
         │
         ▼
┌─────────────────┐
│  pilly_client   │  (Generated Client Library)
│  - Protocol     │  - Uses: serverpod_client
└────────┬────────┘  - Uses: serverpod_auth_idp_client
         │            - GENERATED FROM: pilly_server
         │
         ▼
┌─────────────────┐
│  pilly_server   │  (Server - Source of Truth)
│  - Endpoints    │  - Uses: serverpod
│  - Models       │  - Uses: serverpod_auth_idp_server
└─────────────────┘  - GENERATES: pilly_client code
```

### Pubspec Dependencies

**pilly_server/pubspec.yaml**:
```yaml
dependencies:
  serverpod: 3.2.3
  serverpod_auth_idp_server: 3.2.3

serverpod:
  scripts:
    start: dart bin/main.dart --apply-migrations
    flutter_build: (builds flutter web app to server/web/app)
```

**pilly_client/pubspec.yaml**:
```yaml
dependencies:
  serverpod_client: 3.2.3
  serverpod_auth_idp_client: 3.2.3
```

**pilly_flutter/pubspec.yaml**:
```yaml
dependencies:
  flutter:
    sdk: flutter
  pilly_client:
    path: ../pilly_client                    # ← LOCAL PATH DEPENDENCY
  serverpod_flutter: 3.2.3
  serverpod_auth_idp_flutter: 3.2.3
```

---

## Code Generation Flow

### 1. Configuration: `generator.yaml`

Located at: `/pilly_server/config/generator.yaml`

```yaml
type: server                                 # Package type

client_package_path: ../pilly_client         # ← WHERE TO GENERATE CLIENT CODE
server_test_tools_path: test/integration/test_tools
```

**This is the CRITICAL configuration file** that tells Serverpod where to generate client code.

### 2. Development Workflow

```
┌──────────────────────────────────────────────────────────────┐
│ STEP 1: Define Endpoint on Server                           │
├──────────────────────────────────────────────────────────────┤
│ File: pilly_server/lib/src/greetings/greeting_endpoint.dart  │
│                                                              │
│ class GreetingEndpoint extends Endpoint {                    │
│   Future<Greeting> hello(Session session, String name) {    │
│     return Greeting(message: 'Hello $name');                │
│   }                                                          │
│ }                                                            │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 2: Run Code Generation                                 │
├──────────────────────────────────────────────────────────────┤
│ Command: serverpod generate                                 │
│ Location: /pilly_server (must run from server package)      │
│                                                              │
│ This command:                                               │
│ 1. Scans server/src for Endpoint classes                    │
│ 2. Generates protocol.yaml                                 │
│ 3. Generates server-side dispatchers                        │
│ 4. Generates client-side protocol code                      │
│ 5. Writes to ../pilly_client (from generator.yaml)         │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 3: Generated Files                                     │
├──────────────────────────────────────────────────────────────┤
│ SERVER SIDE (pilly_server/lib/src/generated/):              │
│ ├── protocol.yaml          - Protocol specification         │
│ ├── endpoints.dart         - Endpoint dispatcher            │
│ ├── protocol.dart          - Serialization manager          │
│ └── greetings/greeting.dart - Generated model               │
│                                                              │
│ CLIENT SIDE (pilly_client/lib/src/protocol/):               │
│ ├── protocol.dart          - Client serialization           │
│ ├── client.dart            - Client methods                 │
│ └── greetings/greeting.dart - Generated model               │
└──────────────────────────────────────────────────────────────┘
                           ↓
┌──────────────────────────────────────────────────────────────┐
│ STEP 4: Use in Flutter App                                  │
├──────────────────────────────────────────────────────────────┤
│ File: pilly_flutter/lib/screens/greetings_screen.dart       │
│                                                              │
│ final result = await client.greeting.hello('World');        │
│ // client is from pilly_client package                      │
│ // .greeting is the generated endpoint module               │
│ // .hello() is the generated method                         │
└──────────────────────────────────────────────────────────────┘
```

### 3. Generated Code Examples

**Server Side** (`pilly_server/lib/src/generated/endpoints.dart`):
```dart
class Endpoints extends EndpointDispatch {
  @override
  void initializeEndpoints(Server server) {
    var endpoints = <String, Endpoint>{
      'greeting': GreetingEndpoint()
        ..initialize(server, 'greeting', null),
    };
    // ... method connectors for reflection
  }
}
```

**Client Side** (`pilly_client/lib/src/protocol/client.dart`):
```dart
class EndpointGreeting {
  final EndpointCaller caller;

  EndpointGreeting(this.caller);

  Future<Greeting> hello(String name) async {
    return caller.callServerEndpoint<Greeting>(
      'greeting',
      'hello',
      {'name': name},
    );
  }
}
```

**Shared Model** (generated identically in both):
```dart
abstract class Greeting implements SerializableModel {
  factory Greeting({
    required String message,
    required String author,
    required DateTime timestamp,
  }) = _GreetingImpl;

  String message;
  String author;
  DateTime timestamp;
}
```

---

## Development Workflow Between Packages

### Typical Development Session

```bash
# 1. Server-side development
cd pilly_server
# Edit: lib/src/your_feature/endpoint.dart
serverpod generate     # Generate protocol
dart bin/main.dart     # Start server

# 2. Client updates (automatic)
cd ../pilly_client
# Code is auto-generated - no manual edits needed
# Verify: lib/src/protocol/your_feature/

# 3. Flutter app development
cd ../pilly_flutter
# Import: import 'package:pilly_client/pilly_client.dart';
flutter run           # Run app
```

### Code Generation Rules

1. **SERVER** is the source of truth
2. Define endpoints in `pilly_server/lib/src/**/endpoint.dart`
3. Run `serverpod generate` from `pilly_server/`
4. Client code is AUTOMATICALLY generated in `pilly_client/`
5. Flutter app imports and uses the client package

### File Organization Patterns

**Server Package** (`pilly_server/lib/src/`):
```
feature_name/
├── feature_name_endpoint.dart    # Your endpoint class (EDIT THIS)
└── models/
    └── my_model.dart             # Custom models (EDIT THIS)

generated/
└── feature_name/
    └── feature_name_endpoint.dart # Generated (DO NOT EDIT)
```

**Client Package** (`pilly_client/lib/src/protocol/`):
```
feature_name/
└── feature_name_endpoint.dart    # Generated (DO NOT EDIT)
```

---

## Server Configuration

### Development Config: `config/development.yaml`

```yaml
apiServer:
  port: 8080
  publicHost: localhost
  publicPort: 8080
  publicScheme: http

insightsServer:
  port: 8081

webServer:
  port: 8082

database:
  host: localhost
  port: 8090
  name: pilly
  user: postgres

redis:
  enabled: false
```

### Flutter Client Configuration

**File**: `pilly_flutter/assets/config.json`
```json
{
  "serverUrl": "http://localhost:8080/"
}
```

**Usage in Flutter** (`main.dart`):
```dart
final serverUrl = await getServerUrl(); // Reads from config.json
client = Client(serverUrl)
  ..connectivityMonitor = FlutterConnectivityMonitor()
  ..authSessionManager = FlutterAuthSessionManager();
```

---

## Authentication Flow

ServerPod includes built-in authentication:

**Server Side** (`pilly_server/lib/src/auth/`):
- `email_idp_endpoint.dart` - Email/password authentication
- `jwt_refresh_endpoint.dart` - JWT token refresh

**Client Side**:
- Uses `serverpod_auth_idp_flutter`
- Pre-built sign-in screens
- Automatic session management

**Flutter App** (`pilly_flutter/lib/screens/sign_in_screen.dart`):
```dart
SignInScreen(
  child: GreetingsScreen(
    onSignOut: () async {
      await client.auth.signOutDevice();
    },
  ),
)
```

---

## Key Takeaways for ServerPod Boost

### 1. Package Detection Strategy

ServerPod Boost should:
1. **Look for `generator.yaml`** in subdirectories to identify server packages
2. **Parse `client_package_path`** to locate the generated client package
3. **Search for Flutter apps** by looking for `pubspec.yaml` with `flutter` SDK dependency
4. **Verify the 3-package structure**: server → client → flutter

### 2. Where ServerPod Boost Should Be Installed

**Option A: Install in Server Package** (RECOMMENDED)
- **Location**: `pilly_server/.ai/boost/`
- **Why**:
  - Server is the source of truth
  - Code generation happens here
  - Single entry point for the entire monorepo
  - Can access all packages via relative paths

**Option B: Monorepo Root**
- **Location**: `pilly/.ai/boost/`
- **Why**:
  - Single location for entire project
  - Easy to manage at project level
  - Can detect all 3 packages automatically

### 3. MCP Tools Integration

ServerPod Boost's MCP tools should work across packages:

```
serverpod_boost/
├── .ai/
│   ├── boost/                    # Boost core skills
│   │   ├── core.dart.md         # ServerPod-specific guidelines
│   │   ├── serverpod.md         # ServerPod framework docs
│   │   └── endpoints.md         # Endpoint development patterns
│   │
│   ├── server/                   # Server package skills
│   │   ├── endpoint-development.md
│   │   ├── model-development.md
│   │   └── migration-management.md
│   │
│   ├── client/                   # Client package skills
│   │   ├── protocol-usage.md
│   │   └── authentication.md
│   │
│   └── flutter/                  # Flutter app skills
│       ├── ui-development.md
│       ├── client-integration.md
│       └── state-management.md
│
├── mcp_server/
│   └── tools/
│       ├── generate-protocol     # Wrapper for 'serverpod generate'
│       ├── create-endpoint       # Scaffold new endpoint
│       ├── create-model          # Scaffold new model
│       ├── run-migration         # Run database migration
│       ├── list-endpoints        # List all endpoints
│       └── validate-protocol     # Validate protocol before generation
│
└── config/
    └── boost.yaml                # ServerPod Boost configuration
```

### 4. Critical Files for ServerPod Boost

**Must Detect and Understand**:
1. `/server/config/generator.yaml` - Code generation config
2. `/server/lib/src/generated/protocol.yaml` - Generated protocol spec
3. `/server/pubspec.yaml` - Server dependencies
4. `/client/pubspec.yaml` - Client dependencies
5. `/flutter/pubspec.yaml` - Flutter dependencies (includes client)

**Must Work With**:
- Endpoints: `/server/lib/src/**/*_endpoint.dart`
- Models: Both custom and generated
- Migrations: `/server/migrations/`
- Tests: `/server/test/` and `/flutter/test/`

### 5. Development Workflow Support

ServerPod Boost should streamline:

```bash
# Typical flow with Boost:
cd pilly_server

# 1. Create new endpoint
boost create:endpoint User --methods:list,get,create,update,delete

# 2. Create models
boost create:model User name:String email:String

# 3. Generate protocol
boost generate         # Wraps 'serverpod generate'

# 4. Run tests
boost test            # Runs server tests

# 5. Start server
boost serve           # Starts server with hot reload

# 6. In another terminal, run flutter
cd ../pilly_flutter
boost run             # Runs Flutter app with client connection
```

---

## Comparison: Laravel Boost vs ServerPod Boost

| Aspect | Laravel Boost | ServerPod Boost |
|--------|---------------|-----------------|
| **Framework** | PHP/Laravel | Dart/ServerPod |
| **Packages** | Single app (monolith) | 3-package monorepo |
| **Code Gen** | None (convention) | Central (server → client) |
| **Type Safety** | Runtime | Compile-time (Dart) |
| **Language Server** | IntelliJ PHP | Dart Analysis Server |
| **Entry Point** | Laravel project root | Server package |
| **Key Command** | `php artisan` | `serverpod generate` |
| **Frontend** | Blade/Inertia/Vite | Flutter (native & web) |

---

## Recommendations for ServerPod Boost Implementation

### Phase 1: Package Detection
```yaml
# config/boost/detection.yaml
monorepo:
  type: serverpod
  packages:
    server:
      detect:
        - file: "config/generator.yaml"
          contains: "type: server"
        - file: "pubspec.yaml"
          dependency: "serverpod"
      path: "./pilly_server"

    client:
      detect:
        - file: "pubspec.yaml"
          dependency: "serverpod_client"
      path_from: "server"  # Read from generator.yaml: client_package_path

    flutter:
      detect:
        - file: "pubspec.yaml"
          sdk: "flutter"
      path: "./pilly_flutter"
```

### Phase 2: MCP Tools Priority
1. **generate-protocol** - Most critical, wraps `serverpod generate`
2. **create-endpoint** - Scaffold new endpoint with protocol
3. **create-model** - Create serializable models
4. **list-endpoints** - Show all available endpoints
5. **validate** - Check protocol before generation

### Phase 3: Skills Organization
```
.ai/boost/
├── core.dart.md           # ServerPod fundamentals
├── server/
│   ├── endpoints.md       # Endpoint development
│   ├── models.md          # Data models
│   ├── database.md        # Database & migrations
│   └── authentication.md  # Auth implementation
├── client/
│   └── usage.md           # Using generated client
└── flutter/
    ├── integration.md     # Client integration
    └── authentication.md  # Flutter auth widgets
```

---

## Conclusion

The Pilly project demonstrates ServerPod's elegant **3-package architecture** where:

1. **Server Package** - Source of truth, defines endpoints and models
2. **Client Package** - Auto-generated from server, provides type-safe API
3. **Flutter Package** - Consumes client package, provides UI

**ServerPod Boost should**:
- Install in the **server package** (`pilly_server/.ai/boost/`)
- Parse `generator.yaml` to understand the monorepo structure
- Provide MCP tools that wrap `serverpod generate` and other CLI commands
- Include skills for endpoint development, protocol generation, and Flutter integration
- Work seamlessly across all 3 packages using relative paths

**The key insight**: ServerPod's power comes from its code generation, and ServerPod Boost should enhance—not replace—this workflow by making it easier to create, generate, and validate endpoints and models.

---

## Next Steps for ServerPod Boost

1. ✅ Study this complete architecture
2. ⬜ Design package detection algorithm
3. ⬜ Create `generator.yaml` parser
4. ⬜ Implement first MCP tool: `generate-protocol`
5. ⬜ Create skills documentation structure
6. ⬜ Test with Pilly project
7. ⬜ Iterate based on real development workflows

**File Location**: `/Users/musinsa/always_summer/serverpod_boost/PILLY_ANALYSIS.md`
