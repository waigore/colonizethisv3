import 'dart:convert';
import 'dart:io';

import '../package_logger.dart';

final _log = packageLogger('observer');

/// Result of one observer invocation.
class ObserverRunResult {
  const ObserverRunResult({
    required this.exitCode,
    this.gameTraceDir,
  });

  final int exitCode;
  final String? gameTraceDir;
}

/// Runs `run_observer_game` via Melos from [repoRoot].
abstract class ObserverRunner {
  Future<ObserverRunResult> run({
    required String repoRoot,
    required String setupPath,
    required String profilesDir,
    required String outputDir,
    required int maxTurns,
    required int seed,
  });
}

class MelosObserverRunner implements ObserverRunner {
  const MelosObserverRunner();

  @override
  Future<ObserverRunResult> run({
    required String repoRoot,
    required String setupPath,
    required String profilesDir,
    required String outputDir,
    required int maxTurns,
    required int seed,
  }) async {
    final result = await Process.run(
      'dart',
      [
        'run',
        'melos',
        'run',
        'run_observer_game',
        '--',
        '--config',
        setupPath,
        '--profiles',
        profilesDir,
        '--max-turns',
        '$maxTurns',
        '--seed',
        '$seed',
        '--output',
        outputDir,
      ],
      workingDirectory: repoRoot,
      runInShell: false,
    );
    final exitCode = result.exitCode;
    final traceDir = findLatestObserverGameTraceDir(outputDir);
    if (exitCode != 0) {
      _log.w(
        'ga:observer_failed exit=$exitCode stderr=${result.stderr}',
      );
    }
    return ObserverRunResult(exitCode: exitCode, gameTraceDir: traceDir);
  }
}

/// Resolves the most recently modified game trace directory under [outputRoot].
String? findLatestObserverGameTraceDir(String outputRoot) {
  final traceRoot = Directory('$outputRoot/observer-traces');
  if (!traceRoot.existsSync()) return null;
  final gameDirs = traceRoot.listSync().whereType<Directory>().toList();
  if (gameDirs.isEmpty) return null;
  gameDirs.sort(
    (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
  );
  return gameDirs.first.path;
}

/// Loads the final snapshot JSON and run-summary from [gameTraceDir].
({Map<String, dynamic> snapshot, Map<String, dynamic> runSummary})?
loadFinalObserverArtifacts(String gameTraceDir) {
  final summaryFile = File('$gameTraceDir/run-summary.json');
  if (!summaryFile.existsSync()) return null;
  Map<String, dynamic> runSummary;
  try {
    runSummary =
        jsonDecode(summaryFile.readAsStringSync()) as Map<String, dynamic>;
  } on Object catch (e) {
    _log.w('ga:run_summary_parse_failed path=${summaryFile.path} error=$e');
    return null;
  }

  final snapshotFile = _latestSnapshotFile(gameTraceDir);
  if (snapshotFile == null) return null;
  try {
    final snapshot =
        jsonDecode(snapshotFile.readAsStringSync()) as Map<String, dynamic>;
    return (snapshot: snapshot, runSummary: runSummary);
  } on Object catch (e) {
    _log.w('ga:snapshot_parse_failed path=${snapshotFile.path} error=$e');
    return null;
  }
}

File? _latestSnapshotFile(String gameTraceDir) {
  final dir = Directory(gameTraceDir);
  if (!dir.existsSync()) return null;
  File? best;
  var bestTurn = -1;
  for (final entity in dir.listSync().whereType<File>()) {
    final name = entity.uri.pathSegments.last;
    final match = RegExp(r'^turn-(\d+)\.snapshot\.json$').firstMatch(name);
    if (match == null) continue;
    final turn = int.parse(match.group(1)!);
    if (turn > bestTurn) {
      bestTurn = turn;
      best = entity;
    }
  }
  return best;
}
