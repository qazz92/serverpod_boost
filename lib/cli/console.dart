import 'package:console/console.dart';

class ConsoleHelper {
  static void header(String text) {
    print('');
    print('═' * 50);
    print(text);
    print('═' * 50);
    print('');
  }

  static void section(String text) {
    print('');
    print('▸ $text');
    print('');
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
    print('\x1B[2J\x1B[H');
  }
}