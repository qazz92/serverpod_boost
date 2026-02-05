/// Base command interface
///
/// All CLI commands must extend this abstract class.
library serverpod_boost.cli.command;

/// Abstract base class for CLI commands
abstract class Command {
  /// Command name (e.g., 'skill:list')
  String get name;

  /// Command description
  String get description;

  /// Run the command
  Future<void> run();
}
