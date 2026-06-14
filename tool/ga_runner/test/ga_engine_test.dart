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
  const _FakeObserverRunner({
    this.exitCode = 0,
    this.onGameComplete,
  });

  final int exitCode;
  final void Function()? onGameComplete;

  @override
  Future<ObserverRunResult> run({
    required String repoRoot,
    required String setupPath,
    required String profilesDir,
    required String outputDir,
    required int maxTurns,
    required int seed,
  }) async {
    onGameComplete?.call();
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
            minorNationCount: 3,
            tribeCount: 3,
            numProvincesOldWorld: 23,
            numProvincesNewWorld: 12,
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

    test('exports best-overall profile at run completion', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_best_');
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
            minorNationCount: 3,
            tribeCount: 3,
            numProvincesOldWorld: 23,
            numProvincesNewWorld: 12,
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
        expect(await engine.runFresh(runId: 'ga-run-best'), 0);
        final state = loadRunState(runDir.path);
        final bestExport = File('${runDir.path}/best-overall-profile.json');
        expect(bestExport.existsSync(), isTrue);
        final genLabel = state.bestOverall.generation.toString().padLeft(3, '0');
        final genBest = File('${runDir.path}/gen-$genLabel/best-profile.json');
        expect(bestExport.readAsStringSync(), genBest.readAsStringSync());
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test('resume on already-complete run re-exports best-overall profile', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_best_resume_');
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
            minorNationCount: 3,
            tribeCount: 3,
            numProvincesOldWorld: 23,
            numProvincesNewWorld: 12,
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
        expect(await engine.runFresh(runId: 'ga-run-best-resume'), 0);

        final bestExport = File('${runDir.path}/best-overall-profile.json');
        final expected = bestExport.readAsStringSync();
        bestExport.deleteSync();
        expect(bestExport.existsSync(), isFalse);

        final resumeEngine = GaEngine(
          repoRoot: Directory.current.path,
          config: config,
          runDir: runDir.path,
          observerRunner: const _FakeObserverRunner(),
        );
        expect(await resumeEngine.resume(loadRunState(runDir.path)), 0);
        expect(bestExport.existsSync(), isTrue);
        expect(bestExport.readAsStringSync(), expected);
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test('resume continues from persisted generation boundary', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_resume_');
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
            minorNationCount: 3,
            tribeCount: 3,
            numProvincesOldWorld: 23,
            numProvincesNewWorld: 12,
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
        expect(await engine.runFresh(runId: 'ga-run-resume'), 0);
        final afterFirst = loadRunState(runDir.path);
        expect(afterFirst.currentGeneration, 0);

        final stateFile = File('${runDir.path}/run-state.json');
        final stateJson =
            jsonDecode(stateFile.readAsStringSync()) as Map<String, dynamic>;
        final configJson = stateJson['config'] as Map<String, dynamic>;
        configJson['max_generations'] = 2;
        await stateFile.writeAsString(jsonEncode(stateJson));

        final resumeEngine = GaEngine(
          repoRoot: Directory.current.path,
          config: GaConfig.fromJson(configJson),
          runDir: runDir.path,
          observerRunner: const _FakeObserverRunner(),
        );
        expect(await resumeEngine.resume(loadRunState(runDir.path)), 0);
        final afterSecond = loadRunState(runDir.path);
        expect(afterSecond.currentGeneration, 1);
        expect(afterSecond.convergence.bestFitnessPerGeneration.length, 2);
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test('returns 130 when stop is requested before generation starts', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_sigint_');
      try {
        final config = GaConfig(
          populationSize: 2,
          gamesPerProfile: 1,
          maxGenerations: 3,
          gamePlayerCount: 2,
          maxTurns: 3,
          seedProfilesDir: seedsDir,
          gameSetupConfig: GameSetupConfig(
            selectedGreatPowerIds: const ['england', 'france'],
            minorNationCount: 3,
            tribeCount: 3,
            numProvincesOldWorld: 23,
            numProvincesNewWorld: 12,
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
          shouldStop: () => true,
        );
        expect(await engine.runFresh(runId: 'ga-run-sigint'), 130);
        expect(File('${runDir.path}/run-state.json').existsSync(), isFalse);
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test('returns 130 mid-generation and keeps last completed generation', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_sigint_mid_');
      var gamesCompleted = 0;
      const stopAfterGames = 3;
      try {
        final config = GaConfig(
          populationSize: 2,
          gamesPerProfile: 1,
          maxGenerations: 2,
          gamePlayerCount: 2,
          maxTurns: 3,
          seedProfilesDir: seedsDir,
          gameSetupConfig: GameSetupConfig(
            selectedGreatPowerIds: const ['england', 'france'],
            minorNationCount: 3,
            tribeCount: 3,
            numProvincesOldWorld: 23,
            numProvincesNewWorld: 12,
            seed: 99,
          ),
          outputDir: runDir.parent.path,
          seed: 11,
        );
        final engine = GaEngine(
          repoRoot: Directory.current.path,
          config: config,
          runDir: runDir.path,
          observerRunner: _FakeObserverRunner(
            onGameComplete: () => gamesCompleted++,
          ),
          shouldStop: () => gamesCompleted >= stopAfterGames,
        );
        expect(await engine.runFresh(runId: 'ga-run-sigint-mid'), 130);
        final state = loadRunState(runDir.path);
        expect(state.currentGeneration, 0);
        expect(state.convergence.bestFitnessPerGeneration.length, 1);
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
            minorNationCount: 3,
            tribeCount: 3,
            numProvincesOldWorld: 23,
            numProvincesNewWorld: 12,
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
