/// Log Reader Tool
///
/// Read ServerPod log files with filtering options.
/// Supports reverse reading, multi-line entries, and log level filtering.
library serverpod_boost.tools.log_reader_tool;

import 'dart:io';
import 'package:path/path.dart' as p;

import '../mcp/mcp_tool.dart';
import '../serverpod/serverpod_locator.dart';

/// Log entry parsed from ServerPod log file
class LogEntry {
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.raw,
  });

  /// Timestamp from log entry
  final String timestamp;

  /// Log level (INFO, WARNING, ERROR, etc.)
  final String level;

  /// Full log message (may contain newlines)
  final String message;

  /// Raw entry text
  final String raw;

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'level': level,
    'message': message,
    'raw': raw,
  };

  @override
  String toString() => '[$timestamp] $level: $message';
}

/// Log Reader Tool for ServerPod Boost
///
/// Reads and parses ServerPod log files with support for:
/// - Reverse reading (newest first, like tail -n)
/// - Multi-line entry support
/// - Log level filtering (INFO, WARNING, ERROR)
/// - Multiple log file support with glob patterns
class LogReaderTool extends McpToolBase {
  @override
  String get name => 'log_reader';

  @override
  String get description => '''
Read ServerPod log files with filtering options.

Supports:
- Reverse reading (newest entries first, like tail -n)
- Multi-line entry detection
- Log level filtering (INFO, WARNING, ERROR, ALL)
- Regex pattern filtering
- Multiple log files (uses glob patterns)
  ''';

  @override
  Map<String, dynamic> get inputSchema => McpSchema.inputSchema(
    type: 'object',
    properties: {
      'file': McpSchema.string(
        description: 'Log file name or pattern (default: serverpod.log). Supports glob patterns like "serverpod-*.log"',
        defaultValue: 'serverpod.log',
      ),
      'lines': McpSchema.integer(
        description: 'Number of log entries to return (default: 100, max: 1000)',
        defaultValue: 100,
      ),
      'level': McpSchema.enumProperty(
        values: ['INFO', 'WARNING', 'ERROR', 'ALL'],
        description: 'Filter by log level',
        defaultValue: 'ALL',
      ),
      'pattern': McpSchema.string(
        description: 'Regex pattern to filter log entries (searches in message content)',
      ),
    },
  );

  @override
  String? validateParams(Map<String, dynamic>? params) {
    if (params == null) return null;

    // Validate lines parameter
    final lines = params['lines'];
    if (lines != null && lines is int) {
      if (lines < 1) {
        return 'lines must be at least 1';
      }
      if (lines > 1000) {
        return 'lines cannot exceed 1000';
      }
    }

    // Validate level parameter
    final level = params['level'];
    if (level != null && level is String) {
      const validLevels = ['INFO', 'WARNING', 'ERROR', 'ALL'];
      if (!validLevels.contains(level)) {
        return 'level must be one of: ${validLevels.join(', ')}';
      }
    }

    return null;
  }

  @override
  Future<dynamic> executeImpl(Map<String, dynamic> params) async {
    final project = ServerPodLocator.getProject();
    if (project == null || !project.isValid) {
      return {
        'error': 'Not a valid ServerPod project',
        'message': 'Could not locate ServerPod project',
      };
    }

    // Get parameters
    final filePattern = params['file'] as String? ?? 'serverpod.log';
    final lines = (params['lines'] as int?) ?? 100;
    final levelFilter = params['level'] as String? ?? 'ALL';
    final regexPattern = params['pattern'] as String?;

    // Find log directory
    final logDir = _findLogDirectory(project);
    if (logDir == null) {
      return {
        'error': 'Log directory not found',
        'message': 'Could not locate logs/ directory in ServerPod project',
        'searchedPaths': _getSearchedLogPaths(project),
      };
    }

    // Find log files matching pattern
    final logFiles = _findLogFiles(logDir, filePattern);
    if (logFiles.isEmpty) {
      return {
        'error': 'No log files found',
        'pattern': filePattern,
        'logDirectory': logDir.path,
        'message': 'No log files match the specified pattern',
      };
    }

    // Use the most recent log file (by modification time)
    logFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    final primaryLogFile = logFiles.first;

    try {
      // Read and parse log entries
      final entries = await _readLogEntries(
        primaryLogFile,
        maxEntries: lines,
        levelFilter: levelFilter,
        patternFilter: regexPattern,
      );

      return {
        'entries': entries.map((e) => e.toJson()).toList(),
        'file': p.basename(primaryLogFile.path),
        'path': primaryLogFile.path,
        'relativePath': p.relative(primaryLogFile.path, from: project.rootPath),
        'totalEntries': entries.length,
        'requestedLines': lines,
        'levelFilter': levelFilter,
        'patternFilter': regexPattern,
        'logDirectory': logDir.path,
      };
    } catch (e) {
      return {
        'error': 'Failed to read log file',
        'file': primaryLogFile.path,
        'message': e.toString(),
      };
    }
  }

  /// Find the logs directory in the ServerPod project
  Directory? _findLogDirectory(ServerPodProject project) {
    // Common log directory locations
    final candidates = [
      // Standard ServerPod location (in server package)
      if (project.serverPath != null) p.join(project.serverPath!, 'logs'),
      // Project root level
      p.join(project.rootPath, 'logs'),
      // Current working directory
      p.join(Directory.current.path, 'logs'),
    ];

    for (final candidate in candidates) {
      final dir = Directory(candidate);
      if (dir.existsSync()) {
        return dir;
      }
    }

    return null;
  }

  /// Get list of searched log paths (for error messages)
  List<String> _getSearchedLogPaths(ServerPodProject project) {
    return [
      if (project.serverPath != null) p.join(project.serverPath!, 'logs'),
      p.join(project.rootPath, 'logs'),
      p.join(Directory.current.path, 'logs'),
    ];
  }

  /// Find log files matching the given pattern
  List<File> _findLogFiles(Directory logDir, String pattern) {
    final files = <File>[];

    // Check if pattern contains glob characters
    final hasGlob = pattern.contains('*') || pattern.contains('?');

    if (hasGlob) {
      // Use glob pattern matching
      for (final entity in logDir.listSync()) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (_matchesGlobPattern(name, pattern)) {
            files.add(entity);
          }
        }
      }
    } else {
      // Direct file lookup
      final file = File(p.join(logDir.path, pattern));
      if (file.existsSync()) {
        files.add(file);
      }
    }

    return files;
  }

  /// Simple glob pattern matching (supports * wildcards)
  bool _matchesGlobPattern(String filename, String pattern) {
    // Convert glob pattern to regex
    final regexPattern = pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');

    final regex = RegExp('^$regexPattern\$');
    return regex.hasMatch(filename);
  }

  /// Read and parse log entries from file (reverse order)
  Future<List<LogEntry>> _readLogEntries(
    File file, {
    required int maxEntries,
    required String levelFilter,
    String? patternFilter,
  }) async {
    final entries = <LogEntry>[];

    // Read entire file (for simplicity; could be optimized for large files)
    final lines = await file.readAsLines();

    // Compile regex pattern if provided
    RegExp? patternRegex;
    if (patternFilter != null && patternFilter.isNotEmpty) {
      try {
        patternRegex = RegExp(patternFilter, caseSensitive: false);
      } catch (e) {
        // Invalid regex - ignore pattern filter
      }
    }

    // Parse lines in reverse order (newest first)
    List<String>? currentEntryLines;

    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];

      if (_isLogEntryStart(line)) {
        // Found start of a new log entry
        if (currentEntryLines != null) {
          // Parse the accumulated entry
          final entry = _parseLogEntry(currentEntryLines);

          // Apply filters
          if (_matchesLevelFilter(entry.level, levelFilter) &&
              _matchesPatternFilter(entry, patternRegex)) {
            entries.add(entry);

            // Stop if we've reached max entries
            if (entries.length >= maxEntries) {
              break;
            }
          }
        }

        // Start new entry
        currentEntryLines = [line];
      } else if (currentEntryLines != null) {
        // Continuation of multi-line entry (add in reverse order)
        currentEntryLines.insert(0, line);
      }
    }

    // Don't forget the first entry
    if (currentEntryLines != null && entries.length < maxEntries) {
      final entry = _parseLogEntry(currentEntryLines);
      if (_matchesLevelFilter(entry.level, levelFilter) &&
          _matchesPatternFilter(entry, patternRegex)) {
        entries.add(entry);
      }
    }

    return entries;
  }

  /// Check if line is the start of a new log entry
  bool _isLogEntryStart(String line) {
    // ServerPod log format: [YYYY-MM-DD HH:MM:SS.mmm] [LEVEL]
    final timestampPattern = RegExp(r'^\[\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d{3}\]');
    return timestampPattern.hasMatch(line);
  }

  /// Parse log entry from accumulated lines
  LogEntry _parseLogEntry(List<String> lines) {
    if (lines.isEmpty) {
      return LogEntry(
        timestamp: '',
        level: 'UNKNOWN',
        message: '',
        raw: '',
      );
    }

    // First line contains timestamp and level
    final firstLine = lines.first;

    // Extract timestamp: [YYYY-MM-DD HH:MM:SS.mmm]
    final timestampMatch = RegExp(r'\[(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d{3})\]').firstMatch(firstLine);
    final timestamp = timestampMatch?.group(1) ?? '';

    // Extract level: [LEVEL]
    final levelMatch = RegExp(r'\[([A-Z]+)\]').firstMatch(firstLine);
    final level = levelMatch?.group(1) ?? 'INFO';

    // Extract message (everything after timestamp and level)
    final messageStart = timestampMatch?.end ?? 0;
    final levelEnd = levelMatch?.end ?? 0;
    final messageStartIndex = levelEnd > messageStart ? levelEnd : messageStart;

    String message;
    if (lines.length == 1) {
      message = firstLine.substring(messageStartIndex).trim();
    } else {
      // Multi-line entry
      final firstLineMessage = firstLine.substring(messageStartIndex).trim();
      final remainingLines = lines.sublist(1).join('\n');
      message = '$firstLineMessage\n$remainingLines';
    }

    // Raw entry
    final raw = lines.join('\n');

    return LogEntry(
      timestamp: timestamp,
      level: level,
      message: message,
      raw: raw,
    );
  }

  /// Check if log level matches filter
  bool _matchesLevelFilter(String level, String filter) {
    if (filter == 'ALL') return true;
    return level == filter;
  }

  /// Check if entry matches pattern filter
  bool _matchesPatternFilter(LogEntry entry, RegExp? pattern) {
    if (pattern == null) return true;
    return pattern.hasMatch(entry.message);
  }
}
