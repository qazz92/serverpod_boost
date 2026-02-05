import 'dart:io';
import 'package:path/path.dart' as p;

/// Project Root Detection for ServerPod Monorepos
///
/// ServerPod v3 projects use a 3-package structure:
/// - {project}_server/  (source of truth)
/// - {project}_client/  (generated)
/// - {project}_flutter/ (app)
///
/// Boost installs at: {monorepo_root}/.ai/boost/
///
/// Detection Strategy:
/// 1. Check environment variable: SERVERPOD_BOOST_PROJECT_ROOT
/// 2. If in .ai/boost/, navigate up to monorepo root
/// 3. Detect *_server package (go up to find monorepo root)
/// 4. Fallback to current directory
class ProjectRoot {
  /// Detect the ServerPod project root
  static String detect([String? currentPath]) {
    currentPath ??= p.normalize(Directory.current.path);

    // 1. Environment variable
    final envRoot = Platform.environment['SERVERPOD_BOOST_PROJECT_ROOT'];
    if (envRoot != null && Directory(envRoot).existsSync()) {
      return envRoot;
    }

    // 2. If in .ai/boost/, navigate up
    if (currentPath.contains('.ai${p.separator}boost')) {
      final root = currentPath.split('.ai${p.separator}boost')[0];
      if (root.isNotEmpty && Directory(root).existsSync()) {
        return p.normalize(root);
      }
    }

    // 3. Detect *_server package
    final serverMatch = RegExp(r'(.+[/\\])\w+_server').firstMatch(currentPath);
    if (serverMatch != null) {
      final root = serverMatch.group(1)!;
      if (Directory(root).existsSync()) {
        return p.normalize(root);
      }
    }

    // 4. Fallback
    return currentPath;
  }

  /// Find the server package directory
  static String? findServerPackage(String projectRoot) {
    final dir = Directory(projectRoot);
    if (!dir.existsSync()) return null;

    // Look for *_server directory
    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.endsWith('_server')) {
          return entity.path;
        }
      }
    }
    return null;
  }

  /// Find the client package directory
  static String? findClientPackage(String projectRoot) {
    final dir = Directory(projectRoot);
    if (!dir.existsSync()) return null;

    for (final entity in dir.listSync()) {
      if (entity is Directory) {
        final name = p.basename(entity.path);
        if (name.endsWith('_client')) {
          return entity.path;
        }
      }
    }
    return null;
  }

  /// Validate this is a ServerPod project
  static bool isValidServerPodProject(String path) {
    final serverPackage = findServerPackage(path);
    if (serverPackage == null) return false;

    // Check for server.dart
    final serverFile = File(p.join(serverPackage, 'lib', 'server.dart'));
    return serverFile.existsSync();
  }
}
