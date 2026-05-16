import 'dart:io';

import 'package:args/args.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'observer_session_runner.dart';
import 'setup_config_parser.dart';

/// Exit code for usage / argument errors (sysexits.h EX_USAGE).
const int kExitUsage = 64;

String _usage(ArgParser parser) {
  final buf = StringBuffer()
    ..writeln('Usage:')
    ..writeln('  melos run run_observer_game -- [options]')
    ..writeln('')
    ..writeln(
      'Full-AI observer campaign: init default GPs, merged turn traces every turn, '
      'HTML + JSON ObserverSnapshot per turn, run-summary.json '
      '(SPEC/program/run_observer_game-tool.md). Traces are not pruned.',
    )
    ..writeln('')
    ..writeln('Options:')
    ..writeln(parser.usage);
  return buf.toString();
}

/// Parses CLI arguments; writes help to [emitStdout], errors to [emitStderr].
/// Returns a process exit code.
Future<int> runObserverGameCli(
  List<String> arguments, {
  required void Function(String line) emitStdout,
  required void Function(String line) emitStderr,
}) async {
  final parser = ArgParser(usageLineLength: 100)
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print usage and exit.',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Artifact root; traces under <output>/observer-traces/<gameId>/',
    )
    ..addOption('seed', help: 'Optional RNG seed (init_game semantics).')
    ..addOption(
      'max-turns',
      help:
          'Cap full turns resolved. Omit to stop at military victory or when the '
          'campaign reaches the calendar year-1800 boundary for the game mapping '
          '(TurnTimeMapping.gdd01 => turn 201). Pass a lower value for short runs.',
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

  final outputRaw = results['output'] as String?;
  if (outputRaw == null || outputRaw.trim().isEmpty) {
    emitStderr('Error: --output is required.');
    emitStderr('Use --help for usage.');
    return kExitUsage;
  }

  final outputRoot = Directory(outputRaw).absolute.path;

  int? seedParsed;
  final seedStr = results['seed'] as String?;
  if (seedStr != null && seedStr.trim().isNotEmpty) {
    seedParsed = int.tryParse(seedStr.trim());
    if (seedParsed == null) {
      emitStderr('Error: --seed must be an integer.');
      return kExitUsage;
    }
  }

  int? maxTurnsCap;
  final maxTurnsStr = results['max-turns'] as String?;
  if (maxTurnsStr != null && maxTurnsStr.trim().isNotEmpty) {
    maxTurnsCap = int.tryParse(maxTurnsStr.trim());
    if (maxTurnsCap == null || maxTurnsCap < 0) {
      emitStderr('Error: --max-turns must be a non-negative integer.');
      return kExitUsage;
    }
  }

  final configPathRaw = results['config'] as String?;
  final configPath = configPathRaw == null || configPathRaw.isEmpty
      ? null
      : configPathRaw;

  GameSetupConfig setup;
  try {
    setup = gameSetupFromObserverCli(
      configJsonPath: configPath,
      seedOverride: seedParsed,
    );
  } on FileSystemException catch (e) {
    emitStderr('Error: ${e.message} (${e.path})');
    return kExitUsage;
  } on Object catch (e) {
    emitStderr('Error: failed to load config: $e');
    return kExitUsage;
  }

  try {
    await Directory(outputRoot).create(recursive: true);
  } on Object catch (e) {
    emitStderr('Error: cannot create output root: $e');
    return 2;
  }

  return runObserverSession(
    outputRoot: outputRoot,
    setupConfig: setup,
    maxTurnsCap: maxTurnsCap,
  );
}
