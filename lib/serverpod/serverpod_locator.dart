/// ServerPod Service Locator
///
/// Central access point for ServerPod project information.
/// Provides methods to locate and access various parts of a ServerPod project.
library serverpod_boost.serverpod.serverpod_locator;

import 'dart:io';
import 'package:path/path.dart' as p;

import 'project_root.dart';
import 'spy_yaml_parser.dart';
import 'method_parser.dart';

/// ServerPod project information
class ServerPodProject {
  /// Project root (monorepo root)
  final String rootPath;

  /// Server package path
  final String? serverPath;

  /// Client package path
  final String? clientPath;

  /// Flutter package path
  final String? flutterPath;

  /// Config directory path
  String? get configPath {
    if (serverPath == null) return null;
    final configDir = Directory(p.join(serverPath!, 'config'));
    return configDir.existsSync() ? configDir.path : null;
  }

  /// Migrations directory path
  String? get migrationsPath {
    if (serverPath == null) return null;
    final migrationsDir = Directory(p.join(serverPath!, 'migrations'));
    return migrationsDir.existsSync() ? migrationsDir.path : null;
  }

  ServerPodProject({
    required this.rootPath,
    this.serverPath,
    this.clientPath,
    this.flutterPath,
  });

  /// Get all .spy.yaml model definitions
  List<SpyYamlModel> get models {
    if (serverPath == null) return [];
    return SpyYamlParser.parseAll(serverPath!);
  }

  /// Get all model file paths
  List<String> get modelFiles {
    if (serverPath == null) return [];
    final models = SpyYamlParser.parseAll(serverPath!);
    return models.map((m) => m.filePath).toList();
  }

  /// Get all endpoint files
  List<String> get endpointFiles {
    if (serverPath == null) return [];
    return MethodParser.findEndpointFiles(serverPath!);
  }

  /// Check if project is valid
  bool get isValid => serverPath != null && configPath != null;

  /// Create from detected project root
  static ServerPodProject? detect([String? currentPath]) {
    final root = ProjectRoot.detect(currentPath);

    if (!ProjectRoot.isValidServerPodProject(root)) {
      return null;
    }

    final serverPath = ProjectRoot.findServerPackage(root);
    final clientPath = ProjectRoot.findClientPackage(root);

    // Find flutter package
    String? flutterPath;
    final dir = Directory(root);
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.endsWith('_flutter')) {
          flutterPath = entity.path;
          break;
        }
      }
    }

    return ServerPodProject(
      rootPath: root,
      serverPath: serverPath,
      clientPath: clientPath,
      flutterPath: flutterPath,
    );
  }

  /// Get config file path for environment
  File? getConfigFile(String environment) {
    if (configPath == null) return null;
    final file = File(p.join(configPath!, '$environment.yaml'));
    return file.existsSync() ? file : null;
  }

  /// List all migration files
  List<File> get migrationFiles {
    final path = migrationsPath;
    if (path == null) return [];

    final dir = Directory(path);
    if (!dir.existsSync()) return [];

    return dir.listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }
}

/// ServerPod service locator
///
/// Use this class to access ServerPod project information.
class ServerPodLocator {
  /// Cached project instance
  static ServerPodProject? _cachedProject;

  /// Get the current ServerPod project
  ///
  /// Caches the result for subsequent calls.
  static ServerPodProject? getProject({String? currentPath, bool forceReload = false}) {
    if (forceReload) {
      _cachedProject = null;
    }

    _cachedProject ??= ServerPodProject.detect(currentPath);
    return _cachedProject;
  }

  /// Reset cached project (useful for testing)
  static void resetCache() {
    _cachedProject = null;
  }

  /// Check if we're in a valid ServerPod project
  static bool isInServerPodProject({String? currentPath}) {
    final project = getProject(currentPath: currentPath);
    return project?.isValid ?? false;
  }
}
