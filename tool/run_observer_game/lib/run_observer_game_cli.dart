import 'dart:io';

import 'package:args/args.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

import 'observer_colonial_verify.dart';
import 'observer_conquest_verify.dart';
import 'observer_session_runner.dart';
import 'observer_workforce_verify.dart';
import 'setup_config_parser.dart';

/// Exit code for usage / argument errors (sysexits.h EX_USAGE).
const int kExitUsage = 64;

/// Exit code when `--verify-conquest` fails (Refs #2504).
const int kExitConquestVerifyFailed = 5;

/// Exit code when `--verify-colonial-expansion` fails (Refs #2509).
const int kExitColonialVerifyFailed = 6;

/// Exit code when `--verify-workforce` fails (Refs #2692 S10).
const int kExitWorkforceVerifyFailed = 8;

String _usage(ArgParser parser) {
  final buf = StringBuffer()
    ..writeln('Usage:')
    ..writeln('  melos run run_observer_game -- [options]')
    ..writeln('')
    ..writeln(
      'Full-AI observer campaign: init default GPs, turn artifacts, run-summary.json '
      '(SPEC/program/run_observer_game-tool.md). With --verify-* flags, minimal trace '
      'mode emits only verification snapshots (no merged traces or HTML).',
    )
    ..writeln('')
    ..writeln('Options:')
    ..writeln(parser.usage);
  return buf.toString();
}

/// Resolves the most recently modified game trace directory under [outputRoot].
String? findLatestObserverGameTraceDir(String outputRoot) {
  final traceRoot = Directory('$outputRoot/observer-traces');
  if (!traceRoot.existsSync()) {
    return null;
  }
  final gameDirs = traceRoot.listSync().whereType<Directory>().toList();
  if (gameDirs.isEmpty) {
    return null;
  }
  gameDirs.sort(
    (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
  );
  return gameDirs.first.path;
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
    )
    ..addFlag(
      'verify-conquest',
      help:
          'After a successful run, verify each GP gained >=3 net Old World '
          'provinces between turn 1 and turn '
          '$kObserverConquestCanonicalTurns snapshots (requires '
          '--max-turns >= $kObserverConquestCanonicalTurns or omit cap).',
    )
    ..addFlag(
      'verify-colonial-expansion',
      help:
          'After a successful run, verify turn-$kObserverColonialCanonicalTurn '
          'snapshot: all newWorld| provinces owned by gp1–gp6 and >=70% of '
          'extractable GP resource tiles improved (requires --max-turns >= '
          '$kObserverColonialCanonicalTurn or omit cap).',
    )
    ..addFlag(
      'verify-workforce',
      help:
          'After a successful run, verify the turn-'
          '$kObserverWorkforceCanonicalTurn snapshot: each Great Power gp1–gp6 '
          'has peasants >= $kObserverWorkforceMinPeasants AND '
          'apprentices+journeymen+masters >= $kObserverWorkforceMinTrained '
          '(requires --max-turns >= $kObserverWorkforceCanonicalTurn or omit '
          'cap).',
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

  final verifyConquest = results['verify-conquest'] == true;
  final verifyColonial = results['verify-colonial-expansion'] == true;
  final verifyWorkforce = results['verify-workforce'] == true;

  if (verifyConquest &&
      maxTurnsCap != null &&
      maxTurnsCap < kObserverConquestCanonicalTurns) {
    emitStderr(
      'Error: --verify-conquest requires --max-turns >= '
      '$kObserverConquestCanonicalTurns (got $maxTurnsCap).',
    );
    return kExitUsage;
  }
  if (verifyColonial &&
      maxTurnsCap != null &&
      maxTurnsCap < kObserverColonialCanonicalTurn) {
    emitStderr(
      'Error: --verify-colonial-expansion requires --max-turns >= '
      '$kObserverColonialCanonicalTurn (got $maxTurnsCap).',
    );
    return kExitUsage;
  }
  if (verifyWorkforce &&
      maxTurnsCap != null &&
      maxTurnsCap < kObserverWorkforceCanonicalTurn) {
    emitStderr(
      'Error: --verify-workforce requires --max-turns >= '
      '$kObserverWorkforceCanonicalTurn (got $maxTurnsCap).',
    );
    return kExitUsage;
  }

  final sessionCode = await runObserverSession(
    outputRoot: outputRoot,
    setupConfig: setup,
    maxTurnsCap: maxTurnsCap,
    verifyConquest: verifyConquest,
    verifyColonialExpansion: verifyColonial,
    verifyWorkforce: verifyWorkforce,
  );
  if (sessionCode != 0) {
    return sessionCode;
  }

  if (!verifyConquest && !verifyColonial && !verifyWorkforce) {
    return 0;
  }

  final gameDir = findLatestObserverGameTraceDir(outputRoot);
  if (gameDir == null) {
    emitStderr('Error: no game trace directory under $outputRoot');
    return 2;
  }

  if (verifyConquest) {
    final failures = verifyObserverConquestFromTraceDir(
      gameDir,
      endTurn: kObserverConquestCanonicalTurns,
    );
    if (failures.isNotEmpty) {
      for (final line in failures) {
        emitStderr('conquest_verify: $line');
      }
      return kExitConquestVerifyFailed;
    }
    emitStdout(
      'Conquest verification passed (seed=${setup.seed}, '
      '$kObserverConquestCanonicalTurns turns, '
      '>=$kObserverConquestMinOwGainPerGp OW provinces per GP).',
    );
  }

  if (verifyColonial) {
    final failures = verifyObserverColonialExpansionFromTraceDir(
      gameDir,
      endTurn: kObserverColonialCanonicalTurn,
    );
    if (failures.isNotEmpty) {
      for (final line in failures) {
        emitStderr('colonial_verify: $line');
      }
      return kExitColonialVerifyFailed;
    }
    emitStdout(
      'Colonial expansion verification passed (seed=${setup.seed}, '
      'turn $kObserverColonialCanonicalTurn, all newWorld| GP-owned, '
      'extractable improvement >= '
      '${(kObserverColonialMinImprovementRatio * 100).round()}%).',
    );
  }

  if (verifyWorkforce) {
    final failures = verifyObserverWorkforceFromTraceDir(
      gameDir,
      endTurn: kObserverWorkforceCanonicalTurn,
    );
    if (failures.isNotEmpty) {
      for (final line in failures) {
        emitStderr('workforce_verify: $line');
      }
      return kExitWorkforceVerifyFailed;
    }
    emitStdout(
      'Workforce verification passed (seed=${setup.seed}, '
      'turn $kObserverWorkforceCanonicalTurn, '
      'peasants >= $kObserverWorkforceMinPeasants AND '
      'apprentices+journeymen+masters >= $kObserverWorkforceMinTrained '
      'per gp1–gp6).',
    );
  }

  return 0;
}
