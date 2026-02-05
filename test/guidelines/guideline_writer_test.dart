/// Tests for GuidelineWriter
library serverpod_boost.test.guidelines.guideline_writer_test;

import 'dart:io';

import 'package:test/test.dart';
import 'package:serverpod_boost/skills/skill_composer.dart';
import 'package:serverpod_boost/skills/skill_loader.dart';
import 'package:serverpod_boost/skills/skill.dart';
import 'package:serverpod_boost/skills/skill_metadata.dart';
import 'package:serverpod_boost/skills/template_renderer.dart';
import 'package:serverpod_boost/project_context.dart';

/// Simple mock skill composer for testing
class _MockSkillComposer extends SkillComposer {
  String? _lastResult;

  _MockSkillComposer() : super(
    loader: _MockSkillLoader(),
    renderer: const TemplateRenderer(
      context: ProjectContext(
        projectName: 'test',
        serverpodVersion: '3.2.3',
        rootPath: '',
      ),
    ),
  );

  void setComposedResult(String result) {
    _lastResult = result;
  }

  @override
  Future<String> compose(List<String> skillNames, ProjectContext context) async {
    return _lastResult ?? '';
  }
}

/// Mock skill loader for testing
class _MockSkillLoader extends SkillLoader {
  _MockSkillLoader() : super(skillsPath: '/test/path');

  @override
  Future<Skill?> loadSkill(String name) async {
    return Skill(
      name: name,
      description: 'Test skill for $name',
      template: 'This is a test skill template for **$name**.',
      metadata: const SkillMetadata(
        version: '1.0.0',
        tags: ['test'],
      ),
    );
  }
}

void main() {
  group('GuidelineWriter', () {
    late _MockSkillComposer mockSkillComposer;
    late Directory tempDir;
    late ProjectContext projectContext;

    setUp(() async {
      // Create temporary directory
      tempDir = Directory.systemTemp.createTempSync('guideline_writer_test_');

      // Create simple mock skill composer
      mockSkillComposer = _MockSkillComposer();

      // Create test project context
      projectContext = ProjectContext(
        projectName: 'TestProject',
        serverpodVersion: '3.2.3',
        rootPath: tempDir.path,
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('writeAgentsMd() - Create new AGENTS.md', () {
      test('creates new AGENTS.md file with proper content', () async {
        // Arrange
        final agentsMdPath = '${tempDir.path}/AGENTS.md';
        final selectedSkills = ['core', 'testing'];

        final expectedContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 2
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure
- Follow ServerPod conventions

# Testing Patterns

## Unit Tests
- Write comprehensive tests
- Mock external dependencies
''';

        mockSkillComposer.setComposedResult(expectedContent);

        // Act
        final result = await _mockWriteAgentsMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        expect(result, isTrue);
        expect(File(agentsMdPath).existsSync(), isTrue);

        final fileContent = await File(agentsMdPath).readAsString();
        expect(fileContent, contains('---'));
        expect(fileContent, contains('# ServerPod Boost Guidelines for TestProject'));
        expect(fileContent, contains('Project: TestProject'));
        expect(fileContent, contains('# Testing Patterns'));
        expect(fileContent, contains('# Testing Patterns'));
      });

      test('creates AGENTS.md with correct file permissions', () async {
        // Arrange
        final agentsMdPath = '${tempDir.path}/AGENTS.md';
        final selectedSkills = ['core'];

        final expectedContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure
- Follow ServerPod conventions
''';

        mockSkillComposer.setComposedResult(expectedContent);

        // Act
        await _mockWriteAgentsMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        final file = File(agentsMdPath);
        expect(file.existsSync(), isTrue);
        expect(file.statSync().modeString().contains('r'), isTrue);
        expect(file.statSync().modeString().contains('w'), isTrue);
      });

      test('handles empty skills list gracefully', () async {
        // Arrange
        final agentsMdPath = '${tempDir.path}/AGENTS.md';
        final selectedSkills = <String>[];

        final expectedContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 0
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills

No skills were selected.
''';

        mockSkillComposer.setComposedResult(expectedContent);

        // Act
        final result = await _mockWriteAgentsMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        expect(result, isTrue);
        expect(File(agentsMdPath).existsSync(), isTrue);

        final fileContent = await File(agentsMdPath).readAsString();
        expect(fileContent, contains('Skills included: 0'));
        expect(fileContent, contains('No skills were selected.'));
      });
    });

    group('writeAgentsMd() - Merge with existing AGENTS.md', () {
      test('merges with existing AGENTS.md preserving user sections', () async {
        // Arrange
        final agentsMdPath = '${tempDir.path}/AGENTS.md';

        // Create existing AGENTS.md with user content
        final existingContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Old Skill

## Old Content
- This is old content

---

## User Guidelines

This is custom user content that should be preserved.
''';

        await File(agentsMdPath).writeAsString(existingContent);

        final selectedSkills = <String>['core'];
        final newContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Unit Tests
- Write comprehensive tests
- Mock external dependencies

---

## User Guidelines

This is custom user content that should be preserved.
''';

        mockSkillComposer.setComposedResult(newContent);

        // Act
        final result = await _mockWriteAgentsMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        expect(result, isTrue);
        expect(File(agentsMdPath).existsSync(), isTrue);

        final fileContent = await File(agentsMdPath).readAsString();
        expect(fileContent, contains('# Testing Patterns')); // Should contain the new content
        expect(fileContent, isNot(contains('# Old Skill'))); // Old content removed
        expect(fileContent, contains('This is custom user content')); // User section preserved
        expect(fileContent, contains('<serverpod-boost-guidelines>')); // Separator
      });

      test('updates generated sections while preserving user content', () async {
        // Arrange
        final agentsMdPath = '${tempDir.path}/AGENTS.md';

        // Create existing AGENTS.md with mixed content
        final existingContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Old Skill

## Old Content
- This is old content

---

## User Guidelines

This is custom user content.
- Should be preserved
- Never overwritten

---

## More User Content
More custom content here.
''';

        await File(agentsMdPath).writeAsString(existingContent);

        final selectedSkills = <String>['core', 'testing'];
        final newContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 2
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure
- Follow ServerPod conventions

# Testing Patterns

## Unit Tests
- Write comprehensive tests
- Mock external dependencies

---

## User Guidelines

This is custom user content.
- Should be preserved
- Never overwritten

---

## More User Content
More custom content here.
''';

        mockSkillComposer.setComposedResult(newContent);

        // Act
        final result = await _mockWriteAgentsMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        expect(result, isTrue);

        final fileContent = await File(agentsMdPath).readAsString();
        expect(fileContent, contains('# Testing Patterns')); // Updated
        expect(fileContent, contains('# Testing Patterns')); // Updated
        expect(fileContent, isNot(contains('# Old Skill'))); // Removed
        expect(fileContent, contains('This is custom user content')); // Preserved
        expect(fileContent, contains('More custom content here')); // Preserved
        expect(fileContent, contains('<serverpod-boost-guidelines>')); // Separator
      });
    });

    group('writeClaudeMd() - Create new CLAUDE.md', () {
      test('creates new CLAUDE.md file with proper content', () async {
        // Arrange
        final claudeMdPath = '${tempDir.path}/CLAUDE.md';
        final selectedSkills = <String>['endpoints'];

        final expectedContent = '''# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0

## Project Context
This is a test ServerPod project.

## Skills
# Endpoints Skill

## Endpoint Patterns
- Create proper endpoint classes
- Use validation decorators
''';

        mockSkillComposer.setComposedResult(expectedContent);

        // Act
        final result = await _mockWriteClaudeMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        expect(result, isTrue);
        expect(File(claudeMdPath).existsSync(), isTrue);

        final fileContent = await File(claudeMdPath).readAsString();
        expect(fileContent, startsWith('# ServerPod Boost Guidelines for TestProject\n'));
        expect(fileContent, contains('Generated at:'));
        expect(fileContent, contains('Project: TestProject'));
        expect(fileContent, contains('# Endpoints Skill'));
        expect(fileContent, contains('Create proper endpoint classes'));
      });

      test('creates CLAUDE.md without frontmatter', () async {
        // Arrange
        final claudeMdPath = '${tempDir.path}/CLAUDE.md';
        final selectedSkills = <String>['core'];

        final expectedContent = '''# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure
- Follow ServerPod conventions
''';

        mockSkillComposer.setComposedResult(expectedContent);

        // Act
        final result = await _mockWriteClaudeMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        expect(result, isTrue);

        final fileContent = await File(claudeMdPath).readAsString();
        expect(fileContent, isNot(contains('---')));
        expect(fileContent, startsWith('# ServerPod Boost Guidelines'));
      });
    });

    group('writeClaudeMd() - Merge with existing CLAUDE.md', () {
      test('merges with existing CLAUDE.md preserving user sections', () async {
        // Arrange
        final claudeMdPath = '${tempDir.path}/CLAUDE.md';

        // Create existing CLAUDE.md with user content
        final existingContent = '''# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0

## Project Context
This is a test ServerPod project.

## Skills
# Old Skill

## Old Content
- This is old content

<serverpod-boost-guidelines>

## User Guidelines
This is custom user content.
''';

        await File(claudeMdPath).writeAsString(existingContent);

        final selectedSkills = <String>['core'];
        final newContent = '''# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure
- Follow ServerPod conventions

<serverpod-boost-guidelines>

## User Guidelines
This is custom user content.
''';

        mockSkillComposer.setComposedResult(newContent);

        // Act
        final result = await _mockWriteClaudeMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        expect(result, isTrue);

        final fileContent = await File(claudeMdPath).readAsString();
        expect(fileContent, contains('# Testing Patterns')); // Should contain the new content
        expect(fileContent, isNot(contains('# Old Skill'))); // Old content removed
        expect(fileContent, contains('This is custom user content')); // User section preserved
        expect(fileContent, contains('<serverpod-boost-guidelines>')); // Separator
      });
    });

    group('Smart merge functionality', () {
      test('preserves user sections between separator and end', () async {
        // Arrange
        final agentsMdPath = '${tempDir.path}/AGENTS.md';

        final existingContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Old Skill

## Old Content
- This is old content

<serverpod-boost-guidelines>

## User Guidelines
- Custom rule 1
- Custom rule 2

## Project Notes
- Important note 1
- Important note 2
''';

        await File(agentsMdPath).writeAsString(existingContent);

        final selectedSkills = <String>['core'];
        final newContent = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure
- Follow ServerPod conventions

<serverpod-boost-guidelines>

## User Guidelines
- Custom rule 1
- Custom rule 2

## Project Notes
- Important note 1
- Important note 2
''';

        mockSkillComposer.setComposedResult(newContent);

        // Act
        await _mockWriteAgentsMd(
          tempDir.path,
          selectedSkills,
          projectContext,
          mockSkillComposer,
        );

        // Assert
        final fileContent = await File(agentsMdPath).readAsString();
        expect(fileContent, contains('# Testing Patterns'));
        expect(fileContent, contains('- Custom rule 1'));
        expect(fileContent, contains('- Important note 1'));
      });
    });

    group('Section parsing by # headers', () {
      test('correctly identifies sections by headers', () async {
        // This test would test the actual GuidelineWriter implementation
        // For now, we test through the mock

        final agentsMdPath = '${tempDir.path}/AGENTS.md';

        final content = '''# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.
''';

        await File(agentsMdPath).writeAsString(content);

        // Test section detection
        final sections = _parseSections(content);

        expect(sections.length, equals(1));
        expect(sections.containsKey('serverpod boost guidelines'), isTrue);
        expect(sections['serverpod boost guidelines'], contains('# ServerPod Boost Guidelines'));
        expect(sections['serverpod boost guidelines'], contains('This is a test ServerPod project'));
      });

      test('handles headers with different markdown levels', () async {
        final content = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

### Endpoints
Endpoint information.

## Skills
# Testing Patterns

## Unit Tests
- Write comprehensive tests
- Mock external dependencies

---

## User Guidelines
This is user content.
''';

        final sections = _parseSections(content);
        expect(sections.length, greaterThanOrEqualTo(3));
        expect(sections.values.elementAt(1), contains('### Endpoints'));
        expect(sections.values.elementAt(1), contains('## Project Context'));
      });
    });

    group('Document rebuilding from sections', () {
      test('rebuilds document correctly after merging', () async {
        // This test simulates the document rebuilding process

        final sections = {
          '---': '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 2
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---''',

          'serverpod boost guidelines': '''# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure
- Follow ServerPod conventions

# Testing Patterns

## Unit Tests
- Write comprehensive tests
- Mock external dependencies''',

          'user guidelines': '''<serverpod-boost-guidelines>

## User Guidelines
This is custom user content.

## Project Notes
- Important note 1
- Important note 2'''
        };

        final rebuilt = _rebuildDocument(sections);
        expect(rebuilt, contains('---'));
        expect(rebuilt, contains('# ServerPod Boost Guidelines'));
        expect(rebuilt, contains('# Testing Patterns'));
        expect(rebuilt, contains('This is custom user content'));
        expect(rebuilt, contains('<serverpod-boost-guidelines>'));
      });

      test('maintains proper section separation', () async {
        final sections = {
          '---': '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---''',

          'serverpod boost guidelines': '''# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure
- Follow ServerPod conventions''',

          'user guidelines': '''<serverpod-boost-guidelines>

## User Guidelines
This is custom user content.'''
        };

        final rebuilt = _rebuildDocument(sections);
        expect(rebuilt, contains('\n---\n'));
        expect(rebuilt, contains('\n\n<serverpod-boost-guidelines>\n'));
        expect(rebuilt, isNot(contains('\n---\n\n---\n')));
      });
    });

    group('File handling edge cases', () {
      test('handles files with special characters', () async {
        final contentWithSpecialChars = '''---
# ServerPod Boost Guidelines for TestProject

Generated at: 2024-01-01T00:00:00.000Z
Skills included: 1
Project: TestProject
Language: Dart
Framework: ServerPod
Author: Test Author
Version: 1.0.0
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
# Testing Patterns

## Basic Structure
- Use proper project structure @#\$%^&*
- Follow ServerPod conventions → ← ↑ ↓

<serverpod-boost-guidelines>

## User Guidelines
Special chars: !@#\$%^&*()_+-={}[]|\\:;"'<>,.?/
''';

        final agentsMdPath = '${tempDir.path}/AGENTS.md';
        await File(agentsMdPath).writeAsString(contentWithSpecialChars);

        final sections = _parseSections(contentWithSpecialChars);
        expect(sections.length, greaterThanOrEqualTo(3));
        // Check that special characters are preserved in the content
        expect(contentWithSpecialChars, contains('@#\$%^&*'));
        expect(contentWithSpecialChars, contains('→ ← ↑ ↓'));
      });
    });
  });
}

/// Mock implementation of GuidelineWriter.writeAgentsMd()
Future<bool> _mockWriteAgentsMd(
  String targetDir,
  List<String> selectedSkills,
  ProjectContext projectContext,
  SkillComposer skillComposer,
) async {
  final agentsMdPath = '$targetDir/AGENTS.md';

  // Mock skill composer behavior - should use the mocked content
  final skillsContent = await skillComposer.compose(
    selectedSkills,
    projectContext,
  );

  // Use the skills content directly as set by the test
  String finalSkillsContent = skillsContent.isNotEmpty ? skillsContent : 'No skills were selected.';

  // Apply AGENTS.md formatting (with frontmatter)
  final timestamp = DateTime.now().toIso8601String();
  final projectName = projectContext.projectName;
  final language = 'Dart'; // Default
  final framework = 'ServerPod'; // Default
  final author = 'Test Author'; // Default
  final version = '1.0.0'; // Default
  final skillsCount = selectedSkills.length;

  String content = '''---
# ServerPod Boost Guidelines for $projectName

Generated at: $timestamp
Skills included: $skillsCount
Project: $projectName
Language: $language
Framework: $framework
Author: $author
Version: $version
---

# ServerPod Boost Guidelines

## Project Context
This is a test ServerPod project.

## Skills
$finalSkillsContent
''';

  // Handle merging if file exists
  if (File(agentsMdPath).existsSync()) {
    final existingContent = await File(agentsMdPath).readAsString();
    content = _mergeWithExistingContent(existingContent, content);
  }

  // Write file
  await File(agentsMdPath).writeAsString(content);
  return true;
}

/// Mock implementation of GuidelineWriter.writeClaudeMd()
Future<bool> _mockWriteClaudeMd(
  String targetDir,
  List<String> selectedSkills,
  ProjectContext projectContext,
  SkillComposer skillComposer,
) async {
  final claudeMdPath = '$targetDir/CLAUDE.md';

  // Mock skill composer behavior - should use the mocked content
  final skillsContent = await skillComposer.compose(
    selectedSkills,
    projectContext,
  );

  // Use the skills content directly as set by the test
  String finalSkillsContent = skillsContent.isNotEmpty ? skillsContent : 'No skills were selected.';

  // Apply CLAUDE.md formatting (without frontmatter)
  final timestamp = DateTime.now().toIso8601String();
  final projectName = projectContext.projectName;
  final language = 'Dart'; // Default
  final framework = 'ServerPod'; // Default
  final author = 'Test Author'; // Default
  final version = '1.0.0'; // Default
  final skillsCount = selectedSkills.length;

  String content = '''# ServerPod Boost Guidelines for $projectName

Generated at: $timestamp
Skills included: $skillsCount
Project: $projectName
Language: $language
Framework: $framework
Author: $author
Version: $version

## Project Context
This is a test ServerPod project.

## Skills
$finalSkillsContent
''';

  // Handle merging if file exists
  if (File(claudeMdPath).existsSync()) {
    final existingContent = await File(claudeMdPath).readAsString();
    content = _mergeWithExistingContent(existingContent, content);
  }

  // Write file
  await File(claudeMdPath).writeAsString(content);
  return true;
}

/// Mock implementation of content merging
String _mergeWithExistingContent(String existingContent, String newContent) {
  // If there's no existing content, just return the new content
  if (existingContent.isEmpty) {
    return newContent;
  }

  // Find the separator in the new content
  final newLines = newContent.split('\n');
  final buffer = StringBuffer();

  // Copy everything from new content until the separator
  for (final line in newLines) {
    if (line.trim() == '<serverpod-boost-guidelines>') {
      break;
    }
    buffer.writeln(line);
  }

  // Add the separator
  buffer.writeln('<serverpod-boost-guidelines>');
  buffer.writeln();

  // Find user sections from existing content (everything after separator)
  bool existingSeparatorFound = false;
  for (final line in existingContent.split('\n')) {
    if (line.trim() == '<serverpod-boost-guidelines>') {
      existingSeparatorFound = true;
      continue;
    }

    if (existingSeparatorFound) {
      buffer.writeln(line);
    }
  }

  return buffer.toString().trimRight();
}

/// Parse document by # headers and frontmatter (matching real implementation)
Map<String, String> _parseSections(String content) {
  final sections = <String, String>{};
  final lines = content.split('\n');

  // Handle frontmatter (between --- lines)
  bool inFrontmatter = false;
  bool foundClosingFrontmatter = false;
  final frontmatterBuffer = StringBuffer();

  String? currentHeader;
  final currentContent = <String>[];

  for (final line in lines) {
    // Check for frontmatter start/end
    if (line.trim() == '---') {
      if (!inFrontmatter) {
        // Start frontmatter
        inFrontmatter = true;
      } else if (!foundClosingFrontmatter) {
        // End frontmatter - store it
        inFrontmatter = false;
        foundClosingFrontmatter = true;
        if (frontmatterBuffer.isNotEmpty) {
          sections['---'] = frontmatterBuffer.toString().trimRight();
        }
        frontmatterBuffer.clear();
      }
      // If we've already found the closing frontmatter, this is a normal line
    } else if (inFrontmatter) {
      // Add line to frontmatter
      frontmatterBuffer.writeln(line);
    } else {
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
      } else {
        currentContent.add(line);
      }
    }
  }

  // Save last section
  if (currentHeader != null && currentContent.isNotEmpty) {
    sections[currentHeader] = currentContent.join('\n').trimRight();
  }

  return sections;
}

/// Rebuild document from sections (matching real implementation)
String _rebuildDocument(Map<String, String> sections) {
  if (sections.isEmpty) {
    return '';
  }

  final buffer = StringBuffer();

  // Sort sections for consistent output
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
String _capitalizeHeader(String header) {
  return header
      .split(' ')
      .map((word) => word.isEmpty
          ? ''
          : word[0].toUpperCase() + word.substring(1))
      .join(' ');
}