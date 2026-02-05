/// Guideline composer
///
/// Composes comprehensive guidelines for AI agents working with ServerPod projects.
library serverpod_boost.guidelines.guideline_composer;

import '../project_context.dart';
import '../skills/skill_composer.dart';
import 'agent_type.dart';

/// Exception thrown when guideline composition fails
class GuidelineCompositionException implements Exception {
  final String message;
  final AgentType? agentType;

  const GuidelineCompositionException(this.message, [this.agentType]);

  @override
  String toString() {
    if (agentType != null) {
      return 'GuidelineCompositionException ($agentType): $message';
    }
    return 'GuidelineCompositionException: $message';
  }
}

/// Exception thrown when an invalid agent type is provided
class InvalidAgentTypeException implements Exception {
  final String agentTypeString;

  const InvalidAgentTypeException(this.agentTypeString);

  @override
  String toString() {
    return 'InvalidAgentTypeException: Unknown agent type "$agentTypeString". '
        'Valid types are: ${AgentType.values.map((t) => t.identifier).join(', ')}';
  }
}

/// Exception thrown when skill list is empty
class EmptySkillListException implements Exception {
  final AgentType agentType;

  const EmptySkillListException(this.agentType);

  @override
  String toString() {
    return 'EmptySkillListException: Cannot compose guidelines for ${agentType.displayName} '
        'without any skills. Provide at least one skill name.';
  }
}

/// Composes guidelines for AI agents working with ServerPod
///
/// The GuidelineComposer combines base agent guidelines with composed skills
/// and project context to create comprehensive instructions for AI agents.
class GuidelineComposer {
  /// Skill composer for composing skill sections
  final SkillComposer skillComposer;

  /// Create a new guideline composer
  ///
  /// Requires a [SkillComposer] instance for composing skill sections.
  const GuidelineComposer({
    required this.skillComposer,
  });

  /// Compose guidelines for an AI agent
  ///
  /// Combines base agent guidelines with composed skills and project context
  /// to create comprehensive instructions.
  ///
  /// Parameters:
  /// - [agent]: The type of AI agent
  /// - [skillNames]: List of skill names to include
  /// - [context]: Project context information
  ///
  /// Throws [EmptySkillListException] if [skillNames] is empty.
  /// Throws [SkillNotFoundException] if any skill is not found.
  /// Throws [UnsatisfiedDependencyException] if skill dependencies are not met.
  /// Throws [CircularDependencyException] if circular dependencies exist.
  /// Throws [GuidelineCompositionException] if composition fails.
  ///
  /// Returns the composed guidelines as a formatted string.
  Future<String> composeForAgent(
    AgentType agent,
    List<String> skillNames,
    ProjectContext context,
  ) async {
    // Validate input
    if (skillNames.isEmpty) {
      throw EmptySkillListException(agent);
    }

    try {
      // Compose the different sections
      final baseGuidelines = _getAgentBaseGuidelines(agent);
      final skillsContent = await skillComposer.compose(skillNames, context);
      final projectContextSection = _buildProjectContext(context);

      // Combine all sections
      final buffer = StringBuffer();

      buffer.writeln(baseGuidelines);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln(skillsContent);
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('## Project Context');
      buffer.writeln();
      buffer.writeln(projectContextSection);

      return buffer.toString();
    } on SkillNotFoundException {
      rethrow;
    } on UnsatisfiedDependencyException {
      rethrow;
    } on CircularDependencyException {
      rethrow;
    } catch (e) {
      throw GuidelineCompositionException(
        'Failed to compose guidelines: $e',
        agent,
      );
    }
  }

  /// Compose guidelines with additional metadata
  ///
  /// Extends [composeForAgent] with optional metadata section.
  ///
  /// Parameters:
  /// - [agent]: The type of AI agent
  /// - [skillNames]: List of skill names to include
  /// - [context]: Project context information
  /// - [metadata]: Optional metadata to include
  ///
  /// Returns the composed guidelines with metadata section.
  Future<String> composeWithMetadata(
    AgentType agent,
    List<String> skillNames,
    ProjectContext context, {
    Map<String, dynamic>? metadata,
  }) async {
    final baseGuidelines = await composeForAgent(agent, skillNames, context);

    if (metadata == null || metadata.isEmpty) {
      return baseGuidelines;
    }

    final metadataSection = _buildMetadataSection(metadata);

    return '$baseGuidelines\n\n---\n\n## Metadata\n\n$metadataSection';
  }

  /// Get base guidelines for a specific agent type
  ///
  /// Returns agent-specific instructions and best practices.
  String _getAgentBaseGuidelines(AgentType agent) {
    switch (agent) {
      case AgentType.claudeCode:
        return _getClaudeCodeGuidelines();
      case AgentType.openCode:
        return _getOpenCodeGuidelines();
      case AgentType.cursor:
        return _getCursorGuidelines();
      case AgentType.copilot:
        return _getCopilotGuidelines();
    }
  }

  /// Get guidelines for Claude Code
  String _getClaudeCodeGuidelines() {
    return '''
# ServerPod Boost - AI Assistant Guidelines

You are an AI programming assistant working with a ServerPod project enhanced with ServerPod Boost.

## Project Overview

This project uses **ServerPod Boost** to provide AI-powered development tools and skills via MCP (Model Context Protocol) tools.

## Available MCP Tools

ServerPod Boost provides the following MCP tools to help you understand and work with this project:

### Essential Tools
- **application_info**: Get comprehensive project information (versions, endpoints, models, database config)
- **list_endpoints**: List all endpoints with their methods
- **endpoint_methods**: Get detailed method signatures for a specific endpoint
- **list_models**: List all protocol models with their fields
- **model_inspector**: Get detailed information about a specific model
- **database_schema**: Get the current database schema
- **migration_scanner**: List and analyze migrations

### Code Navigation
- **project_structure**: Get the complete project file tree
- **find_files**: Search for files by name pattern
- **read_file**: Read file contents
- **search_code**: Search for code patterns across the project

### Runtime Tools
- **call_endpoint**: Test endpoint methods directly
- **service_config**: Get service configuration details

### AI Skills System
- **list_skills**: List all available AI skills for ServerPod development
- **get_skill**: Retrieve the full content of a specific skill

## Using the Skills System

ServerPod Boost includes a dynamic skills system that provides specialized knowledge for different ServerPad development tasks:

1. **Discover available skills**:
   - Use the \`list_skills\` MCP tool to see all available skills
   - Skills are organized by category (serverpod, remote, etc.)
   - Each skill has tags, examples, and triggers for easy discovery

2. **Get skill content**:
   - Use the \`get_skill\` MCP tool with a skill name to retrieve its full content
   - Skills contain domain knowledge, best practices, and code patterns
   - Skills are dynamically loaded from the project\`.ai/skills\` directory

3. **Common skill categories**:
   - **core**: Core ServerPod concepts and architecture
   - **endpoints**: Endpoint development patterns
   - **models**: Model design and validation
   - **migrations**: Database migration strategies
   - **testing**: Testing patterns and best practices
   - **redis**: Caching with Redis
   - **authentication**: Auth implementation patterns
   - **webhooks**: Webhook handling

## Core Principles

1. **Understand the Project Context**
   - Start by using \`application_info\` to understand the project
   - Consider existing endpoints, models, and migrations
   - Respect the project\`s architecture and patterns

2. **ServerPod Best Practices**
   - Endpoints should be focused and single-purpose
   - Models should have clear validation rules
   - Use transactions for multi-step database operations
   - Implement proper error handling and logging

3. **Code Style**
   - Follow Dart style guide
   - Use meaningful variable and function names
   - Add documentation comments for public APIs
   - Keep functions small and focused

4. **Testing**
   - Write unit tests for business logic
   - Write integration tests for endpoints
   - Mock external dependencies
   - Test edge cases and error conditions

5. **Safety**
   - Always backup before making major changes
   - Run migrations in development first
   - Test changes locally before committing
   - Use version control branches

## Common Workflow

### Adding a New Endpoint
1. Use \`list_skills\` to find the \"endpoints\" skill
2. Use \`get_skill\` with \"endpoints\" to get endpoint development patterns
3. Create endpoint file in \`lib/src/endpoints/\`
4. Extend \`Endpoint\` class and define methods with \`@ApiCall\`
5. Add tests in \`test/\`

### Modifying a Model
1. Use \`model_inspector\` to understand the current model structure
2. Use \`get_skill\` with \"models\" to get model design patterns
3. Update model definition
4. Create migration for schema change
5. Update related endpoints and tests

### Debugging
- Check ServerPod logs in \`logs/\`
- Use database query logging
- Enable debug mode in config
- Use \`search_code\` to find usages of problematic code

## Skills Reference

The skills system is designed to be extensible. Skills are stored in:
\`.ai/skills/{category}/{skill}/SKILL.md.mustache\`

To add new skills:
1. Create a new directory under \`.ai/skills/\`
2. Add a \`SKILL.md.mustache\` file with the skill content
3. Optionally add a \`meta.yaml\` with metadata (tags, examples, triggers)
4. The skill will be automatically discovered by \`list_skills\`

---

**Note**: This project is enhanced with ServerPod Boost. Use the provided MCP tools to access project information and skills dynamically.
''';
  }

  /// Get guidelines for OpenCode
  String _getOpenCodeGuidelines() {
    return '''
# OpenCode Guidelines for ServerPod

You are OpenCode, an AI programming assistant working with a ServerPod project.

## Core Principles

1. **Project Understanding**
   - Analyze the project structure before suggesting changes
   - Consider the existing architecture and patterns
   - Maintain consistency with established conventions

2. **ServerPod Development**
   - Follow ServerPod's endpoint-based architecture
   - Use async/await for all I/O operations
   - Implement proper error handling
   - Validate all input data

3. **Code Quality**
   - Write clean, readable code
   - Use meaningful names
   - Add helpful comments
   - Keep functions focused

4. **Testing Strategy**
   - Test business logic independently
   - Write integration tests for endpoints
   - Mock external services
   - Cover error scenarios

## ServerPod Architecture

### Project Structure
\`\`\`
lib/src/
  endpoints/    # API endpoints
  models/       # Data models
migrations/     # Database migrations
test/           # Test files
\`\`\`

### Key Concepts
- **Endpoints**: Server-side API methods
- **Models**: Typed data structures
- **Sessions**: Request-scoped context
- **Migrations**: Database schema changes

## Development Guidelines

### When Adding Features
1. Understand requirements
2. Design the API surface
3. Implement with tests
4. Document usage
5. Test thoroughly

### When Fixing Bugs
1. Reproduce the issue
2. Identify root cause
3. Fix with tests
4. Verify no regressions
5. Document the fix

### When Refactoring
1. Ensure tests pass
2. Make small changes
3. Run tests frequently
4. Commit often
5. Update documentation
''';
  }

  /// Get guidelines for Cursor
  String _getCursorGuidelines() {
    return '''
# Cursor Guidelines for ServerPod

You are Cursor, an AI programming assistant working with a ServerPod project.

## Quick Reference

### ServerPod Basics
- Backend framework for Dart/Flutter
- Endpoint-based API architecture
- Type-safe models and serialization
- Built-in database migrations

### Project Layout
- \`lib/src/endpoints/\` - API endpoints
- \`lib/src/models/\` - Data models
- \`migrations/\` - Database migrations
- \`test/\` - Test files

### Common Patterns
\`\`\`dart
// Endpoint method
@ApiCall()
Future<MyModel> getData(Session session, String id) async {
  // Implementation
}

// Database query
final result = await session.db.query('SELECT * FROM table WHERE id = @id', {
  'id': id,
});
\`\`\`

## Best Practices

1. **Always validate input**
2. **Use transactions for multi-step operations**
3. **Handle errors gracefully**
4. **Write tests for new code**
5. **Document public APIs**

## Get Started
Review the project context below and ask if you need clarification on any aspect of the project.
''';
  }

  /// Get guidelines for GitHub Copilot
  String _getCopilotGuidelines() {
    return '''
# GitHub Copilot Guidelines for ServerPod

You are GitHub Copilot assisting with a ServerPod project.

## ServerPod Context

This is a ServerPod backend project with:
- Endpoint-based API architecture
- Type-safe data models
- Database migrations
- Async/await patterns

## Code Style Preferences

- Use descriptive names
- Keep functions focused
- Add doc comments for APIs
- Handle errors appropriately
- Write tests

## Common Patterns

### Endpoint Definition
\`\`\`dart
@ApiCall()
Future<Response> method(Session session, Request request) async {
  // Implementation
}
\`\`\`

### Database Access
\`\`\`dart
final data = await session.db.query(
  'SELECT * FROM table WHERE condition = @value',
  {'value': value},
);
\`\`\`

## Project-Specific Notes

Refer to the project context below for specific information about this project's structure and conventions.
''';
  }

  /// Build project context section
  ///
  /// Creates a formatted summary of the project context.
  String _buildProjectContext(ProjectContext context) {
    final buffer = StringBuffer();

    // Basic information
    buffer.writeln('**Project:** ${context.projectName}');
    buffer.writeln('**ServerPod Version:** ${context.serverpodVersion}');
    buffer.writeln('**Database:** ${context.databaseType.name}');
    buffer.writeln();

    // Project structure
    buffer.writeln('### Project Structure');
    buffer.writeln();
    buffer.writeln('- **Endpoints:** ${context.endpoints.length}');
    buffer.writeln('- **Models:** ${context.models.length}');
    buffer.writeln('- **Migrations:** ${context.migrations.length}');
    buffer.writeln();

    // Endpoints
    if (context.endpoints.isNotEmpty) {
      buffer.writeln('### Endpoints');
      buffer.writeln();
      for (final endpoint in context.endpoints) {
        buffer.writeln('- **${endpoint.name}**');
        if (endpoint.methodCount > 0) {
          buffer.writeln('  - Methods: ${endpoint.methodCount}');
        }
      }
      buffer.writeln();
    }

    // Models
    if (context.models.isNotEmpty) {
      buffer.writeln('### Models');
      buffer.writeln();
      for (final model in context.models) {
        buffer.writeln('- **${model.name}**');
        if (model.fields.isNotEmpty) {
          buffer.writeln('  - Fields: ${model.fields.length}');
        }
      }
      buffer.writeln();
    }

    // Migrations
    if (context.migrations.isNotEmpty) {
      buffer.writeln('### Migrations');
      buffer.writeln();
      for (final migration in context.migrations) {
        buffer.writeln('- ${migration.name}');
      }
      buffer.writeln();
    }

    // Additional info
    if (context.usesRedis) {
      buffer.writeln('**Note:** This project uses Redis for caching.');
    }

    return buffer.toString().trim();
  }

  /// Build metadata section
  ///
  /// Creates a formatted metadata section from key-value pairs.
  String _buildMetadataSection(Map<String, dynamic> metadata) {
    final buffer = StringBuffer();

    for (final entry in metadata.entries) {
      buffer.writeln('**${entry.key}:** ${entry.value}');
    }

    return buffer.toString().trim();
  }

  /// Parse agent type from string
  ///
  /// Converts a string identifier to an AgentType enum value.
  ///
  /// Throws [InvalidAgentTypeException] if the string is not recognized.
  static AgentType parseAgentType(String agentTypeString) {
    final normalized = agentTypeString.toLowerCase().replaceAll('-', '').replaceAll('_', '');

    for (final agentType in AgentType.values) {
      if (agentType.name.toLowerCase().replaceAll('_', '') == normalized ||
          agentType.identifier.toLowerCase() == agentTypeString.toLowerCase()) {
        return agentType;
      }
    }

    throw InvalidAgentTypeException(agentTypeString);
  }

  /// Get all supported agent types
  ///
  /// Returns a list of all available agent types.
  static List<AgentType> getSupportedAgentTypes() => AgentType.values;

  /// Check if an agent type is supported
  ///
  /// Returns true if the given agent type is supported.
  static bool isAgentTypeSupported(AgentType agentType) {
    return AgentType.values.contains(agentType);
  }
}
