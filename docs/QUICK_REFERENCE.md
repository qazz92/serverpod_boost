# ServerPod Multi-Package Architecture - Quick Reference

## TL;DR

**ServerPod = 3-package monorepo** with code generation flowing from **server → client → flutter**

```
pilly_server (SOURCE) → [serverpod generate] → pilly_client → pilly_flutter (USES)
```

---

## Directory Structure (30-Second View)

```
pilly/
├── pilly_server/          ← SERVER: Define endpoints & models
│   ├── config/
│   │   └── generator.yaml    ⚡ KEY FILE: client_package_path: ../pilly_client
│   └── lib/src/
│       ├── [feature]/_endpoint.dart  ← YOU WRITE THIS
│       └── generated/               ← DO NOT EDIT (generated)
│
├── pilly_client/          ← CLIENT: Auto-generated from server
│   └── lib/src/protocol/           ← DO NOT EDIT (all generated)
│
└── pilly_flutter/         ← FLUTTER: Uses client package
    └── lib/
        ├── main.dart              ← Initialize client
        └── screens/               ← Use client.greeting.hello()
```

---

## Critical Files

| File | Purpose | Edit? |
|------|---------|-------|
| `pilly_server/config/generator.yaml` | Code gen config | ✅ Yes |
| `pilly_server/lib/src/**/*_endpoint.dart` | Your endpoints | ✅ Yes |
| `pilly_server/lib/src/generated/*` | Generated server code | ❌ No |
| `pilly_client/lib/src/protocol/*` | Generated client code | ❌ No |
| `pilly_flutter/lib/**` | Your UI code | ✅ Yes |

---

## Development Workflow

```bash
# 1. Create endpoint
cd pilly_server/lib/src/greetings
# Create: greeting_endpoint.dart

# 2. Generate protocol
cd ../../../  # Back to server root
serverpod generate

# 3. Use in Flutter
cd ../../pilly_flutter
flutter run
```

---

## Code Example

**Server** (`greeting_endpoint.dart`):
```dart
class GreetingEndpoint extends Endpoint {
  Future<Greeting> hello(Session session, String name) async {
    return Greeting(message: 'Hello $name');
  }
}
```

**Generated Client** (auto-generated):
```dart
class EndpointGreeting {
  Future<Greeting> hello(String name) async { /* ... */ }
}
```

**Flutter Usage**:
```dart
final greeting = await client.greeting.hello('World');
print(greeting.message);  // Type-safe!
```

---

## Key Configuration

**generator.yaml** (`pilly_server/config/`):
```yaml
type: server
client_package_path: ../pilly_client    # WHERE CLIENT CODE IS GENERATED
```

**Flutter pubspec.yaml**:
```yaml
dependencies:
  pilly_client:
    path: ../pilly_client                # LOCAL DEPENDENCY
  serverpod_flutter: 3.2.3
```

---

## What `serverpod generate` Does

1. Scans `pilly_server/lib/src/` for `*endpoint.dart` files
2. Parses public methods in each endpoint
3. Generates `pilly_server/lib/src/generated/*` (server side)
4. Reads `client_package_path` from `generator.yaml`
5. Generates `pilly_client/lib/src/protocol/*` (client side)

**Result**: Type-safe client methods that match server endpoints.

---

## Package Detection

**Server Package**:
- Has `config/generator.yaml` with `type: server`
- Depends on `serverpod`

**Client Package**:
- Located at path from `generator.yaml`
- Depends on `serverpod_client`
- Contains `lib/src/protocol/protocol.dart`

**Flutter Package**:
- Depends on `flutter` SDK
- Depends on local `pilly_client` package
- Contains `lib/main.dart`

---

## ServerPod Boost Integration

### Where to Install?

**Install in SERVER package**: `pilly_server/.ai/boost/`

**Why**:
- Server is source of truth
- Code generation happens here
- Can access all packages via relative paths

### Key MCP Tools

1. **generate_protocol** - Wraps `serverpod generate`
2. **create_endpoint** - Scaffold new endpoint
3. **create_model** - Scaffold new model
4. **list_endpoints** - Show all endpoints
5. **validate** - Check before generation

### Skills Structure

```
.ai/boost/
├── core.dart.md           # ServerPod fundamentals
├── server/
│   ├── endpoints.md       # Endpoint development
│   └── models.md          # Data models
├── client/
│   └── usage.md           # Using generated client
└── flutter/
    └── integration.md     # Flutter client integration
```

---

## Type Safety Benefits

✅ **Compile-time checking** - Errors caught before runtime
✅ **IDE autocomplete** - Full IntelliSense support
✅ **Refactoring** - Rename propagates through entire stack
✅ **No manual API code** - Client methods generated automatically
✅ **No documentation drift** - Protocol always matches code

---

## Common Pitfalls

❌ **Don't**: Edit generated files in `lib/src/generated/` or `lib/src/protocol/`
✅ **Do**: Run `serverpod generate` after modifying endpoints

❌ **Don't**: Make endpoint methods private (e.g., `_hello()`)
✅ **Do**: Keep methods public for generation

❌ **Don't**: Return non-serializable types
✅ **Do**: Use classes implementing `SerializableModel`

❌ **Don't**: Forget to regenerate after changes
✅ **Do**: Run `serverpod generate` before using in Flutter

---

## Quick Commands

```bash
# Generate protocol
cd pilly_server && serverpod generate

# Start server
cd pilly_server && dart bin/main.dart

# Run Flutter app
cd pilly_flutter && flutter run

# Run tests
cd pilly_server && dart test
cd pilly_flutter && flutter test
```

---

## References

- **Full Analysis**: `PILLY_ANALYSIS.md`
- **Package Detection**: `PACKAGE_DETECTION.md`
- **Code Generation**: `CODE_GENERATION_FLOW.md`
- **Visual Guide**: `VISUAL_ARCHITECTURE.md`

---

## Summary

| Aspect | Detail |
|--------|--------|
| **Architecture** | 3-package monorepo |
| **Code Flow** | Server → generate → Client → Flutter |
| **Generation** | `serverpod generate` (from server package) |
| **Config** | `config/generator.yaml` |
| **Type Safety** | Automatic (Dart) |
| **Boost Install** | Server package (`pilly_server/.ai/boost/`) |
| **Key Benefit** | Type-safe API without manual code |
