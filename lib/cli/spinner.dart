import 'dart:async';
import 'dart:io';

class Spinner {
  final String message;
  final List<String> frames;

  Timer? _timer;
  int _frameIndex = 0;
  bool _isRunning = false;

  Spinner(this.message)
      : frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  void start() {
    if (_isRunning) return;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _frameIndex = (_frameIndex + 1) % frames.length;
      _update();
    });
  }

  void stop(String? finalMessage) {
    if (!_isRunning) return;
    _isRunning = false;

    _timer?.cancel();
    _clear();

    if (finalMessage != null) {
      print(finalMessage);
    }
  }

  void _update() {
    _clear();
    stdout.write('${frames[_frameIndex]} $message');
  }

  void _clear() {
    stdout.write('\r' * (message.length + 3));
  }

  static Future<T> run<T>(
    String message,
    Future<T> Function() task,
  ) async {
    final spinner = Spinner(message);
    spinner.start();

    try {
      final result = await task();
      spinner.stop('✓ $message');
      return result;
    } catch (e) {
      spinner.stop('✗ $message');
      rethrow;
    }
  }
}