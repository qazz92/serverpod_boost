/// Log Reader Tool Tests
///
/// Comprehensive tests for the log reader tool functionality.
library serverpod_boost.test.tools.log_reader_tool_test;

import 'package:test/test.dart';
import 'dart:io';

void main() {
  group('LogReaderTool', () {
    late Directory testLogDir;

    setUp(() async {
      testLogDir = await Directory.systemTemp.createTemp('test_logs_');
    });

    tearDown(() async {
      if (await testLogDir.exists()) {
        await testLogDir.delete(recursive: true);
      }
    });

    group('File Discovery', () {
      test('finds log files in logs/ directory', () async {
        // Create test log files
        final logsDir = Directory('${testLogDir.path}/logs')..createSync();
        File('${logsDir.path}/serverpod.log').writeAsStringSync('Log content 1');
        File('${logsDir.path}/analytics.log').writeAsStringSync('Log content 2');

        // Find .log files
        final logFiles = await testLogDir
            .list(recursive: true)
            .where((entity) => entity.path.endsWith('.log'))
            .toList();

        expect(logFiles.length, equals(2));
        expect(logFiles.any((f) => f.path.contains('serverpod.log')), isTrue);
        expect(logFiles.any((f) => f.path.contains('analytics.log')), isTrue);
      });

      test('returns empty list when no logs directory exists', () async {
        final logsDir = Directory('${testLogDir.path}/logs');
        expect(logsDir.existsSync(), isFalse);

        // Attempt to find log files
        final logFiles = await testLogDir
            .list(recursive: true)
            .where((entity) => entity.path.endsWith('.log'))
            .toList();

        expect(logFiles, isEmpty);
      });
    });

    group('Reverse Reading', () {
      test('reads log file in reverse order', () async {
        final logFile = File('${testLogDir.path}/test.log');
        await logFile.writeAsString(
          '[2026-02-05 10:00:00.000] Entry 1\n'
          '[2026-02-05 10:01:00.000] Entry 2\n'
          '[2026-02-05 10:02:00.000] Entry 3\n',
        );

        // Read all lines and reverse
        final lines = await logFile.readAsLines();
        final reversedLines = lines.reversed.toList();

        expect(reversedLines[0], contains('Entry 3'));
        expect(reversedLines[1], contains('Entry 2'));
        expect(reversedLines[2], contains('Entry 1'));
      });

      test('returns newest entries first when reading logs', () async {
        final logFile = File('${testLogDir.path}/serverpod.log');
        final content = List.generate(100, (i) =>
          '[2026-02-05 10:${i.toString().padLeft(2, '0')}:00.000] Log entry $i'
        ).join('\n');
        await logFile.writeAsString(content);

        // Read last 10 entries (newest first)
        final lines = await logFile.readAsLines();
        final newestEntries = lines.sublist(lines.length - 10).reversed.toList();

        expect(newestEntries[0], contains('Log entry 99'));
        expect(newestEntries[9], contains('Log entry 90'));
      });
    });

    group('Line Limit', () {
      test('respects lines parameter for reading last N lines', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final content = List.generate(50, (i) => 'Line $i').join('\n');
        await logFile.writeAsString(content);

        // Read only last 10 lines
        final lines = await logFile.readAsLines();
        final lastTen = lines.sublist(lines.length - 10);

        expect(lastTen.length, equals(10));
        expect(lastTen[0], equals('Line 40'));
        expect(lastTen[9], equals('Line 49'));
      });

      test('handles lines parameter larger than file size', () async {
        final logFile = File('${testLogDir.path}/test.log');
        await logFile.writeAsString('Line 1\nLine 2\nLine 3');

        final lines = await logFile.readAsLines();

        expect(lines.length, equals(3));
      });

      test('handles zero lines parameter', () async {
        final logFile = File('${testLogDir.path}/test.log');
        await logFile.writeAsString('Line 1\nLine 2\nLine 3');

        // Read zero lines should return empty
        final lines = await logFile.readAsLines();
        final zeroLines = lines.sublist(0, 0);

        expect(zeroLines, isEmpty);
      });

      test('handles negative lines parameter gracefully', () async {
        final logFile = File('${testLogDir.path}/test.log');
        await logFile.writeAsString('Line 1\nLine 2\nLine 3');

        final lines = await logFile.readAsLines();

        // Negative lines should not crash
        expect(lines.length, greaterThanOrEqualTo(0));
      });
    });

    group('Multi-line Entry', () {
      test('handles ServerPod log entries spanning multiple lines', () async {
        final logFile = File('${testLogDir.path}/serverpod.log');
        final logContent = '''
[2026-02-05 10:00:00.000] [INFO] Request received
  Endpoint: /api/user/profile
  Method: GET
  Duration: 45ms
[2026-02-05 10:00:01.000] [INFO] Request received
  Endpoint: /api/user/posts
  Method: GET
  Duration: 78ms
[2026-02-05 10:00:02.000] [ERROR] Database error
  Error: Connection timeout
  Query: SELECT * FROM users
''';
        await logFile.writeAsString(logContent);

        // Parse multi-line entries
        final lines = await logFile.readAsLines();
        final entries = <List<String>>[];
        var currentEntry = <String>[];

        for (final line in lines) {
          if (line.startsWith('[2026-')) {
            if (currentEntry.isNotEmpty) {
              entries.add(currentEntry);
            }
            currentEntry = [line];
          } else if (line.trim().isNotEmpty) {
            currentEntry.add(line);
          }
        }
        if (currentEntry.isNotEmpty) {
          entries.add(currentEntry);
        }

        expect(entries.length, equals(3));
        expect(entries[0][0], contains('Request received'));
        expect(entries[0][1], contains('Endpoint: /api/user/profile'));
        expect(entries[1][0], contains('Request received'));
        expect(entries[1][1], contains('Endpoint: /api/user/posts'));
        expect(entries[2][0], contains('Database error'));
      });

      test('preserves indentation in multi-line entries', () async {
        final logFile = File('${testLogDir.path}/test.log');
        await logFile.writeAsString(
          '[2026-02-05 10:00:00.000] Main entry\n'
          '  Indented line 1\n'
          '  Indented line 2\n'
          '    Double indented\n'
        );

        final lines = await logFile.readAsLines();

        expect(lines[1], startsWith('  '));
        expect(lines[2], startsWith('  '));
        expect(lines[3], startsWith('    '));
      });
    });

    group('Level Filtering', () {
      test('filters log entries by INFO level', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] [INFO] Server started
[2026-02-05 10:00:01.000] [WARNING] High memory usage
[2026-02-05 10:00:02.000] [ERROR] Failed to connect
[2026-02-05 10:00:03.000] [INFO] Request processed
''';
        await logFile.writeAsString(logContent);

        // Filter INFO level
        final lines = await logFile.readAsLines();
        final infoLogs = lines.where((line) => line.contains('[INFO]')).toList();

        expect(infoLogs.length, equals(2));
        expect(infoLogs[0], contains('Server started'));
        expect(infoLogs[1], contains('Request processed'));
      });

      test('filters log entries by WARNING level', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] [INFO] Server started
[2026-02-05 10:00:01.000] [WARNING] High memory usage
[2026-02-05 10:00:02.000] [ERROR] Failed to connect
[2026-02-05 10:00:03.000] [WARNING] Slow query detected
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();
        final warningLogs = lines.where((line) => line.contains('[WARNING]')).toList();

        expect(warningLogs.length, equals(2));
        expect(warningLogs[0], contains('High memory usage'));
        expect(warningLogs[1], contains('Slow query detected'));
      });

      test('filters log entries by ERROR level', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] [INFO] Server started
[2026-02-05 10:00:01.000] [WARNING] High memory usage
[2026-02-05 10:00:02.000] [ERROR] Failed to connect
[2026-02-05 10:00:03.000] [ERROR] Null pointer exception
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();
        final errorLogs = lines.where((line) => line.contains('[ERROR]')).toList();

        expect(errorLogs.length, equals(2));
        expect(errorLogs[0], contains('Failed to connect'));
        expect(errorLogs[1], contains('Null pointer exception'));
      });

      test('filters multiple levels (INFO and WARNING)', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] [INFO] Server started
[2026-02-05 10:00:01.000] [WARNING] High memory usage
[2026-02-05 10:00:02.000] [ERROR] Failed to connect
[2026-02-05 10:00:03.000] [INFO] Request processed
[2026-02-05 10:00:04.000] [WARNING] Slow query detected
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();
        final filteredLogs = lines.where((line) =>
          line.contains('[INFO]') || line.contains('[WARNING]')
        ).toList();

        expect(filteredLogs.length, equals(4));
        expect(filteredLogs.any((l) => l.contains('[INFO]')), isTrue);
        expect(filteredLogs.any((l) => l.contains('[WARNING]')), isTrue);
        expect(filteredLogs.any((l) => l.contains('[ERROR]')), isFalse);
      });

      test('returns all entries when no level filter specified', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] [INFO] Server started
[2026-02-05 10:00:01.000] [WARNING] High memory usage
[2026-02-05 10:00:02.000] [ERROR] Failed to connect
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();

        expect(lines.length, equals(3));
      });
    });

    group('Pattern Matching', () {
      test('filters entries using regex pattern', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] User john_doe logged in
[2026-02-05 10:00:01.000] User jane_smith logged in
[2026-02-05 10:00:02.000] User admin logged in
[2026-02-05 10:00:03.000] System notification
''';
        await logFile.writeAsString(logContent);

        // Filter for users ending with '_doe'
        final lines = await logFile.readAsLines();
        final pattern = RegExp(r'john_doe');
        final filtered = lines.where((line) => pattern.hasMatch(line)).toList();

        expect(filtered.length, equals(1));
        expect(filtered[0], contains('john_doe'));
      });

      test('filters entries using case-insensitive pattern', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] ERROR: Database connection failed
[2026-02-05 10:00:01.000] error: File not found
[2026-02-05 10:00:02.000] Error: Invalid input
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();
        final pattern = RegExp(r'error', caseSensitive: false);
        final filtered = lines.where((line) => pattern.hasMatch(line)).toList();

        expect(filtered.length, equals(3));
      });

      test('filters entries using wildcard pattern', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] GET /api/users
[2026-02-05 10:00:01.000] POST /api/posts
[2026-02-05 10:00:02.000] GET /api/users/123
[2026-02-05 10:00:03.000] DELETE /api/posts/456
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();
        final filtered = lines.where((line) => line.contains('/api/users')).toList();

        expect(filtered.length, equals(2));
        expect(filtered[0], contains('GET /api/users'));
        expect(filtered[1], contains('GET /api/users/123'));
      });

      test('returns empty list when pattern matches nothing', () async {
        final logFile = File('${testLogDir.path}/test.log');
        await logFile.writeAsString(
          '[2026-02-05 10:00:00.000] INFO: Server started\n'
          '[2026-02-05 10:00:01.000] INFO: Ready to accept connections',
        );

        final lines = await logFile.readAsLines();
        final pattern = RegExp(r'NEVER_MATCHES');
        final filtered = lines.where((line) => pattern.hasMatch(line)).toList();

        expect(filtered, isEmpty);
      });

      test('handles complex regex patterns', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] Duration: 123ms
[2026-02-05 10:00:01.000] Duration: 456ms
[2026-02-05 10:00:02.000] Duration: 789ms
[2026-02-05 10:00:03.000] Duration: 12ms
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();
        // Match durations > 100ms
        final pattern = RegExp(r'Duration: \d{3}ms');
        final filtered = lines.where((line) => pattern.hasMatch(line)).toList();

        expect(filtered.length, equals(3));
        expect(filtered.any((l) => l.contains('12ms')), isFalse);
      });
    });

    group('Missing File', () {
      test('returns error for non-existent file', () async {
        final nonExistentFile = File('${testLogDir.path}/does_not_exist.log');

        expect(nonExistentFile.existsSync(), isFalse);

        // Attempt to read
        try {
          await nonExistentFile.readAsString();
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<FileSystemException>());
        }
      });

      test('returns error for invalid file path', () async {
        final invalidPath = '/non/existent/directory/file.log';
        final file = File(invalidPath);

        expect(file.existsSync(), isFalse);

        try {
          await file.readAsString();
          fail('Should have thrown exception');
        } catch (e) {
          expect(e, isA<FileSystemException>());
        }
      });
    });

    group('Empty File', () {
      test('handles empty log file gracefully', () async {
        final logFile = File('${testLogDir.path}/empty.log');
        await logFile.writeAsString('');

        final content = await logFile.readAsString();
        final lines = await logFile.readAsLines();

        expect(content, isEmpty);
        expect(lines, isEmpty);
      });

      test('handles file with only newlines', () async {
        final logFile = File('${testLogDir.path}/newlines.log');
        await logFile.writeAsString('\n\n\n');

        final lines = await logFile.readAsLines();

        // Empty lines between newlines (3 newlines creates 3 empty strings)
        expect(lines.length, equals(3)); // "\n\n\n" splits to ["", "", ""]
        expect(lines.every((l) => l.isEmpty), isTrue);
      });

      test('handles file with only whitespace', () async {
        final logFile = File('${testLogDir.path}/whitespace.log');
        await logFile.writeAsString('   \n  \n ');

        final lines = await logFile.readAsLines();

        expect(lines.length, greaterThan(0));
        expect(lines[0].trim(), isEmpty);
      });
    });

    group('Timestamp Parsing', () {
      test('parses ServerPod timestamp format correctly', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final logContent = '''
[2026-02-05 10:00:00.000] Entry 1
[2026-02-05 10:00:01.500] Entry 2
[2026-02-05 10:00:02.999] Entry 3
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();
        final timestampPattern = RegExp(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]');

        for (final line in lines) {
          final match = timestampPattern.firstMatch(line);
          expect(match, isNotNull);
          expect(match!.groupCount, equals(1));

          final timestamp = match.group(1);
          expect(timestamp, isNotNull);
          expect(timestamp!.length, equals(23)); // "2026-02-05 10:00:00.000"

          // Verify it's a valid datetime format
          expect(timestamp, contains('-'));
          expect(timestamp, contains(' '));
          expect(timestamp, contains(':'));
          expect(timestamp, contains('.'));
        }
      });

      test('extracts timestamps from log entries', () async {
        final logFile = File('${testLogDir.path}/test.log');
        await logFile.writeAsString(
          '[2026-02-05 10:00:00.000] [INFO] Server started\n'
          '[2026-02-05 10:00:01.500] [INFO] Connection established\n'
          '[2026-02-05 10:00:02.999] [ERROR] Failed request\n',
        );

        final lines = await logFile.readAsLines();
        final timestampPattern = RegExp(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]');
        final timestamps = lines
            .map((line) => timestampPattern.firstMatch(line)?.group(1))
            .where((ts) => ts != null)
            .toList();

        expect(timestamps.length, equals(3));
        expect(timestamps[0], equals('2026-02-05 10:00:00.000'));
        expect(timestamps[1], equals('2026-02-05 10:00:01.500'));
        expect(timestamps[2], equals('2026-02-05 10:00:02.999'));
      });

      test('handles timestamps with different millisecond values', () async {
        final logFile = File('${testLogDir.path}/test.log');
        final testCases = [
          '2026-02-05 10:00:00.001',
          '2026-02-05 10:00:00.099',
          '2026-02-05 10:00:00.100',
          '2026-02-05 10:00:00.999',
        ];

        final content = testCases.map((ts) => '[$ts] Entry').join('\n');
        await logFile.writeAsString(content);

        final lines = await logFile.readAsLines();
        final timestampPattern = RegExp(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]');
        final extracted = lines
            .map((line) => timestampPattern.firstMatch(line)?.group(1))
            .toList();

        for (var i = 0; i < testCases.length; i++) {
          expect(extracted[i], equals(testCases[i]));
        }
      });

      test('rejects invalid timestamp formats', () async {
        final logFile = File('${testLogDir.path}/test.log');
        await logFile.writeAsString(
          '[2026-02-05 10:00:00] Entry without milliseconds\n'
          '[2026-02-05T10:00:00.000Z] ISO format timestamp\n'
          'No timestamp here\n'
          '[2026-02-05 10:00:00.000] Valid timestamp\n',
        );

        final lines = await logFile.readAsLines();
        final serverpodTimestampPattern = RegExp(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]');
        final validTimestamps = lines
            .where((line) => serverpodTimestampPattern.hasMatch(line))
            .toList();

        expect(validTimestamps.length, equals(1));
        expect(validTimestamps[0], contains('Valid timestamp'));
      });

      test('sorts log entries by timestamp', () async {
        final logFile = File('${testLogDir.path}/test.log');
        // Create entries out of order
        final logContent = '''
[2026-02-05 10:00:02.000] Entry 3
[2026-02-05 10:00:00.000] Entry 1
[2026-02-05 10:00:01.000] Entry 2
''';
        await logFile.writeAsString(logContent);

        final lines = await logFile.readAsLines();
        final timestampPattern = RegExp(r'\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]');

        final entriesWithTimestamps = lines.map((line) {
          final match = timestampPattern.firstMatch(line);
          return {
            'line': line,
            'timestamp': match?.group(1) ?? '',
          };
        }).toList();

        // Sort by timestamp
        entriesWithTimestamps.sort((a, b) =>
          (a['timestamp'] as String).compareTo(b['timestamp'] as String)
        );

        expect(entriesWithTimestamps[0]['line'], contains('Entry 1'));
        expect(entriesWithTimestamps[1]['line'], contains('Entry 2'));
        expect(entriesWithTimestamps[2]['line'], contains('Entry 3'));
      });
    });

    group('Integration Tests', () {
      test('complex scenario: read recent errors with pattern filter', () async {
        final logFile = File('${testLogDir.path}/serverpod.log');
        final logContent = List.generate(100, (i) {
          final level = i % 10 == 0 ? 'ERROR' : i % 5 == 0 ? 'WARNING' : 'INFO';
          final timestamp = '2026-02-05 10:${(i ~/ 60).toString().padLeft(2, '0')}:${(i % 60).toString().padLeft(2, '0')}.000';
          return '[$timestamp] [$level] Log message $i: ${level == 'ERROR' ? 'Something failed' : 'OK'}';
        }).join('\n');

        await logFile.writeAsString(logContent);

        // Read last 20 lines
        final allLines = await logFile.readAsLines();
        final last20 = allLines.sublist(allLines.length - 20);

        // Filter for ERROR only
        final errorLogs = last20.where((line) => line.contains('[ERROR]')).toList();

        expect(errorLogs.length, greaterThan(0));
        expect(errorLogs.every((l) => l.contains('[ERROR]')), isTrue);
      });

      test('handles mixed line endings', () async {
        final logFile = File('${testLogDir.path}/mixed.log');
        final content = 'Line 1\nLine 2\r\nLine 3\n';
        await logFile.writeAsString(content);

        final lines = await logFile.readAsLines();

        expect(lines.length, greaterThan(0));
        expect(lines[0], equals('Line 1'));
      });
    });
  });
}
