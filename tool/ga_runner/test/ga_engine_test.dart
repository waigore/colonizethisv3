import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import 'package:ga_runner/ga_runner.dart';
import 'package:ga_runner/observer/observer_runner.dart';

Map<String, dynamic> _minimalSnapshot() => <String, dynamic>{
  'players': <Map<String, dynamic>>[
    <String, dynamic>{
      'playerId': 'gp1',
      'treasuryPounds': 100,
      'workerPool': <String, dynamic>{
        'peasants': 10,
        'apprentices': 0,
        'journeymen': 0,
        'masters': 0,
      },
      'regimentLikeUnitCountHint': 5,
    },
    <String, dynamic>{
      'playerId': 'gp2',
      'treasuryPounds': 50,
      'workerPool': <String, dynamic>{
        'peasants': 5,
        'apprentices': 0,
        'journeymen': 0,
        'masters': 0,
      },
      'regimentLikeUnitCountHint': 2,
    },
  ],
  'provinceOwnershipSorted': <Map<String, String?>>[
    <String, String?>{'id': 'oldWorld|p1', 'ownerId': 'gp1'},
    <String, String?>{'id': 'oldWorld|p2', 'ownerId': 'gp2'},
  ],
  'diplomacyRelationSummariesSorted': <String>[],
  'militaryArmySummariesSorted': <String>[
    'army:a1 owner=gp1 region=oldWorld regiments=5',
    'army:a2 owner=gp2 region=oldWorld regiments=2',
  ],
};

class _FakeObserverRunner implements ObserverRunner {
  const _FakeObserverRunner({this.exitCode = 0});

  final int exitCode;

  @override
  Future<ObserverRunResult> run({
    required String repoRoot,
    required String setupPath,
    required String profilesDir,
    required String outputDir,
    required int maxTurns,
    required int seed,
  }) async {
    if (exitCode != 0) {
      return ObserverRunResult(exitCode: exitCode);
    }
    final gameId = 'game-$seed';
    final traceDir = '$outputDir/observer-traces/$gameId';
    await Directory(traceDir).create(recursive: true);
    await File('$traceDir/turn-000001.snapshot.json').writeAsString(
      jsonEncode(_minimalSnapshot()),
    );
    await File('$traceDir/run-summary.json').writeAsString(
      jsonEncode(<String, dynamic>{
        'declared_winner_player_id': 'gp1',
        'termination_reason': 'military_victory',
      }),
    );
    return ObserverRunResult(exitCode: 0, gameTraceDir: traceDir);
  }
}

Future<String> _seedDir() async {
  final dir = await Directory.systemTemp.createTemp('ga_seed_dir_');
  for (final profile in seedAiProfiles.take(2)) {
    await File(p.join(dir.path, '${profile.profileId}.json')).writeAsString(
      jsonEncode(profile.toJson()),
    );
  }
  return dir.path;
}

void main() {
  group('GaEngine integration', () {
    test('runs one generation and persists state', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_');
      try {
        final config = GaConfig(
          populationSize: 2,
          gamesPerProfile: 1,
          maxGenerations: 1,
          gamePlayerCount: 2,
          maxTurns: 3,
          seedProfilesDir: seedsDir,
          gameSetupConfig: GameSetupConfig(
            selectedGreatPowerIds: const ['england', 'france'],
            minorNationCount: 0,
            tribeCount: 2,
            numProvincesOldWorld: 20,
            numProvincesNewWorld: 8,
            seed: 99,
          ),
          outputDir: runDir.parent.path,
          seed: 11,
        );
        final engine = GaEngine(
          repoRoot: Directory.current.path,
          config: config,
          runDir: runDir.path,
          observerRunner: const _FakeObserverRunner(),
        );
        final code = await engine.runFresh(runId: 'ga-run-test');
        expect(code, 0);
        final state = loadRunState(runDir.path);
        expect(state.currentGeneration, 0);
        expect(state.population.length, 2);
        expect(File('${runDir.path}/gen-000/fitness.json').existsSync(), isTrue);
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test('assigns fitness 0 when all games fail', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_fail_');
      try {
        final config = GaConfig(
          populationSize: 2,
          gamesPerProfile: 1,
          maxGenerations: 1,
          gamePlayerCount: 2,
          maxTurns: 3,
          seedProfilesDir: seedsDir,
          gameSetupConfig: GameSetupConfig(
            selectedGreatPowerIds: const ['england', 'france'],
            minorNationCount: 0,
            tribeCount: 2,
            numProvincesOldWorld: 20,
            numProvincesNewWorld: 8,
            seed: 99,
          ),
          outputDir: runDir.parent.path,
          seed: 11,
        );
        final engine = GaEngine(
          repoRoot: Directory.current.path,
          config: config,
          runDir: runDir.path,
          observerRunner: const _FakeObserverRunner(exitCode: 2),
        );
        await engine.runFresh(runId: 'ga-run-fail');
        final state = loadRunState(runDir.path);
        expect(state.population.every((m) => m.fitnessHistory.single == 0.0), isTrue);
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });
  });
}
