# ServerPod Package Detection Algorithm

## Overview

Serverpod projects use a **3-package monorepo structure**. This document defines how ServerPod Boost should detect and validate all three packages.

## Detection Strategy

### Step 1: Locate Server Package

The server package is the **entry point** for detection.

**Indicators**:
1. `config/generator.yaml` exists with `type: server`
2. `pubspec.yaml` depends on `serverpod` package
3. Directory contains `lib/src/endpoints/` or `lib/src/generated/`

**Detection Code**:
```yaml
algorithm:
  scan_root_directory:
    - find_subdirectories_with("pubspec.yaml")
    - for_each_directory:
        - check_file_exists("config/generator.yaml")
        - parse_yaml("config/generator.yaml")
        - verify_field_equals("type", "server")
        - verify_dependency("serverpod")
        - if_all_pass: mark_as_server_package
```

### Step 2: Locate Client Package

The client package location is **defined in generator.yaml**.

**Source**: `config/generator.yaml` in server package
```yaml
client_package_path: ../pilly_client
```

**Detection Code**:
```yaml
algorithm:
  parse_client_location:
    - read_file("config/generator.yaml")
    - extract_field("client_package_path")
    - resolve_relative_path(from: server_package)
    - verify_exists:
        - pubspec.yaml
        - lib/src/protocol/protocol.dart
    - if_exists: mark_as_client_package
    - else: error("Client package not found at specified path")
```

### Step 3: Locate Flutter Package

The flutter package is a **sibling directory** that depends on the client.

**Indicators**:
1. `pubspec.yaml` depends on `flutter` SDK
2. `pubspec.yaml` depends on local client package
3. Contains `lib/main.dart`

**Detection Code**:
```yaml
algorithm:
  scan_flutter_packages:
    - find_sibling_directories_with("pubspec.yaml")
    - for_each_directory:
        - parse_yaml("pubspec.yaml")
        - verify_sdk_dependency("flutter")
        - verify_local_dependency(client_package_name)
        - if_all_pass: mark_as_flutter_package
```

## Validation Rules

### Server Package Validation

```dart
class ServerPackageValidator {
  static const requiredFiles = [
    'config/generator.yaml',
    'pubspec.yaml',
    'lib/server.dart',
    'bin/main.dart',
  ];

  static const requiredDependencies = [
    'serverpod',
  ];

  bool validate(String path) {
    return _checkRequiredFiles(path) &&
           _checkRequiredDependencies(path) &&
           _checkGeneratorConfig(path);
  }
}
```

### Client Package Validation

```dart
class ClientPackageValidator {
  static const requiredFiles = [
    'pubspec.yaml',
    'lib/pilly_client.dart',
    'lib/src/protocol/protocol.dart',
    'lib/src/protocol/client.dart',
  ];

  static const requiredDependencies = [
    'serverpod_client',
  ];

  bool validate(String path) {
    return _checkRequiredFiles(path) &&
           _checkRequiredDependencies(path) &&
           _checkGeneratedCode(path);
  }
}
```

### Flutter Package Validation

```dart
class FlutterPackageValidator {
  static const requiredFiles = [
    'pubspec.yaml',
    'lib/main.dart',
  ];

  static const requiredDependencies = [
    'flutter',  # SDK
    'serverpod_flutter',
  ];

  bool validate(String path) {
    return _checkRequiredFiles(path) &&
           _checkRequiredDependencies(path) &&
           _checkClientDependency(path);
  }
  
  bool _checkClientDependency(String path) {
    final pubspec = parsePubspec('$path/pubspec.yaml');
    final dependencies = pubspec['dependencies'] as Map;
    
    // Check for local path dependency to client package
    for (var dep in dependencies.entries) {
      if (dep.value is Map && dep.value['path'] != null) {
        final clientPath = resolvePath(dep.value['path'], from: path);
        return clientPath == detectedClientPackagePath;
      }
    }
    return false;
  }
}
```

## Directory Resolution

### Relative Path Handling

```dart
class PathResolver {
  /// Resolves a relative path from a base directory
  static String resolve(String relativePath, {required String from}) {
    final baseDir = Directory(from).absolute;
    final resolved = baseDir.parent.join(relativePath);
    return resolved.absolute.path;
  }
  
  /// Example:
  /// Server: /project/pilly_server
  /// Config: client_package_path: ../pilly_client
  /// Result: /project/pilly_client
}
```

## Detection Output

### Success Result

```json
{
  "success": true,
  "projectType": "serverpod",
  "root": "/Users/musinsa/always_summer/pilly",
  "packages": {
    "server": {
      "path": "/Users/musinsa/always_summer/pilly/pilly_server",
      "name": "pilly_server",
      "type": "server",
      "config": {
        "generator": "/Users/musinsa/always_summer/pilly/pilly_server/config/generator.yaml"
      }
    },
    "client": {
      "path": "/Users/musinsa/always_summer/pilly/pilly_client",
      "name": "pilly_client",
      "type": "client",
      "generated": true,
      "source": "server"
    },
    "flutter": {
      "path": "/Users/musinsa/always_summer/pilly/pilly_flutter",
      "name": "pilly_flutter",
      "type": "flutter",
      "dependsOn": ["client"]
    }
  }
}
```

### Error Results

```json
{
  "success": false,
  "error": "server_package_not_found",
  "message": "No ServerPod server package found in project",
  "suggestions": [
    "Ensure config/generator.yaml exists",
    "Verify pubspec.yaml includes serverpod dependency"
  ]
}

{
  "success": false,
  "error": "client_package_not_found",
  "message": "Client package not found at ../pilly_client",
  "location": "config/generator.yaml:client_package_path",
  "suggestions": [
    "Check that client_package_path is correct",
    "Run: serverpod generate to create client package"
  ]
}

{
  "success": false,
  "error": "flutter_package_not_found",
  "message": "No Flutter package found in project",
  "suggestions": [
    "Ensure Flutter package has flutter SDK dependency",
    "Verify Flutter package depends on local client package"
  ]
}
```

## Detection CLI

```bash
# Detect packages in current directory
boost detect

# Detect with verbose output
boost detect --verbose

# Detect specific project
boost detect --path=/path/to/project

# Output JSON
boost detect --format=json
```

## MCP Integration

```yaml
tools:
  detect_packages:
    description: Detect ServerPod packages in project
    handler: detectServerpodPackages
    returns:
      - Server package path
      - Client package path  
      - Flutter package path(s)
      - Validation status
```

## Testing

### Test Cases

1. **Standard 3-package project** ✅
2. **Server-only project** (client not yet generated)
3. **Multiple Flutter apps** (e.g., pilly_flutter_admin, pilly_flutter_user)
4. **Nested monorepo structure**
5. **Custom client package location**

### Mock Project Structure for Testing

```
/test_projects/
├── standard/                  # Standard 3-package
│   ├── app_server/
│   ├── app_client/
│   └── app_flutter/
├── server_only/              # Server only
│   └── app_server/
├── multi_flutter/            # Multiple Flutter apps
│   ├── app_server/
│   ├── app_client/
│   ├── app_flutter_user/
│   └── app_flutter_admin/
└── nested/                   # Nested structure
    └── monorepo/
        ├── packages/
        │   ├── server/
        │   ├── client/
        │   └── flutter/
        └── boost/
```

## Implementation Checklist

- [ ] Create `PackageDetector` class
- [ ] Implement server package detection
- [ ] Implement client package detection from generator.yaml
- [ ] Implement flutter package detection
- [ ] Add validation for all package types
- [ ] Create CLI command: `boost detect`
- [ ] Add JSON output option
- [ ] Write comprehensive tests
- [ ] Document error messages and suggestions
- [ ] Create MCP tool integration
