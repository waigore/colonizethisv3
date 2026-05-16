import 'package:args/args.dart';

/// Exit code for usage / argument errors (sysexits.h EX_USAGE).
const int kExitUsage = 64;

/// Package slice [S3]: CLI parsing and help only; observer loop is **S4** (#2498).
const String kNotImplementedS4 =
    'run_observer_game: full observer run (init, Full AI loop, artifacts) '
    'is not implemented in this slice; see GitHub #2498 subtask S4.';

String _usage(ArgParser parser) {
  final buf = StringBuffer()
    ..writeln('Usage:')
    ..writeln('  melos run run_observer_game -- [options]')
    ..writeln('')
    ..writeln(
      'Run an all-Great-Power Full AI campaign with merged turn traces and '
      'observer snapshots (SPEC/program/run_observer_game-tool.md).',
    )
    ..writeln('')
    ..writeln('Options:')
    ..writeln(parser.usage);
  return buf.toString();
}

/// Parses CLI arguments; writes help to [emitStdout], errors to [emitStderr].
/// Returns a process exit code.
int runObserverGameCli(
  List<String> arguments, {
  required void Function(String line) emitStdout,
  required void Function(String line) emitStderr,
}) {
  final parser = ArgParser(usageLineLength: 100)
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage and exit.')
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Artifact root; traces under <output>/observer-traces/<gameId>/',
    )
    ..addOption('seed', help: 'Optional RNG seed (init_game semantics).')
    ..addOption(
      'max-turns',
      help: 'Optional cap; default = calendar-1800 turn T for the game mapping.',
    )
    ..addOption(
      'config',
      help: 'Optional JSON GameSetupConfig path (init_game-compatible).',
    );

  late final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    emitStderr(e.message);
    return kExitUsage;
  }

  if (results['help'] == true) {
    emitStdout(_usage(parser).trimRight());
    return 0;
  }

  emitStderr(kNotImplementedS4);
  emitStderr('Use --help for usage.');
  return 2;
}
