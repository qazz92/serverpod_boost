/// MCP Resource interface
library serverpod_boost.mcp.mcp_resource;

/// Base interface for all MCP resources
abstract class McpResource {
  /// Resource URI (must be unique)
  String get uri;

  /// Resource name
  String get name;

  /// Resource description
  String get description;

  /// Resource MIME type
  String get mimeType;

  /// Read the resource content
  Future<String> read();

  /// Get resource metadata as a map (for resource listing)
  Map<String, dynamic> get metadata => {
        'uri': uri,
        'name': name,
        'description': description,
        'mimeType': mimeType,
      };

  @override
  String toString() => 'McpResource(uri: $uri, name: $name)';
}

/// Base class for resources
abstract class McpResourceBase implements McpResource {
  // Base implementation can override specific methods if needed
}

/// Resource exception
class McpResourceException implements Exception {
  final String message;
  McpResourceException(this.message);

  @override
  String toString() => 'McpResourceException: $message';
}

/// Resource registry for managing multiple resources
class McpResourceRegistry {
  final Map<String, McpResource> _resources = {};

  /// Register a resource
  void register(McpResource resource) {
    if (_resources.containsKey(resource.uri)) {
      throw ArgumentError('Resource ${resource.uri} is already registered');
    }
    _resources[resource.uri] = resource;
  }

  /// Unregister a resource by URI
  void unregister(String uri) {
    _resources.remove(uri);
  }

  /// Get a resource by URI
  McpResource? getResource(String uri) => _resources[uri];

  /// Check if a resource exists
  bool hasResource(String uri) => _resources.containsKey(uri);

  /// List all resource URIs
  List<String> get resourceUris => _resources.keys.toList();

  /// List all resource metadata
  List<Map<String, dynamic>> get resourceMetadata =>
      _resources.values.map((r) => r.metadata).toList();

  /// Read a resource by URI
  Future<String> read(String uri) async {
    final resource = getResource(uri);
    if (resource == null) {
      throw McpResourceException('Resource not found: $uri');
    }
    return resource.read();
  }

  /// Clear all resources
  void clear() => _resources.clear();

  /// Get resource count
  int get count => _resources.length;
}
