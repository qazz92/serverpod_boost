/// install command
///
/// Installation of ServerPod Boost features.
/// Installs all features (guidelines, skills, MCP) by default.
library serverpod_boost.commands.install_command;

import 'dart:io';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;
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

      if (args['nonInteractive'] != true) {
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
    // Default: use essential skills only (for optimized CLAUDE.md size)
    args['fullSkills'] = false;

    // Parse flags
    final rawArgs = Platform.environment['SERVERPOD_BOOST_ARGS']?.split(' ') ?? [];

    for (final arg in rawArgs) {
      if (arg == '--guidelines') {
        args['features'] = ['guidelines'];
      } else if (arg == '--skills') {
        args['features'] = ['skills'];
      } else if (arg == '--mcp') {
        args['features'] = ['mcp'];
      } else if (arg == '--non-interactive') {
        args['nonInteractive'] = true;
      } else if (arg == '--overwrite') {
        args['overwrite'] = true;
      } else if (arg == '--full-skills') {
        args['fullSkills'] = true;
      }
    }

    return args;
  }

  /// Run non-interactive installation
  Future<void> _runNonInteractive(Map<String, dynamic> args) async {
    final features = args['features'] as List<String>? ??
        ['guidelines', 'skills', 'mcp'];

    // Use essential skills by default unless --full-skills is specified
    final useFullSkills = args['fullSkills'] == true;
    final skills = useFullSkills ? await _autoDiscoverSkills() : _getEssentialSkills();

    _config = InstallConfig(
      features: features,
      overwrite: args['overwrite'] == true,
      skills: skills,
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
    List<String> allSkills;
    try {
      final loader = SkillLoader(skillsPath: _config.skillsPath);
      allSkills = await loader.listSkillNames();
    } catch (e) {
      // Skills directory doesn't exist yet - will copy built-in skills during installation
      ConsoleHelper.info('Skills will be copied from Boost package during installation');
      ConsoleHelper.indent('Essential skills (core, endpoints) will be included');
      ConsoleHelper.indent('Tip: Use --full-skills flag to include all available skills');
      return [];
    }

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

    // Copy built-in skills first (before installing guidelines)
    if (_config.installGuidelines || _config.installSkills) {
      ConsoleHelper.subHeader('Installing Built-in Skills');
      final result = await _installBuiltInSkills();
      if (!result.success) {
        ConsoleHelper.warning('Failed to copy built-in skills, continuing anyway...');
      }
      ConsoleHelper.closeSection();
    }

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

  /// Copy built-in skills from Boost package to project
  Future<InstallResult> _installBuiltInSkills() async {
    try {
      final sourceSkillsPath = await _findBoostSkillsPath();
      final targetSkillsPath = '${_project!.rootPath}/.ai/skills';

      ConsoleHelper.info('Copying built-in skills...');
      ConsoleHelper.indent('Source: $sourceSkillsPath');
      ConsoleHelper.indent('Target: $targetSkillsPath');

      // Check if source directory exists
      final sourceDir = Directory(sourceSkillsPath);
      if (!await sourceDir.exists()) {
        ConsoleHelper.warning('Source skills directory not found at: $sourceSkillsPath');
        ConsoleHelper.indent('Creating empty skills directory as fallback');

        // Create empty skills directory and continue
        final targetDir = Directory(targetSkillsPath);
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        return InstallResult.success(['skills']);
      }

      // Create target directory if it doesn't exist
      final targetDir = Directory(targetSkillsPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
        ConsoleHelper.indent('Created directory: $targetSkillsPath');
      }

      // Determine which skills to copy
      // If config has specific skills, copy only those
      // If config is empty (skills not yet selected), copy all available skills
      final skillsToCopy = _config.skills.isEmpty
          ? await _listAvailableSkills(sourceDir)
          : _config.skills;

      // Copy skill directories
      final copiedSkills = <String>[];
      await for (final entity in sourceDir.list(recursive: false, followLinks: false)) {
        if (entity is Directory) {
          final skillName = entity.path.split(Platform.pathSeparator).last;

          // Skip if not in the list of skills to copy
          if (skillsToCopy.isNotEmpty && !skillsToCopy.contains(skillName)) {
            continue;
          }

          final targetPath = '$targetSkillsPath/$skillName';

          // Remove existing if overwrite is enabled
          final existingDir = Directory(targetPath);
          if (await existingDir.exists()) {
            if (_config.overwrite) {
              await existingDir.delete(recursive: true);
            } else {
              ConsoleHelper.indent('⊘ Skipped existing: $skillName');
              continue;
            }
          }

          // Copy directory recursively
          await _copyDirectory(entity, Directory(targetPath));
          copiedSkills.add(skillName);
          ConsoleHelper.indent('✓ Copied: $skillName');
        }
      }

      if (copiedSkills.isEmpty) {
        ConsoleHelper.indent('No new skills to copy');
      } else {
        ConsoleHelper.success('Copied ${copiedSkills.length} skill(s)');
      }

      return InstallResult.success(copiedSkills);
    } catch (e) {
      ConsoleHelper.error('Failed to copy skills: $e');
      // Create empty skills directory as fallback
      try {
        final targetDir = Directory('${_project!.rootPath}/.ai/skills');
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      } catch (_) {
        // Ignore fallback errors
      }
      return InstallResult.failure({'skills': e.toString()});
    }
  }

  /// List all available skill directories in the source directory
  Future<List<String>> _listAvailableSkills(Directory sourceDir) async {
    final skills = <String>[];
    await for (final entity in sourceDir.list(recursive: false, followLinks: false)) {
      if (entity is Directory) {
        final skillName = entity.path.split(Platform.pathSeparator).last;
        skills.add(skillName);
      }
    }
    return skills;
  }

  /// Find the Boost package skills directory
  /// Supports both local development and published packages
  Future<String> _findBoostSkillsPath() async {
    // Strategy 1: Try local development (for when working on boost itself)
    try {
      final currentScript = File.fromUri(Platform.script);
      final boostPackageRoot = currentScript.parent.parent.path;
      final localPath = '$boostPackageRoot/.ai/skills/serverpod';
      if (await Directory(localPath).exists()) {
        ConsoleHelper.indent('Found Boost skills via local development path');
        return localPath;
      }
    } catch (e) {
      // Ignore and try next strategy
    }

    // Strategy 2: Use package resolver to find lib/resources/skills
    try {
      final packageConfig = await findPackageConfig(Directory.current);
      if (packageConfig != null) {
        final boostPackage = packageConfig['serverpod_boost'];
        if (boostPackage != null) {
          final packageRoot = boostPackage.root.path;
          final resourcesPath = '$packageRoot/lib/resources/skills';
          if (await Directory(resourcesPath).exists()) {
            ConsoleHelper.indent('Found Boost skills via package config');
            return resourcesPath;
          }
        }
      }
    } catch (e) {
      // Ignore and try next strategy
    }

    // Strategy 3: Try resolving from current package (for published packages)
    try {
      // For published packages, lib is at the package root
      final currentScript = File.fromUri(Platform.script);
      final binDir = currentScript.parent;
      final packageRoot = binDir.parent;
      final resourcesPath = '$packageRoot/lib/resources/skills';
      ConsoleHelper.indent('Using resolved package path');
      return resourcesPath;
    } catch (e) {
      // Fallback to default
      ConsoleHelper.indent('Using default path');
      return 'lib/resources/skills';
    }
  }

  /// Copy directory recursively
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);

    await for (final entity in source.list(recursive: false, followLinks: false)) {
      final basename = p.basename(entity.path);
      if (entity is File) {
        final targetFile = File(p.join(destination.path, basename));
        await entity.copy(targetFile.path);
      } else if (entity is Directory) {
        final targetDir = Directory(p.join(destination.path, basename));
        await _copyDirectory(entity, targetDir);
      }
    }
  }

  /// Install AI guidelines
  Future<InstallResult> _installGuidelines() async {
    try {
      ConsoleHelper.info('Generating AGENTS.md and CLAUDE.md...');

      // Select skills - use essential skills if none specified
      final skillNames = _config.skills.isEmpty
          ? _getEssentialSkills()
          : _config.skills;

      if (skillNames.isEmpty) {
        ConsoleHelper.warning('No skills found to include');
        return InstallResult.success();
      }

      ConsoleHelper.indent('Using ${skillNames.length} skill(s): ${skillNames.join(', ')}');
      ConsoleHelper.indent('Tip: Use --full-skills flag to include all available skills');

      // Create guideline composer
      final context = ProjectContext.fromProject(_project!);
      final composer = GuidelineComposer(
        skillComposer: SkillComposer(
          loader: SkillLoader(skillsPath: '${_project!.rootPath}/.ai/skills'),
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
    final loader = SkillLoader(skillsPath: '${_project!.rootPath}/.ai/skills');
    return loader.listSkillNames();
  }

  /// Get essential skills for optimized CLAUDE.md size
  /// Returns only core and endpoints skills to keep documentation under 40KB
  List<String> _getEssentialSkills() {
    return ['core', 'endpoints'];
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
