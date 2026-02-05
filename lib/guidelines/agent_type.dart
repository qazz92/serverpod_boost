/// Agent types for guideline generation
///
/// Defines the different AI agents/code editors that ServerPod Boost
/// can generate guidelines for.
library serverpod_boost.guidelines.agent_type;

/// Supported AI agent types
enum AgentType {
  /// Claude Code (Anthropic's CLI tool)
  claudeCode,

  /// OpenCode AI assistant
  openCode,

  /// Cursor AI editor
  cursor,

  /// GitHub Copilot
  copilot,
}

/// Extension to get display names and properties for AgentType
extension AgentTypeExtension on AgentType {
  /// Get the display name for the agent type
  String get displayName {
    switch (this) {
      case AgentType.claudeCode:
        return 'Claude Code';
      case AgentType.openCode:
        return 'OpenCode';
      case AgentType.cursor:
        return 'Cursor';
      case AgentType.copilot:
        return 'GitHub Copilot';
    }
  }

  /// Get the agent identifier
  String get identifier {
    switch (this) {
      case AgentType.claudeCode:
        return 'claude-code';
      case AgentType.openCode:
        return 'opencode';
      case AgentType.cursor:
        return 'cursor';
      case AgentType.copilot:
        return 'copilot';
    }
  }

  /// Check if this agent supports streaming responses
  bool get supportsStreaming {
    switch (this) {
      case AgentType.claudeCode:
      case AgentType.openCode:
      case AgentType.cursor:
        return true;
      case AgentType.copilot:
        return false;
    }
  }

  /// Check if this agent has file system access
  bool get hasFileSystemAccess {
    switch (this) {
      case AgentType.claudeCode:
      case AgentType.openCode:
      case AgentType.cursor:
        return true;
      case AgentType.copilot:
        return false;
    }
  }
}
