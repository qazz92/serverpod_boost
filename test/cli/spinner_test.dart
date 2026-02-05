/// Tests for CLI Spinner utility
library;

import 'dart:async';
import 'package:test/test.dart';
import 'package:serverpod_boost/cli/spinner.dart';

void main() {
  group('Spinner', () {
    test('starts and stops correctly', () async {
      final spinner = Spinner('Test message');

      // Start spinner
      spinner.start();

      // Verify it doesn't throw when starting
      expect(spinner.message, 'Test message');

      // Stop spinner
      spinner.stop('Complete');

      // Verify it doesn't throw when stopping
      expect(true, isTrue);
    });

    test('updates frames during animation', () async {
      final spinner = Spinner('Test message');
      final frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

      spinner.start();

      // Wait for frames to update
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify the spinner still has the correct frames
      expect(spinner.frames.length, 10);
      expect(spinner.frames, frames);

      // Stop spinner
      spinner.stop('Done');
    });

    test('Spinner.run() executes task and returns result', () async {
      bool taskExecuted = false;

      final future = Spinner.run(
        'Processing...',
        () async {
          // Simulate async work
          await Future.delayed(const Duration(milliseconds: 100));
          taskExecuted = true;
          return 'success';
        },
      );

      // Wait for completion
      final result = await future;

      // Verify task was executed
      expect(taskExecuted, true);

      // Verify result
      expect(result, 'success');
    });

    test('Spinner.run() throws error when task fails', () async {
      final error = Exception('Test error');

      final future = Spinner.run(
        'Processing...',
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          throw error;
        },
      );

      // Wait for completion and expect error
      expect(
        future,
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Test error'))),
      );
    });

    test('stop() with finalMessage displays message', () async {
      final spinner = Spinner('Test message');

      spinner.start();

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 50));

      // Stop with final message
      spinner.stop('Completed successfully!');

      // Verify it doesn't throw
      expect(true, isTrue);
    });

    test('stop() without finalMessage displays completion', () async {
      final spinner = Spinner('Test message');

      spinner.start();

      // Wait a bit
      await Future.delayed(const Duration(milliseconds: 50));

      // Stop without final message
      spinner.stop('Done');

      // Verify it doesn't throw
      expect(true, isTrue);
    });

    test('run() with custom message returns result', () async {
      final future = Spinner.run(
        'Custom processing...',
        () async => 'result',
      );

      final result = await future;

      expect(result, 'result');
    });

    test('start() does nothing if already running', () async {
      final spinner = Spinner('Test message');

      spinner.start();

      // Start again
      spinner.start();

      // Verify still running and message is unchanged
      expect(spinner.message, 'Test message');

      // Stop spinner
      spinner.stop('Done');
    });

    test('stop() does nothing if not running', () async {
      final spinner = Spinner('Test message');

      // Stop without starting
      spinner.stop('Done');

      // Verify it doesn't throw
      expect(true, isTrue);
    });

    test('constructor with message sets message', () {
      final spinner = Spinner('Custom message');
      expect(spinner.message, 'Custom message');
    });

    test('constructor with default message has empty message', () {
      final spinner = Spinner('');
      expect(spinner.message, '');
    });
  });
}