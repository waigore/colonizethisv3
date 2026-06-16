import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import 'package:ga_runner/ga_runner.dart';
import 'package:ga_runner/observer/observer_runner.dart';

import 'test_ga_config.dart';

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

Map<String, dynamic> _readGpProfileJson(String roundDir, String slot) {
  final file = File(p.join(roundDir, 'profiles', '$slot.json'));
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

Map<String, dynamic> _completedRunSnapshot(String runDir) {
  final state = loadRunState(runDir);
  final genDir = Directory(p.join(runDir, 'gen-000'));
  final roundDirs = genDir
      .listSync()
      .map((entry) => p.basename(entry.path))
      .toList()
    ..sort();
  final sevenGpRosters = <String, List<String>>{};
  for (final entry in genDir.listSync()) {
    final roundName = p.basename(entry.path);
    if (!roundName.contains('-7gp-')) {
      continue;
    }
    final rosterIds = <String>[];
    for (var seat = 1; seat <= 7; seat++) {
      final profileFile =
          File(p.join(entry.path, 'profiles', 'gp$seat.json'));
      if (!profileFile.existsSync()) {
        continue;
      }
      final decoded =
          jsonDecode(profileFile.readAsStringSync()) as Map<String, dynamic>;
      rosterIds.add(decoded['profile_id'] as String);
    }
    sevenGpRosters[roundName] = rosterIds;
  }
  return <String, dynamic>{
    'fitnessBySlot': <String, List<double>>{
      for (final member in state.population)
        member.slotId: List<double>.from(member.fitnessHistory),
    },
    'roundDirs': roundDirs,
    'sevenGpRosters': sevenGpRosters,
  };
}

void main() {
  group('GaEngine integration', () {
    test('runs one generation and persists state', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_');
      try {
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
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
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
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
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
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
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
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
        final config = testGaConfig(
          maxGenerations: 3,
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
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
        final config = testGaConfig(
          maxGenerations: 2,
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
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

    test(
      'does not persist evaluation_checkpoint when interrupted during 2-player '
      'stage with 7-GP enabled (#3488)',
      () async {
        final seedsDir = await _seedDir();
        final runDir =
            await Directory.systemTemp.createTemp('ga_run_sigint_2p_7gp_');
        var gamesCompleted = 0;
        // Gen 0: 2 two-player + 2 seven-GP games; gen 1: stop on first 2-player.
        const stopAfterGames = 5;
        try {
          final config = testGaConfig(
            maxGenerations: 2,
            seedProfilesDir: seedsDir,
            gameSetupConfig: testTwoPlayerSetup(),
            outputDir: runDir.parent.path,
            sevenGpGamesPerProfile: 1,
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
          expect(await engine.runFresh(runId: 'ga-run-sigint-2p-7gp'), 130);
          final interrupted = loadRunState(runDir.path);
          expect(interrupted.currentGeneration, 0);
          expect(interrupted.evaluationCheckpoint, isNull);
          expect(interrupted.convergence.bestFitnessPerGeneration.length, 1);
        } finally {
          await Directory(seedsDir).delete(recursive: true);
          await runDir.delete(recursive: true);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('uses subject 2-player AiProfile as gp1 in 7-GP artifacts (#3488)',
        () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_7gp_gp1_');
      try {
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
          sevenGpGamesPerProfile: 1,
        );
        final engine = GaEngine(
          repoRoot: Directory.current.path,
          config: config,
          runDir: runDir.path,
          observerRunner: const _FakeObserverRunner(),
        );
        expect(await engine.runFresh(runId: 'ga-run-7gp-gp1'), 0);

        final genDir = Directory(p.join(runDir.path, 'gen-000'));
        for (final entry in genDir.listSync()) {
          final roundName = p.basename(entry.path);
          if (!roundName.contains('-7gp-')) {
            continue;
          }
          final slotId = roundName.split('-7gp-').first;
          final twoPlayerRound = genDir
              .listSync()
              .map((e) => p.basename(e.path))
              .where(
                (name) =>
                    name.startsWith('$slotId-g') && !name.contains('-7gp-'),
              )
              .first;
          final twoPlayerDir = p.join(genDir.path, twoPlayerRound);
          expect(
            _readGpProfileJson(entry.path, 'gp1'),
            _readGpProfileJson(twoPlayerDir, 'gp1'),
          );
        }
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test('schedules 7-GP stage after successful 2-player stage', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_7gp_');
      var gamesCompleted = 0;
      try {
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
          sevenGpGamesPerProfile: 1,
        );
        final engine = GaEngine(
          repoRoot: Directory.current.path,
          config: config,
          runDir: runDir.path,
          observerRunner: _FakeObserverRunner(
            onGameComplete: () => gamesCompleted++,
          ),
        );
        expect(await engine.runFresh(runId: 'ga-run-7gp'), 0);
        expect(gamesCompleted, 4);
        expect(
          Directory('${runDir.path}/gen-000')
              .listSync()
              .where((e) => e.path.contains('-7gp-')),
          hasLength(2),
        );
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test('resumes 7-GP stage from checkpoint without replaying 2-player games',
        () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_7gp_resume_');
      var gamesCompleted = 0;
      const stopAfterGames = 3;
      try {
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
          sevenGpGamesPerProfile: 1,
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
        expect(await engine.runFresh(runId: 'ga-run-7gp-resume'), 130);
        final interrupted = loadRunState(runDir.path);
        expect(interrupted.evaluationCheckpoint, isNotNull);
        expect(interrupted.evaluationCheckpoint!.generation, 0);
        expect(interrupted.currentGeneration, -1);
        expect(
          Directory('${runDir.path}/gen-000')
              .listSync()
              .where((e) => e.path.contains('-7gp-')),
          hasLength(1),
        );

        gamesCompleted = 0;
        final resumeEngine = GaEngine(
          repoRoot: Directory.current.path,
          config: config,
          runDir: runDir.path,
          observerRunner: _FakeObserverRunner(
            onGameComplete: () => gamesCompleted++,
          ),
        );
        expect(await resumeEngine.resume(interrupted), 0);
        expect(gamesCompleted, 1);
        expect(
          Directory('${runDir.path}/gen-000')
              .listSync()
              .where((e) => e.path.contains('-7gp-')),
          hasLength(2),
        );
        final completed = loadRunState(runDir.path);
        expect(completed.evaluationCheckpoint, isNull);
        expect(completed.currentGeneration, 0);
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test(
      'deterministic stage scheduling and fitness for fixed config and seed '
      '(#3488)',
      () async {
        final seedsDir = await _seedDir();
        final parentDir = await Directory.systemTemp.createTemp('ga_run_det_');
        final runDirA = Directory(p.join(parentDir.path, 'run-a'));
        final runDirB = Directory(p.join(parentDir.path, 'run-b'));
        try {
          final config = testGaConfig(
            seedProfilesDir: seedsDir,
            gameSetupConfig: testTwoPlayerSetup(),
            outputDir: parentDir.path,
            sevenGpGamesPerProfile: 1,
            seed: 4242,
          );
          final engineA = GaEngine(
            repoRoot: Directory.current.path,
            config: config,
            runDir: runDirA.path,
            observerRunner: const _FakeObserverRunner(),
          );
          final engineB = GaEngine(
            repoRoot: Directory.current.path,
            config: config,
            runDir: runDirB.path,
            observerRunner: const _FakeObserverRunner(),
          );
          expect(await engineA.runFresh(runId: 'ga-run-det-a'), 0);
          expect(await engineB.runFresh(runId: 'ga-run-det-b'), 0);
          expect(
            _completedRunSnapshot(runDirA.path),
            _completedRunSnapshot(runDirB.path),
          );
        } finally {
          await Directory(seedsDir).delete(recursive: true);
          await parentDir.delete(recursive: true);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test('skips 7-GP stage when all 2-player games fail', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_7gp_skip_');
      var gamesCompleted = 0;
      try {
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
          sevenGpGamesPerProfile: 1,
        );
        final engine = GaEngine(
          repoRoot: Directory.current.path,
          config: config,
          runDir: runDir.path,
          observerRunner: _FakeObserverRunner(
            exitCode: 2,
            onGameComplete: () => gamesCompleted++,
          ),
        );
        await engine.runFresh(runId: 'ga-run-7gp-skip');
        expect(gamesCompleted, 2);
        expect(
          Directory('${runDir.path}/gen-000')
              .listSync()
              .where((e) => e.path.contains('-7gp-')),
          isEmpty,
        );
      } finally {
        await Directory(seedsDir).delete(recursive: true);
        await runDir.delete(recursive: true);
      }
    });

    test('assigns fitness 0 when all games fail', () async {
      final seedsDir = await _seedDir();
      final runDir = await Directory.systemTemp.createTemp('ga_run_fail_');
      try {
        final config = testGaConfig(
          seedProfilesDir: seedsDir,
          gameSetupConfig: testTwoPlayerSetup(),
          outputDir: runDir.parent.path,
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
