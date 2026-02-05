import 'dart:io';
import 'package:console/console.dart';

class ConsoleHelper {
  static void header(String text) {
    stdout.writeln('');
    stdout.writeln('═' * 50);
    stdout.writeln(text);
    stdout.writeln('═' * 50);
    stdout.writeln('');
  }

  static void section(String text) {
    stdout.writeln('');
    stdout.writeln('▸ $text');
    stdout.writeln('');
  }

  static void success(String text) {
    TextPen().green().text('✓ $text').print();
  }

  static void error(String text) {
    TextPen().red().text('✗ $text').print();
  }

  static void warning(String text) {
    TextPen().yellow().text('⚠ $text').print();
  }

  static void info(String text) {
    TextPen().blue().text('ℹ $text').print();
  }

  static void clear() {
    stdout.write('\x1B[2J\x1B[H');
  }
}
