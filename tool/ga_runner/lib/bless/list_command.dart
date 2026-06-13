import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../ga_runner_cli.dart';
import '../persistence/run_state.dart';
import 'blessed_profile_manifest.dart';

Future<int> runListCommand({
  required List<String> arguments,
  required void Function(String line) emitStdout,
  required void Function(String line) emitStderr,
}) async {
  String? runDir;
  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    switch (arg) {
      case '--run':
        runDir = _nextValue(arguments, ++i, emitStderr, '--run');
      case '--help':
      case '-h':
        emitStdout(_listUsage());
        return 0;
      default:
        emitStderr('Error: unknown list option: $arg');
        emitStdout(_listUsage());
        return kExitUsage;
    }
  }

  if (runDir == null) {
    emitStderr('Error: list requires --run.');
    emitStdout(_listUsage());
    return kExitUsage;
  }

  if (!Directory(runDir).existsSync()) {
    emitStderr('Error: run directory not found: $runDir');
    return kExitError;
  }

  GaRunState state;
  try {
    state = loadRunState(runDir);
  } on FormatException catch (e) {
    emitStderr('Error: $e');
    return kExitError;
  }

  emitStdout(
    'generation=${state.currentGeneration} population=${state.population.length}',
  );
  for (final member in state.population) {
    final lastFitness = member.fitnessHistory.isEmpty
        ? 0.0
        : member.fitnessHistory.last;
    emitStdout(
      '${member.slotId}\tfitness=$lastFitness\t'
      'survived=${member.generationsSurvived}\t'
      '${member.profile.displayName}',
    );
  }
  return 0;
}

String? _nextValue(
  List<String> args,
  int index,
  void Function(String line) emitStderr,
  String flag,
) {
  if (index >= args.length) {
    emitStderr('Error: $flag requires a value');
    return null;
  }
  return args[index];
}

String _listUsage() => '''
Usage:
  melos run ga_runner -- list --run <dir>

Lists final-generation population members with fitness and survival counts.
''';

Future<AiProfile> _loadBestOverallProfile(String runDir, GaRunState state) async {
  final bestFile = File('$runDir/best-overall-profile.json');
  if (bestFile.existsSync()) {
    final decoded = jsonDecode(bestFile.readAsStringSync());
    if (decoded is Map<String, dynamic>) {
      return AiProfile.fromJson(decoded);
    }
  }
  final slotId = state.bestOverall.profileId;
  final profileFile = File('$runDir/profiles/$slotId.json');
  if (!profileFile.existsSync()) {
    throw FormatException('missing best-overall profile in $runDir');
  }
  final decoded = jsonDecode(profileFile.readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('profile JSON must be an object');
  }
  return AiProfile.fromJson(decoded);
}

/// Exported for tests.
Future<AiProfile> loadBestOverallProfileForRun(
  String runDir,
  GaRunState state,
) =>
    _loadBestOverallProfile(runDir, state);
