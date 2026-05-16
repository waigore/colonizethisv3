/// CLI: Full-AI observer game runner (thin facade).
/// SPEC/program/run_observer_game-tool.md
import 'dart:io';

import 'package:run_observer_game/package_logger.dart';
import 'package:run_observer_game/run_observer_game_cli.dart';

final _log = packageLogger('cli');

void main(List<String> arguments) {
  final code = runObserverGameCli(
    arguments,
    emitStdout: stdout.writeln,
    emitStderr: (line) {
      stderr.writeln(line);
      _log.e(line);
    },
  );
  exit(code);
}
