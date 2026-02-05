/// Agent Detector
///
/// Detects installed AI editor agents on the system and in the current project.
library serverpod_boost.agents.agent_detector;

import 'agent.dart';
import 'claude_code_agent.dart';
import 'opencode_agent.dart';

/// Agent detector for finding installed AI editors
class AgentDetector {
  /// List of all supported agents
  static final List<Agent> _allAgents = [
    ClaudeCodeAgent(),
    OpenCodeAgent(),
  ];

  /// Detect all installed agents on the system
  static Future<List<Agent>> detect() async {
    final agents = <Agent>[];

    for (final agent in _allAgents) {
      if (await agent.isInstalled()) {
        agents.add(agent);
      }
    }

    return agents;
  }

  /// Detect all agents used in the current project
  static Future<List<Agent>> detectInProject(String basePath) async {
    final agents = <Agent>[];

    for (final agent in _allAgents) {
      if (await agent.isInProject(basePath)) {
        agents.add(agent);
      }
    }

    return agents;
  }

  /// Detect all agents (both system and project)
  static Future<List<Agent>> detectAll({required String basePath}) async {
    final systemAgents = await detect();
    final projectAgents = await detectInProject(basePath);

    // Combine and deduplicate
    final allAgents = <Agent>{};
    for (final agent in [...systemAgents, ...projectAgents]) {
      allAgents.add(agent);
    }

    return allAgents.toList();
  }

  /// Detect specific agent by name
  static Future<bool> isAgentInstalled(String agentName) async {
    for (final agent in _allAgents) {
      if (agent.name == agentName) {
        return await agent.isInstalled();
      }
    }
    return false;
  }

  /// Check if specific agent is used in project
  static Future<bool> isAgentInProject(String agentName, String basePath) async {
    for (final agent in _allAgents) {
      if (agent.name == agentName) {
        return await agent.isInProject(basePath);
      }
    }
    return false;
  }

  /// Get agent by name
  static Agent? getAgent(String agentName) {
    for (final agent in _allAgents) {
      if (agent.name == agentName) {
        return agent;
      }
    }
    return null;
  }

  /// List all supported agent names
  static List<String> get supportedAgentNames {
    return _allAgents.map((agent) => agent.name).toList();
  }

  /// List all supported agent display names
  static List<String> get supportedAgentDisplayNames {
    return _allAgents.map((agent) => agent.displayName).toList();
  }
}
