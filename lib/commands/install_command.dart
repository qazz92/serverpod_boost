/// install command
///
/// Installation of ServerPod Boost features.
/// Installs all features (guidelines, skills, MCP) by default.
library serverpod_boost.commands.install_command;

import 'dart:io';
import 'package:serverpod_boost/cli/command.dart';
import 'package:serverpod_boost/cli/console_helper.dart';
import 'package:serverpod_boost/install/install_utils.dart';
import 'package:serverpod_boost/serverpod/serverpod_locator.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';
import 'package:serverpod_boost/agents/agent_detector.dart';
import 'package:serverpod_boost/agents/agents.dart';
import 'package:serverpod_boost/guidelines/guideline_composer.dart';
import 'package:serverpod_boost/guidelines/guideline_writer.dart';
import 'package:serverpod_boost/skills/skill_composer.dart';
import 'package:serverpod_boost/skills/template_renderer.dart';
import 'package:serverpod_boost/project_context.dart';

/// Command to install ServerPod Boost features
class InstallCommand extends Command {
  /// Installation configuration
  late InstallConfig _config;

  /// ServerPod project
  late ServerPodProject? _project;

  @override
  String get name => 'install';

  @override
  String get description => 'Install ServerPod Boost features (guidelines, skills, MCP)';

  @override
  Future<void> run() async {
    try {
      // Detect ServerPod project
      _project = ServerPodLocator.getProject();
      if (_project == null || !_project!.isValid) {
        ConsoleHelper.error('Not a valid ServerPod project');
        ConsoleHelper.error('Please run this command from within a ServerPod project.');
        exit(1);
      }

      // Initialize with defaults
      _config = const InstallConfig();

      // Display header
      ConsoleHelper.header(
        'ServerPod Boost Installation',
        subtitle: 'v0.1.0',
      );

      ConsoleHelper.info('Project: ${_project!.rootPath}');
      ConsoleHelper.info('Server: ${_project!.serverPath}');
      ConsoleHelper.newLine();

      // Check for command-line flags
      final args = _parseArgs();

      if (args['interactive'] == true) {
        await _runInteractive();
      } else {
        await _runNonInteractive(args);
      }

      ConsoleHelper.outro(
        'Installation complete! 🚀',
        link: 'https://github.com/serverpod/serverpod_boost',
      );
    } catch (e) {
      ConsoleHelper.error('Installation failed: $e');
      exit(1);
    }
  }

  /// Parse command-line arguments
  Map<String, dynamic> _parseArgs() {
    final args = <String, dynamic>{};

    // Default: install all features
    args['features'] = ['guidelines', 'skills', 'mcp'];

    // Parse flags
    final rawArgs = Platform.environment['SERVERPOD_BOOST_ARGS']?.split(' ') ?? [];

    for (final arg in rawArgs) {
      if (arg == '--guidelines') {
        args['features'] = ['guidelines'];
      } else if (arg == '--skills') {
        args['features'] = ['skills'];
      } else if (arg == '--mcp') {
        args['features'] = ['mcp'];
      } else if (arg == '--interactive' || arg == '-i') {
        args['interactive'] = true;
      } else if (arg == '--overwrite') {
        args['overwrite'] = true;
      }
    }

    return args;
  }

  /// Run non-interactive installation
  Future<void> _runNonInteractive(Map<String, dynamic> args) async {
    final features = args['features'] as List<String>? ??
        ['guidelines', 'skills', 'mcp'];

    _config = InstallConfig(
      features: features,
      overwrite: args['overwrite'] == true,
    );

    await _executeInstallation();
  }

  /// Run interactive installation
  Future<void> _runInteractive() async {
    // Select features
    final features = await _selectFeatures();
    _config = _config.copyWith(features: features);

    ConsoleHelper.newLine();

    // Select skills if needed
    if (_config.installSkills) {
      final skills = await _selectSkills();
      _config = _config.copyWith(skills: skills);
      ConsoleHelper.newLine();
    }

    // Select agents if needed
    if (_config.installMcp) {
      final agents = await _selectAgents();
      _config = _config.copyWith(agents: agents);
      ConsoleHelper.newLine();
    }

    // Show confirmation
    final confirmed = await _confirmInstallation();
    if (!confirmed) {
      ConsoleHelper.warning('Installation cancelled');
      exit(0);
    }

    ConsoleHelper.newLine();

    // Execute installation
    await _executeInstallation();
  }

  /// Select features to install
  Future<List<String>> _selectFeatures() async {
    ConsoleHelper.subHeader('Select Features');

    final options = InstallFeature.all.map((f) => f.displayName).toList();
    final defaults = InstallFeature.all
        .where((f) => f.isDefault)
        .map((f) => InstallFeature.all.indexOf(f) + 1)
        .toList();

    final selected = ConsoleHelper.multiselect(
      'Which Boost features would you like to configure?',
      options,
      defaultIndices: defaults,
    );

    // Map display names back to IDs
    final featureIds = <String>[];
    for (final name in selected) {
      final feature = InstallFeature.all.firstWhere(
        (f) => f.displayName == name,
        orElse: () => InstallFeature.all.first,
      );
      featureIds.add(feature.id);
    }

    return featureIds;
  }

  /// Select skills to include
  Future<List<String>> _selectSkills() async {
    ConsoleHelper.subHeader('Select Skills');

    // Discover available skills
    final loader = SkillLoader(skillsPath: _config.skillsPath);
    final allSkills = await loader.listSkillNames();

    if (allSkills.isEmpty) {
      ConsoleHelper.warning('No skills found');
      return [];
    }

    // Display skills in grid
    ConsoleHelper.info('Available skills:');
    ConsoleHelper.grid(allSkills.map((s) => '  • $s').toList());
    ConsoleHelper.newLine();

    final useAll = ConsoleHelper.confirm('Include all available skills?');

    if (useAll) {
      return allSkills;
    }

    // Select specific skills
    final defaultIndices = List.generate(allSkills.length, (i) => i + 1);
    final selected = ConsoleHelper.multiselect(
      'Which skills would you like to include?',
      allSkills,
      defaultIndices: defaultIndices,
    );

    return selected;
  }

  /// Select AI editors to configure
  Future<List<String>> _selectAgents() async {
    ConsoleHelper.subHeader('Select AI Editors');

    // Detect available agents
    final agents = await AgentDetector.detectAll(basePath: _project!.rootPath);

    if (agents.isEmpty) {
      ConsoleHelper.warning('No supported AI editors detected');
      ConsoleHelper.info('Supported editors:');
      for (final name in AgentDetector.supportedAgentDisplayNames) {
        ConsoleHelper.indent('  - $name');
      }
      return [];
    }

    ConsoleHelper.info('Detected AI editors:');
    for (final agent in agents) {
      final systemInstalled = await agent.isInstalled();
      final inProject = await agent.isInProject(_project!.rootPath);
      final status = systemInstalled ? '[system]' : inProject ? '[project]' : '';
      ConsoleHelper.indent('  • ${agent.displayName} $status');
    }
    ConsoleHelper.newLine();

    final useAll = ConsoleHelper.confirm('Configure all detected editors?');

    if (useAll) {
      return agents.map((a) => a.name).toList();
    }

    // Select specific agents
    final options = agents.map((a) => a.displayName).toList();
    final selected = ConsoleHelper.multiselect(
      'Which editors would you like to configure?',
      options,
    );

    // Map display names back to agent names
    final agentNames = <String>[];
    for (final name in selected) {
      final agent = agents.firstWhere(
        (a) => a.displayName == name,
        orElse: () => agents.first,
      );
      agentNames.add(agent.name);
    }

    return agentNames;
  }

  /// Show confirmation and get user approval
  Future<bool> _confirmInstallation() async {
    ConsoleHelper.dividerWithText('Installation Summary');
    ConsoleHelper.newLine();

    ConsoleHelper.info('Features to install:');
    for (final featureId in _config.features) {
      final feature = InstallFeature.findById(featureId);
      if (feature != null) {
        ConsoleHelper.checkbox(feature.displayName, checked: true);
      }
    }
    ConsoleHelper.newLine();

    if (_config.installSkills && _config.skills.isNotEmpty) {
      ConsoleHelper.info('Skills to include (${_config.skills.length}):');
      ConsoleHelper.grid(_config.skills.map((s) => '  • $s').toList());
      ConsoleHelper.newLine();
    }

    if (_config.installMcp && _config.agents.isNotEmpty) {
      ConsoleHelper.info('AI editors to configure:');
      for (final agentName in _config.agents) {
        ConsoleHelper.indent('  • $agentName');
      }
      ConsoleHelper.newLine();
    }

    return ConsoleHelper.confirm('Proceed with installation?');
  }

  /// Execute the installation
  Future<void> _executeInstallation() async {
    final results = <String, InstallResult>{};

    // Install guidelines
    if (_config.installGuidelines) {
      ConsoleHelper.subHeader('Installing Guidelines');
      final result = await _installGuidelines();
      results['guidelines'] = result;
      ConsoleHelper.closeSection();
    }

    // Install skills
    if (_config.installSkills) {
      ConsoleHelper.subHeader('Installing Skills');
      final result = await _installSkills();
      results['skills'] = result;
      ConsoleHelper.closeSection();
    }

    // Install MCP configuration
    if (_config.installMcp) {
      ConsoleHelper.subHeader('Installing MCP Configuration');
      final result = await _installMcp();
      results['mcp'] = result;
      ConsoleHelper.closeSection();
    }

    // Display final summary
    _displaySummary(results);
  }

  /// Install AI guidelines
  Future<InstallResult> _installGuidelines() async {
    try {
      ConsoleHelper.info('Generating AGENTS.md and CLAUDE.md...');

      // Select skills
      final skillNames = _config.skills.isEmpty
          ? await _autoDiscoverSkills()
          : _config.skills;

      if (skillNames.isEmpty) {
        ConsoleHelper.warning('No skills found to include');
        return InstallResult.success();
      }

      ConsoleHelper.indent('Using ${skillNames.length} skill(s)');

      // Create guideline composer
      final context = ProjectContext.fromProject(_project!);
      final composer = GuidelineComposer(
        skillComposer: SkillComposer(
          loader: SkillLoader(skillsPath: _config.skillsPath),
          renderer: TemplateRenderer(context: context),
        ),
      );

      // Create writer
      final writer = GuidelineWriter(composer: composer);

      // Write AGENTS.md
      ConsoleHelper.info('Writing AGENTS.md...');
      final agentsResult = await writer.writeAgentsMd(
        _project!.rootPath,
        skillNames,
        context: context,
      );

      _printWriteResult('AGENTS.md', agentsResult);

      // Write CLAUDE.md
      ConsoleHelper.info('Writing CLAUDE.md...');
      final claudeResult = await writer.writeClaudeMd(
        _project!.rootPath,
        skillNames,
        context: context,
      );

      _printWriteResult('CLAUDE.md', claudeResult);

      return InstallResult.success(['AGENTS.md', 'CLAUDE.md']);
    } catch (e) {
      return InstallResult.failure({'guidelines': e.toString()});
    }
  }

  /// Install skills
  Future<InstallResult> _installSkills() async {
    try {
      ConsoleHelper.info('Skills are auto-loaded from ${_config.skillsPath}');
      ConsoleHelper.indent('No additional installation needed');
      return InstallResult.success(['skills']);
    } catch (e) {
      return InstallResult.failure({'skills': e.toString()});
    }
  }

  /// Install MCP configuration
  Future<InstallResult> _installMcp() async {
    try {
      // Detect agents
      final agents = await AgentDetector.detectAll(basePath: _project!.rootPath);

      if (agents.isEmpty) {
        ConsoleHelper.warning('No supported AI editors detected');
        return InstallResult.success();
      }

      // Filter to selected agents
      final selectedAgents = _config.agents.isEmpty
          ? agents
          : agents.where((a) => _config.agents.contains(a.name)).toList();

      if (selectedAgents.isEmpty) {
        ConsoleHelper.warning('No agents selected for configuration');
        return InstallResult.success();
      }

      final failures = <String, String>{};

      for (final agent in selectedAgents) {
        ConsoleHelper.info('Configuring ${agent.displayName}...');

        try {
          final config = agent.generateMcpConfig(_project!);
          await agent.writeMcpConfig(_project!, config);
          ConsoleHelper.success('${agent.displayName} configured');
          ConsoleHelper.indent('Config: ${agent.getConfigPath(_project!.rootPath)}');
        } catch (e) {
          ConsoleHelper.error('${agent.displayName} failed: $e');
          failures[agent.displayName] = e.toString();
        }
      }

      if (failures.isEmpty) {
        return InstallResult.success(selectedAgents.map((a) => a.displayName).toList());
      } else {
        return InstallResult.failure(failures);
      }
    } catch (e) {
      return InstallResult.failure({'mcp': e.toString()});
    }
  }

  /// Auto-discover available skills
  Future<List<String>> _autoDiscoverSkills() async {
    final loader = SkillLoader(skillsPath: _config.skillsPath);
    return loader.listSkillNames();
  }

  /// Print write result message
  void _printWriteResult(String filename, GuidelineWriteStatus result) {
    final status = switch (result) {
      GuidelineWriteStatus.created => 'Created',
      GuidelineWriteStatus.replaced => 'Updated',
      GuidelineWriteStatus.noop => 'No changes',
      GuidelineWriteStatus.failed => 'Failed',
    };

    final mark = switch (result) {
      GuidelineWriteStatus.created => '\x1B[32m✓\x1B[0m',
      GuidelineWriteStatus.replaced => '\x1B[32m✓\x1B[0m',
      GuidelineWriteStatus.noop => '\x1B[33m⊘\x1B[0m',
      GuidelineWriteStatus.failed => '\x1B[31m✗\x1B[0m',
    };

    ConsoleHelper.indent('$mark $filename - $status');
  }

  /// Display final installation summary
  void _displaySummary(Map<String, InstallResult> results) {
    ConsoleHelper.rule(character: '═');
    ConsoleHelper.newLine();

    var totalSuccess = 0;
    var totalFailures = 0;

    for (final entry in results.entries) {
      final result = entry.value;
      totalSuccess += result.successes.length;
      totalFailures += result.failures.length;
    }

    if (totalFailures == 0) {
      ConsoleHelper.success('All installations completed successfully!');
    } else {
      ConsoleHelper.warning(
        'Installation completed with $totalFailures error(s)',
      );
    }

    ConsoleHelper.newLine();
    ConsoleHelper.info('Summary:');
    ConsoleHelper.indent('✓ $totalSuccess successful');
    if (totalFailures > 0) {
      ConsoleHelper.indent('✗ $totalFailures failed');
    }
    ConsoleHelper.newLine();

    // Show failures if any
    if (totalFailures > 0) {
      ConsoleHelper.info('Failed installations:');
      for (final result in results.values) {
        for (final entry in result.failures.entries) {
          ConsoleHelper.indent('  • ${entry.key}: ${entry.value}');
        }
      }
      ConsoleHelper.newLine();
    }

    ConsoleHelper.rule(character: '═');
  }
}
