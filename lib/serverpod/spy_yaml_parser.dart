/// Parser for ServerPod .spy.yaml model definition files
///
/// .spy.yaml files are the source of truth for protocol models.
/// Generated Dart files are created from these YAML files.
library serverpod_boost.serverpod.spy_yaml_parser;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Protocol model definition parsed from .spy.yaml
class SpyYamlModel {
  /// Model class name
  final String className;

  /// Field definitions
  final List<SpyYamlField> fields;

  /// Original file path
  final String filePath;

  SpyYamlModel({
    required this.className,
    required this.fields,
    required this.filePath,
  });

  /// Model namespace (derived from directory structure)
  String get namespace {
    final dir = p.dirname(filePath);
    final parts = p.split(dir);
    // Extract namespace from path like: .../lib/src/greetings/greeting.spy.yaml
    final srcIndex = parts.lastIndexOf('src');
    if (srcIndex >= 0 && srcIndex + 1 < parts.length) {
      return parts.sublist(srcIndex + 1).join('/');
    }
    return '';
  }

  @override
  String toString() {
    return 'SpyYamlModel(className: $className, namespace: $namespace, fields: ${fields.length}, filePath: $filePath)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpyYamlModel &&
        other.className == className &&
        other.filePath == filePath &&
        _listEquals(other.fields, fields);
  }

  @override
  int get hashCode => Object.hash(className, filePath, fields.length);

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Field definition from .spy.yaml
class SpyYamlField {
  /// Field name
  final String name;

  /// Field type (String, int, DateTime, UserModel, etc.)
  final String type;

  /// Whether field is optional (has ? suffix in type)
  final bool isOptional;

  SpyYamlField({
    required this.name,
    required this.type,
    this.isOptional = false,
  });

  /// Get the Dart type with nullable suffix
  String get dartType => isOptional ? '$type?' : type;

  @override
  String toString() {
    return 'SpyYamlField(name: $name, type: $type, isOptional: $isOptional)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpyYamlField &&
        other.name == name &&
        other.type == type &&
        other.isOptional == isOptional;
  }

  @override
  int get hashCode => Object.hash(name, type, isOptional);
}

/// Parser for .spy.yaml files
class SpyYamlParser {
  /// Parse a single .spy.yaml file
  static SpyYamlModel? parseFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap?;

    if (yaml == null) return null;

    final className = yaml['class'] as String?;
    if (className == null || className.isEmpty) return null;

    final fields = <SpyYamlField>[];

    final fieldsMap = yaml['fields'] as YamlMap?;
    if (fieldsMap != null) {
      fieldsMap.forEach((key, value) {
        final fieldName = key as String;
        final fieldType = value as String;
        final isOptional = fieldType.endsWith('?');

        fields.add(SpyYamlField(
          name: fieldName,
          type: isOptional ? fieldType.replaceAll('?', '') : fieldType,
          isOptional: isOptional,
        ));
      });
    }

    return SpyYamlModel(
      className: className,
      fields: fields,
      filePath: filePath,
    );
  }

  /// Find all .spy.yaml files in the server package
  static List<String> findSpyYamlFiles(String serverPackagePath) {
    final files = <String>[];

    final libDir = Directory(p.join(serverPackagePath, 'lib', 'src'));
    if (!libDir.existsSync()) return files;

    // Recursively find all .spy.yaml files
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.spy.yaml')) {
        files.add(entity.path);
      }
    }

    return files;
  }

  /// Parse all .spy.yaml models in the server package
  static List<SpyYamlModel> parseAll(String serverPackagePath) {
    final files = findSpyYamlFiles(serverPackagePath);
    final models = <SpyYamlModel>[];

    for (final file in files) {
      final model = parseFile(file);
      if (model != null) {
        models.add(model);
      }
    }

    return models;
  }

  /// Get field pattern for parsing (utility)
  static RegExp get fieldPattern => RegExp(r'^\s+(\w+):\s*(\S+)');
}
