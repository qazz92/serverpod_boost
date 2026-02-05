/// Project context for template rendering
///
/// Provides information about the current ServerPod project
/// for use in skill templates.
library serverpod_boost.project_context;

import 'serverpod/serverpod_locator.dart';
import 'serverpod/spy_yaml_parser.dart';

/// Database type used by the project
enum DatabaseType {
  postgres,
  sqlite,
  unknown,
}

/// Project context information
class ProjectContext {
  /// Project name
  final String projectName;

  /// ServerPod version
  final String serverpodVersion;

  /// Project root path
  final String rootPath;

  /// Database type
  final DatabaseType databaseType;

  /// Whether the project has endpoints
  final bool hasEndpoints;

  /// Whether the project has models
  final bool hasModels;

  /// Whether the project has migrations
  final bool hasMigrations;

  /// Whether the project uses Redis
  final bool usesRedis;

  /// List of endpoint information
  final List<EndpointInfo> endpoints;

  /// List of model information
  final List<ModelInfo> models;

  /// List of migration information
  final List<MigrationInfo> migrations;

  const ProjectContext({
    required this.projectName,
    required this.serverpodVersion,
    required this.rootPath,
    this.databaseType = DatabaseType.unknown,
    this.hasEndpoints = false,
    this.hasModels = false,
    this.hasMigrations = false,
    this.usesRedis = false,
    this.endpoints = const [],
    this.models = const [],
    this.migrations = const [],
  });

  /// Create project context from a ServerPod project
  factory ProjectContext.fromProject(ServerPodProject project) {
    final projectName = _extractProjectName(project.rootPath);

    return ProjectContext(
      projectName: projectName,
      serverpodVersion: '3.2.3', // TODO: Extract from pubspec.yaml
      rootPath: project.rootPath,
      databaseType: _detectDatabaseType(project),
      hasEndpoints: project.endpointFiles.isNotEmpty,
      hasModels: project.modelFiles != null && project.modelFiles!.isNotEmpty,
      hasMigrations: project.migrationFiles.isNotEmpty,
      usesRedis: _detectRedisUsage(project),
      endpoints: _extractEndpointInfo(project),
      models: _extractModelInfo(project),
      migrations: _extractMigrationInfo(project),
    );
  }

  /// Get endpoint count
  int get endpointCount => endpoints.length;

  /// Get model count
  int get modelCount => models.length;

  /// Get migration count
  int get migrationCount => migrations.length;

  /// Convert to template variables map
  Map<String, dynamic> toTemplateVars() {
    return {
      'project_name': projectName,
      'serverpod_version': serverpodVersion,
      'root_path': rootPath,
      'database_type': databaseType.name,
      'uses_postgres': databaseType == DatabaseType.postgres,
      'uses_sqlite': databaseType == DatabaseType.sqlite,
      'has_endpoints': hasEndpoints,
      'endpoint_count': endpointCount,
      'has_models': hasModels,
      'model_count': modelCount,
      'has_migrations': hasMigrations,
      'migration_count': migrationCount,
      'uses_redis': usesRedis,
      'endpoints': endpoints.map((e) => e.toJson()).toList(),
      'models': models.map((m) => m.toJson()).toList(),
      'migrations': migrations.map((m) => m.toJson()).toList(),
    };
  }

  static String _extractProjectName(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : 'serverpod_project';
  }

  static DatabaseType _detectDatabaseType(ServerPodProject project) {
    // TODO: Check config files for database type
    return DatabaseType.postgres;
  }

  static bool _detectRedisUsage(ServerPodProject project) {
    // TODO: Check config files for Redis
    return false;
  }

  static List<EndpointInfo> _extractEndpointInfo(ServerPodProject project) {
    // TODO: Parse endpoint files for detailed info
    return project.endpointFiles.map((path) {
      final name = path.split('/').last.replaceAll('_endpoint.dart', '');
      return EndpointInfo(
        name: name,
        file: path,
        methodCount: 0, // TODO: Parse methods
      );
    }).toList();
  }

  static List<ModelInfo> _extractModelInfo(ServerPodProject project) {
    // TODO: Parse model files
    return [];
  }

  static List<MigrationInfo> _extractMigrationInfo(ServerPodProject project) {
    return project.migrationFiles.map((file) {
      final name = file.path.split('/').last;
      return MigrationInfo(
        name: name,
        file: file.path,
      );
    }).toList();
  }
}

/// Information about an endpoint
class EndpointInfo {
  final String name;
  final String file;
  final int methodCount;
  final List<MethodInfo> methods;

  const EndpointInfo({
    required this.name,
    required this.file,
    this.methodCount = 0,
    this.methods = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'file': file,
      'method_count': methodCount,
      'methods': methods.map((m) => m.toJson()).toList(),
    };
  }
}

/// Information about a method in an endpoint
class MethodInfo {
  final String name;
  final String returnType;
  final String signature;
  final int lineNumber;

  const MethodInfo({
    required this.name,
    required this.returnType,
    required this.signature,
    required this.lineNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'return_type': returnType,
      'signature': signature,
      'line_number': lineNumber,
    };
  }
}

/// Information about a model
class ModelInfo {
  final String name;
  final String file;
  final String? namespace;
  final List<FieldInfo> fields;

  const ModelInfo({
    required this.name,
    required this.file,
    this.namespace,
    this.fields = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'class_name': name,
      'file': file,
      'namespace': namespace,
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }
}

/// Information about a field in a model
class FieldInfo {
  final String name;
  final String type;
  final bool isNullable;

  const FieldInfo({
    required this.name,
    required this.type,
    this.isNullable = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'is_nullable': isNullable,
    };
  }
}

/// Information about a migration
class MigrationInfo {
  final String name;
  final String file;

  const MigrationInfo({
    required this.name,
    required this.file,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'file': file,
    };
  }
}
