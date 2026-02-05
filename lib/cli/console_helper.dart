/// Console helper utilities
///
/// Provides consistent formatting and output for CLI commands.
library serverpod_boost.cli.console_helper;

import 'dart:io';

/// Console helper for consistent output formatting
class ConsoleHelper {
  /// Get terminal width (fallback to 80 if unable to detect)
  static int get terminalWidth {
    try {
      // Try to get terminal width via stty
      final result = Process.runSync('stty', ['size'],
          runInShell: true, stderrEncoding: null, stdoutEncoding: null);

      if (result.exitCode == 0 && result.stdout != null) {
        final output = result.stdout as String;
        final parts = output.trim().split(' ');
        if (parts.length == 2) {
          return int.tryParse(parts[1]) ?? 80;
        }
      }
    } catch (_) {
      // Fallback to default
    }

    return 80;
  }

  /// Display a formatted header
  static void header(String title, {String? subtitle}) {
    final width = terminalWidth;
    final line = '═' * width;

    print(line);
    print(_centerText(title, width));
    if (subtitle != null) {
      print(_centerText(subtitle, width));
    }
    print(line);
    print('');
  }

  /// Display a sub-header
  static void subHeader(String title) {
    print('');
    print('┌─ $title');
    print('│');
  }

  /// Close a sub-header section
  static void closeSection() {
    print('│');
    print('└─ ${'─' * (terminalWidth - 3)}');
    print('');
  }

  /// Display success message
  static void success(String message) {
    print('\x1B[32m✓\x1B[0m $message');
  }

  /// Display error message
  static void error(String message) {
    stderr.writeln('\x1B[31m✗\x1B[0m $message');
  }

  /// Display warning message
  static void warning(String message) {
    print('\x1B[33m⚠\x1B[0m $message');
  }

  /// Display info message
  static void info(String message) {
    print('  $message');
  }

  /// Display indented text
  static void indent(String text, {int spaces = 2}) {
    final prefix = ' ' * spaces;
    print(prefix + text);
  }

  /// Display a list of items
  static void list(List<String> items, {int spaces = 2}) {
    for (final item in items) {
      indent(item, spaces: spaces);
    }
  }

  /// Display a grid of items (auto-fit to terminal width)
  static void grid(List<String> items) {
    if (items.isEmpty) return;

    final width = terminalWidth;
    final maxItemLength = items.map((e) => e.length).reduce((a, b) => a > b ? a : b);
    final columnWidth = maxItemLength + 4;
    final columns = (width / columnWidth).floor().clamp(1, items.length);

    for (var i = 0; i < items.length; i += columns) {
      final row = items.skip(i).take(columns).toList();
      final line = row.map((item) => item.padRight(columnWidth)).join();
      print(line);
    }
  }

  /// Display progress indicator
  static void progress(String message, {int current = 0, int total = 100}) {
    final percentage = total > 0 ? ((current / total) * 100).round() : 0;
    final bar = '█' * (percentage ~/ 5);
    final empty = '░' * (20 - (percentage ~/ 5));
    print('\r  [$bar$empty] $percentage% - $message');
  }

  /// Display a horizontal rule
  static void rule({String character = '─'}) {
    print(character * terminalWidth);
  }

  /// Display a bullet point
  static void bullet(String text, {String bullet = '•'}) {
    print('  $bullet $text');
  }

  /// Display a checkbox item
  static void checkbox(String text, {bool checked = false}) {
    final mark = checked ? '☑' : '☐';
    print('  $mark $text');
  }

  /// Display a step counter
  static void step(int step, int total, String description) {
    print('  [$step/$total] $description');
  }

  /// Clear current line
  static void clearLine() {
    stdout.write('\r\x1B[K');
  }

  /// Display a table
  static void table(List<List<String>> rows, {List<int>? columnWidths}) {
    if (rows.isEmpty) return;

    // Calculate column widths if not provided
    final widths = columnWidths ?? _calculateColumnWidths(rows);

    // Print each row
    for (final row in rows) {
      final cells = <String>[];
      for (var i = 0; i < row.length && i < widths.length; i++) {
        cells.add(row[i].padRight(widths[i]));
      }
      print(cells.join('  '));
    }
  }

  /// Calculate column widths for table
  static List<int> _calculateColumnWidths(List<List<String>> rows) {
    if (rows.isEmpty) return [];

    final columnCount = rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
    final widths = List<int>.filled(columnCount, 0);

    for (final row in rows) {
      for (var i = 0; i < row.length && i < columnCount; i++) {
        widths[i] = widths[i] > row[i].length ? widths[i] : row[i].length;
      }
    }

    return widths;
  }

  /// Center text within width
  static String _centerText(String text, int width) {
    final padding = (width - text.length) ~/ 2;
    return ' ' * padding + text;
  }

  /// Display a menu option
  static void menuOption(String key, String description) {
    print('  [$key] $description');
  }

  /// Display a prompt
  static String prompt(String question) {
    stdout.write('\x1B[36m?\x1B[0m $question ');
    return stdin.readLineSync() ?? '';
  }

  /// Display a confirmation prompt (Y/n)
  static bool confirm(String question, {bool defaultValue = true}) {
    final defaultHint = defaultValue ? 'Y/n' : 'y/N';
    stdout.write('\x1B[36m?\x1B[0m $question [$defaultHint] ');
    final response = stdin.readLineSync()?.toLowerCase().trim();

    if (response == null || response.isEmpty) {
      return defaultValue;
    }

    return response == 'y' || response == 'yes';
  }

  /// Display a selection prompt
  static String select(String question, List<String> options) {
    print('\x1B[36m?\x1B[0m $question');
    print('');

    for (var i = 0; i < options.length; i++) {
      menuOption('${i + 1}', options[i]);
    }

    print('');

    while (true) {
      final response = prompt('Select an option (1-${options.length})');
      final index = int.tryParse(response);

      if (index != null && index > 0 && index <= options.length) {
        return options[index - 1];
      }

      error('Invalid selection. Please try again.');
    }
  }

  /// Display a multi-select prompt
  static List<String> multiselect(String question, List<String> options,
      {List<int> defaultIndices = const []}) {
    print('\x1B[36m?\x1B[0m $question');
    print('');
    print('Select items by typing numbers separated by commas (e.g., 1,3,5)');
    print('Press Enter to confirm');
    print('');

    for (var i = 0; i < options.length; i++) {
      final isSelected = defaultIndices.contains(i + 1);
      final mark = isSelected ? '☑' : '☐';
      print('  $mark [${i + 1}] ${options[i]}');
    }

    print('');

    while (true) {
      stdout.write('\x1B[36m?\x1B[0m Selection [${defaultIndices.join(',')}] ');
      final response = stdin.readLineSync()?.trim();

      // Use default if empty
      if (response == null || response.isEmpty) {
        return defaultIndices.map((i) => options[i - 1]).toList();
      }

      // Parse selection
      final indices = response.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toList();

      // Validate
      final valid = indices.every((i) => i > 0 && i <= options.length);
      if (valid && indices.isNotEmpty) {
        return indices.map((i) => options[i - 1]).toList();
      }

      error('Invalid selection. Please try again.');
    }
  }

  /// Display a divider with text
  static void dividerWithText(String text) {
    final width = terminalWidth;
    final padding = (width - text.length - 4) ~/ 2;
    final left = '─' * padding;
    final right = '─' * (width - text.length - 4 - padding);
    print('$left  $text  $right');
  }

  /// Display an outro message
  static void outro(String message, {String? link}) {
    print('');
    rule();
    print(message);
    if (link != null) {
      print(link);
    }
    rule();
    print('');
  }

  /// New line
  static void newLine([int count = 1]) {
    print('\n' * (count - 1));
  }
}
