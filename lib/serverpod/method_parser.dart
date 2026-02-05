/// Parser for ServerPod endpoint method signatures
///
/// Extracts method information from endpoint class definitions.
library serverpod_boost.serverpod.method_parser;

import 'dart:io';
import 'package:path/path.dart' as p;

/// Parsed method signature from endpoint
class EndpointMethod {
  EndpointMethod({
    required this.name,
    required this.returnType,
    required this.parameters,
    required this.filePath,
    required this.lineNumber,
  });

  /// Method name
  final String name;

  /// Return type (e.g., 'Greeting', 'List<User>', 'void')
  final String returnType;

  /// All parameters including Session session
  final List<MethodParameter> parameters;

  /// Source file path
  final String filePath;

  /// Line number in source file
  final int lineNumber;

  /// Get parameters excluding Session session
  List<MethodParameter> get userParameters {
    return parameters.where((p) => !p.isSession).toList();
  }

  /// Method signature as string
  String get signature {
    final params = parameters.map((p) => p.toString()).join(', ');
    return 'Future<$returnType> $name($params)';
  }

  @override
  String toString() {
    return 'EndpointMethod(name: $name, returnType: $returnType, parameters: $parameters, filePath: $filePath, lineNumber: $lineNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EndpointMethod &&
        other.name == name &&
        other.returnType == returnType &&
        other.lineNumber == lineNumber &&
        _listEquals(other.parameters, parameters);
  }

  @override
  int get hashCode {
    var hash = Object.hash(name, returnType, lineNumber);
    for (final param in parameters) {
      hash = Object.hash(hash, param);
    }
    return hash;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Method parameter definition
class MethodParameter {
  MethodParameter({
    required this.type,
    required this.name,
    this.isSession = false,
  });

  /// Parameter type
  final String type;

  /// Parameter name
  final String name;

  /// Whether this is the Session session parameter
  final bool isSession;

  @override
  String toString() => '$type $name';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MethodParameter &&
        other.type == type &&
        other.name == name &&
        other.isSession == isSession;
  }

  @override
  int get hashCode => Object.hash(type, name, isSession);
}

/// Parser for endpoint method signatures
class MethodParser {
  /// RegExp pattern for matching endpoint methods
  static final _methodPattern = RegExp(
    r'Future\s*'                     // Future
    r'<'
    r'(\w+(?:<[^>]+>)?)>'            // Return type: Greeting, List<User>, etc.
    r'\s*'
    r'(\w+)'                         // Method name
    r'\s*'
    r'\(\s*'
    r'Session\s+session'             // First param: Session session
    r'\s*,\s*'
    r'([^)]+)'                       // Remaining params
    r'\)',
    multiLine: true,
  );

  /// Parse all methods from an endpoint file
  static List<EndpointMethod> parseFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return [];

    final content = file.readAsLinesSync();
    final methods = <EndpointMethod>[];

    for (var i = 0; i < content.length; i++) {
      final line = content[i];

      // Skip comments and empty lines
      if (line.trim().isEmpty || line.trim().startsWith('//')) {
        continue;
      }

      final match = _methodPattern.firstMatch(line);
      if (match != null) {
        final returnType = match.group(1)!;
        final methodName = match.group(2)!;
        final paramsStr = match.group(3)!;

        methods.add(EndpointMethod(
          name: methodName,
          returnType: returnType,
          parameters: _parseParameters(paramsStr),
          filePath: filePath,
          lineNumber: i + 1,
        ));
      }
    }

    return methods;
  }

  /// Parse parameter string
  static List<MethodParameter> _parseParameters(String paramsStr) {
    final params = <MethodParameter>[];

    // Add Session parameter first (always present)
    params.add(MethodParameter(
      type: 'Session',
      name: 'session',
      isSession: true,
    ));

    // Parse remaining parameters
    final parts = paramsStr.split(',');
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;

      final paramParts = trimmed.split(RegExp(r'\s+'));
      if (paramParts.length >= 2) {
        final type = paramParts[0];
        final name = paramParts[1];

        params.add(MethodParameter(
          type: type,
          name: name.replaceAll(RegExp(r'[{}]?'), ''), // Remove default value markers
        ));
      }
    }

    return params;
  }

  /// Find all endpoint files in the server package
  static List<String> findEndpointFiles(String serverPackagePath) {
    final files = <String>[];

    final libDir = Directory(p.join(serverPackagePath, 'lib', 'src'));
    if (!libDir.existsSync()) return files;

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File &&
          entity.path.endsWith('_endpoint.dart') &&
          !entity.path.contains('generated')) {
        files.add(entity.path);
      }
    }

    return files;
  }
}
