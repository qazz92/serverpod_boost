/// Guideline writer for ServerPod Boost
///
/// Writes AGENTS.md and CLAUDE.md files with smart merge support.
library serverpod_boost.guidelines.guideline_writer;

import 'dart:io';
import 'package:path/path.dart' as p;
import '../project_context.dart';
import 'guideline_composer.dart';
import 'agent_type.dart';

/// Write result status
enum GuidelineWriteStatus {
  /// File was newly created
  created,

  /// File was updated/replaced
  replaced,

  /// No changes needed
  noop,

  /// Write failed
  failed,
}

/// Exception thrown when guideline writing fails
class GuidelineWriteException implements Exception {
  /// Create exception
  const GuidelineWriteException(this.message, [this.filePath]);

  /// Error message
  final String message;

  /// Optional file path
  final String? filePath;

  @override
  String toString() {
    if (filePath != null) {
      return 'GuidelineWriteException: $message (file: $filePath)';
    }
    return 'GuidelineWriteException: $message';
  }
}

/// Writer for AI guideline files (AGENTS.md, CLAUDE.md)
///
/// Provides smart merge functionality to preserve user customizations
/// when updating guideline files.
class GuidelineWriter {
  /// Create a new guideline writer
  ///
  /// Requires a [GuidelineComposer] instance for generating guideline content.
  const GuidelineWriter({
    required this.composer,
  });

  /// Guideline composer for generating content
  final GuidelineComposer composer;

  /// Write AGENTS.md file with smart merge
  ///
  /// Generates AGENTS.md content using the GuidelineComposer and smart merges
  /// with existing content if the file exists.
  ///
  /// Parameters:
  /// - [projectPath]: Root path of the ServerPod project
  /// - [skillNames]: List of skill names to include in guidelines
  /// - [agent]: Agent type to generate guidelines for (defaults to claudeCode)
  /// - [context]: Project context information
  ///
  /// Throws [GuidelineWriteException] if writing fails.
  /// Returns [GuidelineWriteStatus] indicating the result.
  Future<GuidelineWriteStatus> writeAgentsMd(
    String projectPath,
    List<String> skillNames, {
    AgentType agent = AgentType.claudeCode,
    required ProjectContext context,
  }) async {
    try {
      // Generate content using composer
      final content = await composer.composeForAgent(
        agent,
        skillNames,
        context,
      );

      final agentsFile = File(p.join(projectPath, 'AGENTS.md'));

      if (await agentsFile.exists()) {
        // Smart merge with existing content
        final existing = await agentsFile.readAsString();
        final merged = _mergeAgentsMd(existing, content);

        // Check if content changed
        if (merged == existing) {
          return GuidelineWriteStatus.noop;
        }

        await agentsFile.writeAsString(merged);
        return GuidelineWriteStatus.replaced;
      } else {
        // Create new file
        await agentsFile.writeAsString(content);
        return GuidelineWriteStatus.created;
      }
    } catch (e) {
      throw GuidelineWriteException(
        'Failed to write AGENTS.md: $e',
        p.join(projectPath, 'AGENTS.md'),
      );
    }
  }

  /// Write CLAUDE.md file with smart merge
  ///
  /// Generates CLAUDE.md content using the GuidelineComposer and smart merges
  /// with existing content if the file exists.
  ///
  /// Parameters:
  /// - [projectPath]: Root path of the ServerPod project
  /// - [skillNames]: List of skill names to include in guidelines
  /// - [agent]: Agent type to generate guidelines for (defaults to claudeCode)
  /// - [context]: Project context information
  ///
  /// Throws [GuidelineWriteException] if writing fails.
  /// Returns [GuidelineWriteStatus] indicating the result.
  Future<GuidelineWriteStatus> writeClaudeMd(
    String projectPath,
    List<String> skillNames, {
    AgentType agent = AgentType.claudeCode,
    required ProjectContext context,
  }) async {
    try {
      // Generate content using composer
      final content = await composer.composeForAgent(
        agent,
        skillNames,
        context,
      );

      final claudeFile = File(p.join(projectPath, 'CLAUDE.md'));

      if (await claudeFile.exists()) {
        // Smart merge with existing content
        final existing = await claudeFile.readAsString();
        final merged = _mergeClaudeMd(existing, content);

        // Check if content changed
        if (merged == existing) {
          return GuidelineWriteStatus.noop;
        }

        await claudeFile.writeAsString(merged);
        return GuidelineWriteStatus.replaced;
      } else {
        // Create new file
        await claudeFile.writeAsString(content);
        return GuidelineWriteStatus.created;
      }
    } catch (e) {
      throw GuidelineWriteException(
        'Failed to write CLAUDE.md: $e',
        p.join(projectPath, 'CLAUDE.md'),
      );
    }
  }

  /// Merge AGENTS.md content with existing content
  ///
  /// Parses both existing and generated content into sections,
  /// then merges them while preserving user customizations.
  ///
  /// The merge strategy:
  /// 1. Parse existing content into sections by # headers
  /// 2. Parse generated content into sections
  /// 3. Generated sections take precedence over existing ones
  /// 4. User sections between <serverpod-boost-guidelines> and end are preserved
  /// 5. Sections are recombined into final document with proper formatting
  String _mergeAgentsMd(String existing, String generated) {
    // Parse both contents
    final existingSections = _parseSections(existing);
    final generatedSections = _parseSections(generated);

    // Find the separator in the generated content
    final generatedContent = generatedSections.values.firstWhere(
      (section) => section.contains('<serverpod-boost-guidelines>'),
      orElse: () => '',
    );

    // Build merged content
    final buffer = StringBuffer();

    // Add frontmatter from generated content
    final frontmatter = generatedSections.keys.firstWhere(
      (key) => key.startsWith('---'),
      orElse: () => '',
    );
    if (frontmatter.isNotEmpty) {
      buffer.writeln(generatedSections[frontmatter]!);
      buffer.writeln();
    }

    // Add generated guidelines (excluding frontmatter)
    final guidelinesSection = generatedSections.keys.firstWhere(
      (key) => key.contains('serverpod boost guidelines'),
      orElse: () => '',
    );
    if (guidelinesSection.isNotEmpty) {
      buffer.writeln(generatedSections[guidelinesSection]!);
      buffer.writeln();
    }

    // Add skills section from generated content
    final skillsSection = generatedSections.keys.firstWhere(
      (key) => key.contains('skills'),
      orElse: () => '',
    );
    if (skillsSection.isNotEmpty) {
      buffer.writeln(generatedSections[skillsSection]!);
      buffer.writeln();
    }

    // Add separator
    buffer.writeln('<serverpod-boost-guidelines>');
    buffer.writeln();

    // Preserve user sections from existing content (everything after separator)
    if (existingSections.isNotEmpty) {
      bool foundSeparator = false;
      for (final line in existing.split('\n')) {
        if (line.trim() == '<serverpod-boost-guidelines>') {
          foundSeparator = true;
          continue;
        }

        if (foundSeparator) {
          buffer.writeln(line);
        }
      }
    }

    return buffer.toString().trimRight();
  }

  /// Merge CLAUDE.md content with existing content
  ///
  /// Similar to _mergeAgentsMd but may have different sections
  /// that need to be preserved for CLAUDE.md.
  String _mergeClaudeMd(String existing, String generated) {
    // For now, use same merge logic as AGENTS.md
    // Can be customized later if CLAUDE.md needs different handling
    return _mergeAgentsMd(existing, generated);
  }

  /// Parse markdown content into sections by # headers
  ///
  /// Splits the content by top-level headers (# Header)
  /// and returns a map of header names to content.
  ///
  /// Headers are normalized (lowercased, trimmed) for comparison.
  /// Content includes the header line itself.
  Map<String, String> _parseSections(String content) {
    final sections = <String, String>{};
    final lines = content.split('\n');

    String? currentHeader;
    final currentContent = <String>[];
    var foundHeader = false;

    for (final line in lines) {
      // Check for top-level header (# Header)
      if (line.startsWith('# ') && !line.startsWith('## ')) {
        // Save previous section if exists
        if (currentHeader != null && currentContent.isNotEmpty) {
          sections[currentHeader] = currentContent.join('\n').trimRight();
        }

        // Start new section
        currentHeader = line.substring(1).trim().toLowerCase();
        currentContent.clear();
        currentContent.add(line); // Include the header line
        foundHeader = true;
      } else {
        currentContent.add(line);
        foundHeader = false;
      }
    }

    // Save last section
    if (currentHeader != null && currentContent.isNotEmpty) {
      sections[currentHeader] = currentContent.join('\n').trimRight();
    }

    return sections;
  }

  /// Build markdown document from sections map
  ///
  /// Reconstructs a markdown document from the sections map,
  /// preserving the order and formatting.
  ///
  /// The sections are sorted alphabetically by key to ensure
  /// consistent output, but can be customized.
  String _buildDocument(Map<String, String> sections) {
    if (sections.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    // Sort sections for consistent output
    // Custom order can be defined here if needed
    final sortedKeys = sections.keys.toList()..sort();

    for (final key in sortedKeys) {
      buffer.writeln('# ${_capitalizeHeader(key)}');
      buffer.writeln();

      final content = sections[key]!;
      if (content.isNotEmpty) {
        buffer.writeln(content);
        buffer.writeln();
      }
    }

    return buffer.toString().trimRight();
  }

  /// Capitalize the first letter of each word in header
  ///
  /// Converts lowercase headers back to title case.
  /// Example: "claude code guidelines" -> "Claude Code Guidelines"
  String _capitalizeHeader(String header) {
    return header
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Write guidelines to a specific file path
  ///
  /// Low-level method that writes content directly to a file
  /// without smart merging. Useful for testing or special cases.
  ///
  /// Parameters:
  /// - [filePath]: Full path to the file to write
  /// - [content]: Content to write
  ///
  /// Throws [GuidelineWriteException] if writing fails.
  Future<void> writeDirectly(String filePath, String content) async {
    try {
      final file = File(filePath);
      final directory = Directory(p.dirname(filePath));

      // Create directory if it doesn't exist
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await file.writeAsString(content);
    } catch (e) {
      throw GuidelineWriteException(
        'Failed to write file: $e',
        filePath,
      );
    }
  }

  /// Check if a guideline file exists
  ///
  /// Parameters:
  /// - [projectPath]: Root path of the ServerPod project
  /// - [fileName]: Name of the file to check (AGENTS.md or CLAUDE.md)
  ///
  /// Returns true if the file exists, false otherwise.
  Future<bool> fileExists(
    String projectPath,
    String fileName,
  ) async {
    final file = File(p.join(projectPath, fileName));
    return await file.exists();
  }

  /// Read existing guideline file content
  ///
  /// Parameters:
  /// - [projectPath]: Root path of the ServerPod project
  /// - [fileName]: Name of the file to read
  ///
  /// Returns the file content, or null if file doesn't exist.
  Future<String?> readExisting(
    String projectPath,
    String fileName,
  ) async {
    final file = File(p.join(projectPath, fileName));

    if (!await file.exists()) {
      return null;
    }

    return await file.readAsString();
  }

  /// Backup existing guideline file
  ///
  /// Creates a backup of the existing file before overwriting.
  /// Backup filename includes timestamp.
  ///
  /// Parameters:
  /// - [projectPath]: Root path of the ServerPod project
  /// - [fileName]: Name of the file to backup
  ///
  /// Returns the backup file path, or null if original doesn't exist.
  Future<String?> backupExisting(
    String projectPath,
    String fileName,
  ) async {
    final file = File(p.join(projectPath, fileName));

    if (!await file.exists()) {
      return null;
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(projectPath, '.$fileName.backup.$timestamp');

    await file.copy(backupPath);
    return backupPath;
  }
}
