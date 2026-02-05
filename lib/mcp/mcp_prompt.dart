/// MCP Prompt interface
library serverpod_boost.mcp.mcp_prompt;

/// Base interface for all MCP prompts
abstract class McpPrompt {
  /// Prompt name (must be unique)
  String get name;

  /// Prompt description
  String get description;

  /// Input arguments schema
  Map<String, dynamic> get argumentsSchema;

  /// Generate the prompt
  Future<String> generate(Map<String, dynamic> arguments);

  /// Get prompt metadata
  Map<String, dynamic> get metadata => {
        'name': name,
        'description': description,
        'arguments': argumentsSchema,
      };
}

/// Prompt registry
class McpPromptRegistry {
  final Map<String, McpPrompt> _prompts = {};

  /// Register a prompt
  void register(McpPrompt prompt) {
    if (_prompts.containsKey(prompt.name)) {
      throw ArgumentError('Prompt ${prompt.name} is already registered');
    }
    _prompts[prompt.name] = prompt;
  }

  /// Get a prompt by name
  McpPrompt? getPrompt(String name) => _prompts[name];

  /// Check if a prompt exists
  bool hasPrompt(String name) => _prompts.containsKey(name);

  /// List all prompt names
  List<String> get promptNames => _prompts.keys.toList();

  /// List all prompt metadata
  List<Map<String, dynamic>> get promptMetadata =>
      _prompts.values.map((p) => p.metadata).toList();

  /// Generate a prompt by name
  Future<String> generate(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    final prompt = getPrompt(name);
    if (prompt == null) {
      throw McpPromptException('Prompt not found: $name');
    }
    return prompt.generate(arguments);
  }

  /// Clear all prompts
  void clear() => _prompts.clear();

  /// Get prompt count
  int get count => _prompts.length;
}

/// Prompt exception
class McpPromptException implements Exception {
  final String message;
  McpPromptException(this.message);

  @override
  String toString() => 'McpPromptException: $message';
}
