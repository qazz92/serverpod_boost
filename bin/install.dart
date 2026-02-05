/// ServerPod Boost Install - Quick install entry point
///
/// This is a convenience entry point that runs the install command.
/// It's equivalent to running: boost install
library serverpod_boost.bin.install;

import 'package:serverpod_boost/cli/cli_app.dart';

/// Main entry point for the install command
Future<void> main(List<String> args) async {
  // Prepend 'install' to args and route through the main CLI app
  final app = CLIApp();
  final installArgs = ['install', ...args];
  await app.run(installArgs);
}
