/// CLI: GA runner for AI profile optimization (thin facade).
/// SPEC/program/ga-runner.md
import 'dart:io';

import 'package:ga_runner/ga_runner_cli.dart';
import 'package:ga_runner/package_logger.dart';

final _log = packageLogger('cli');

Future<void> main(List<String> arguments) async {
  final code = await runGaRunnerCli(
    arguments,
    emitStdout: stdout.writeln,
    emitStderr: (line) {
      stderr.writeln(line);
      _log.e(line);
    },
  );
  exit(code);
}
