import 'skill.dart';

/// Resolves naming conflicts between skills
///
/// This utility class helps resolve naming conflicts when multiple skills
/// have the same name. It provides methods to detect conflicts and resolve them
/// by either selecting the first occurrence (in simple cases) or requiring
/// user intervention in advanced scenarios.
class SkillConflictResolver {
  /// Resolve naming conflicts between skills
  ///
  /// Groups skills by name and resolves conflicts by selecting the first occurrence
  /// of each duplicate name. In a full interactive version, this would prompt
  /// the user to choose between conflicting skills.
  ///
  /// Args:
  ///   skills: List of skills to resolve conflicts for
  ///
  /// Returns:
  ///   List of skills with conflicts resolved (no duplicate names)
  ///
  /// Throws:
  ///   ArgumentError: If skills list is null or contains null values
  Future<List<Skill>> resolve(List<Skill> skills) async {
    // In Dart's null safety, skills cannot be null and cannot contain null values
    // All skills are guaranteed to be non-null by the type system

    final grouped = <String, List<Skill>>{};

    for (final skill in skills) {
      grouped.putIfAbsent(skill.name, () => []).add(skill);
    }

    final resolved = <Skill>[];

    for (final entry in grouped.entries) {
      if (entry.value.length == 1) {
        resolved.add(entry.value.single);
      } else {
        // Conflict detected - user would need to choose
        // For now, take the first one
        resolved.add(entry.value.first);
      }
    }

    return resolved;
  }

  /// Check for conflicts in a list of skills
  ///
  /// Efficiently checks if any skills have duplicate names.
  ///
  /// Args:
  ///   skills: List of skills to check for conflicts
  ///
  /// Returns:
  ///   true if conflicts exist, false otherwise
  ///
  /// Throws:
  ///   ArgumentError: If skills list is null or contains null values
  static bool hasConflicts(List<Skill> skills) {
    // In Dart's null safety, skills cannot be null and cannot contain null values
    // All skills are guaranteed to be non-null by the type system

    final names = <String>{};
    for (final skill in skills) {
      if (names.contains(skill.name)) {
        return true;
      }
      names.add(skill.name);
    }
    return false;
  }

  /// Get list of conflicting names from a list of skills
  ///
  /// Returns a list of names that appear more than once in the skills list.
  /// Useful for providing detailed conflict information to users.
  ///
  /// Args:
  ///   skills: List of skills to check for conflicts
  ///
  /// Returns:
  ///   List of conflicting skill names
  ///
  /// Throws:
  ///   ArgumentError: If skills list is null or contains null values
  static List<String> getConflicts(List<Skill> skills) {
    // In Dart's null safety, skills cannot be null and cannot contain null values
    // All skills are guaranteed to be non-null by the type system

    final seen = <String>{};
    final conflicts = <String>[];

    for (final skill in skills) {
      if (seen.contains(skill.name)) {
        if (!conflicts.contains(skill.name)) {
          conflicts.add(skill.name);
        }
      } else {
        seen.add(skill.name);
      }
    }

    return conflicts;
  }
}