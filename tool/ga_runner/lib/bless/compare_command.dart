import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';

import '../ga_runner_cli.dart';
import '../persistence/run_state.dart';
import 'blessed_profile_manifest.dart';
import 'list_command.dart' show loadBestOverallProfileForRun;

Future<int> runCompareCommand({
  required List<String> arguments,
  required String repoRoot,
  required void Function(String line) emitStdout,
  required void Function(String line) emitStderr,
}) async {
  String? baselineDir;
  String? baselineName;
  String? candidateDir;

  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    switch (arg) {
      case '--baseline':
        if (baselineName != null) {
          emitStderr('Error: --baseline and --baseline-name are mutually exclusive');
          return kExitUsage;
        }
        baselineDir = _nextValue(arguments, ++i, emitStderr, '--baseline');
      case '--baseline-name':
        if (baselineDir != null) {
          emitStderr('Error: --baseline and --baseline-name are mutually exclusive');
          return kExitUsage;
        }
        baselineName = _nextValue(arguments, ++i, emitStderr, '--baseline-name');
      case '--candidate':
        candidateDir = _nextValue(arguments, ++i, emitStderr, '--candidate');
      case '--help':
      case '-h':
        emitStdout(_compareUsage());
        return 0;
      default:
        emitStderr('Error: unknown compare option: $arg');
        emitStdout(_compareUsage());
        return kExitUsage;
    }
  }

  if (candidateDir == null) {
    emitStderr('Error: compare requires --candidate.');
    emitStdout(_compareUsage());
    return kExitUsage;
  }
  if (baselineDir == null && baselineName == null) {
    emitStderr('Error: compare requires --baseline or --baseline-name.');
    emitStdout(_compareUsage());
    return kExitUsage;
  }

  if (!Directory(candidateDir).existsSync()) {
    emitStderr('Error: candidate run directory not found: $candidateDir');
    return kExitError;
  }

  if (baselineName != null) {
    final manifest = BlessedProfileManifest.readFile(
      blessedManifestPath(repoRoot),
    );
    final entry = manifest.entryByName(baselineName);
    if (entry == null) {
      emitStderr("Error: blessed profile '$baselineName' not in manifest");
      return kExitError;
    }
    final searchRoot = Directory(candidateDir).parent.path;
    baselineDir = resolveRunDirectoryById(searchRoot, entry.sourceRunId);
    if (baselineDir == null) {
      emitStderr(
        "Error: cannot locate run directory for source_run_id "
        "'${entry.sourceRunId}' under $searchRoot",
      );
      return kExitError;
    }
  }

  if (baselineDir == null || !Directory(baselineDir).existsSync()) {
    emitStderr('Error: baseline run directory not found: $baselineDir');
    return kExitError;
  }

  GaRunState baselineState;
  GaRunState candidateState;
  try {
    baselineState = loadRunState(baselineDir);
    candidateState = loadRunState(candidateDir);
  } on FormatException catch (e) {
    emitStderr('Error: $e');
    return kExitError;
  }

  emitStdout('=== Fitness per generation (best) ===');
  emitStdout(
    _formatFitnessCurves(
      baselineState.convergence.bestFitnessPerGeneration,
      candidateState.convergence.bestFitnessPerGeneration,
    ),
  );
  emitStdout('');
  emitStdout('=== Best-overall profiles ===');

  AiProfile baselineProfile;
  AiProfile candidateProfile;
  try {
    baselineProfile = await loadBestOverallProfileForRun(
      baselineDir,
      baselineState,
    );
    candidateProfile = await loadBestOverallProfileForRun(
      candidateDir,
      candidateState,
    );
  } on FormatException catch (e) {
    emitStderr('Error: $e');
    return kExitError;
  }

  emitStdout('baseline: ${baselineProfile.profileId} (${baselineProfile.displayName})');
  emitStdout(
    'candidate: ${candidateProfile.profileId} (${candidateProfile.displayName})',
  );
  emitStdout('');
  emitStdout('=== Parameter diff (candidate − baseline) ===');
  emitStdout(_formatParameterDiff(baselineProfile, candidateProfile));
  return 0;
}

String _formatFitnessCurves(List<double> baseline, List<double> candidate) {
  final lines = <String>['gen\tbaseline\tcandidate'];
  final maxLen = math.max(baseline.length, candidate.length);
  for (var i = 0; i < maxLen; i++) {
    final b = i < baseline.length ? baseline[i].toStringAsFixed(4) : '-';
    final c = i < candidate.length ? candidate[i].toStringAsFixed(4) : '-';
    lines.add('$i\t$b\t$c');
  }
  return lines.join('\n');
}

String _formatParameterDiff(AiProfile baseline, AiProfile candidate) {
  final keys = AiParameterRegistry.allParams.map((p) => p.name).toList()
    ..sort();
  final lines = <String>['parameter\tbaseline\tcandidate\tdelta'];
  for (final key in keys) {
    final b = baseline.parameters[key] ?? 0;
    final c = candidate.parameters[key] ?? 0;
    final delta = c - b;
    if (delta == 0) {
      continue;
    }
    lines.add('$key\t$b\t$c\t$delta');
  }
  if (lines.length == 1) {
    lines.add('(no parameter differences)');
  }
  return lines.join('\n');
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

String _compareUsage() => '''
Usage:
  melos run ga_runner -- compare --baseline <dir> --candidate <dir>
  melos run ga_runner -- compare --baseline-name <name> --candidate <dir>

Compares GA runs: fitness curves and best-overall parameter diffs.
''';
