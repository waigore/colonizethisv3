import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner.dart';
import 'package:ga_runner/ga_runner_cli.dart';
import 'package:ga_runner/observer/observer_runner.dart';

void main() {
  group('ga_runner CLI', () {
    test('--help prints usage', () async {
      final out = <String>[];
      final code = await runGaRunnerCli(
        <String>['--help'],
        emitStdout: out.add,
        emitStderr: (_) {},
      );
      expect(code, 0);
      expect(out.join('\n'), contains('melos run ga_runner'));
      expect(out.join('\n'), contains('--config'));
      expect(out.join('\n'), contains('--resume'));
    });

    test('requires exactly one of --config or --resume', () async {
      final err = <String>[];
      final code = await runGaRunnerCli(
        <String>[],
        emitStdout: (_) {},
        emitStderr: err.add,
      );
      expect(code, 64);
      expect(err.join('\n'), contains('exactly one'));
    });

    test('--resume exits 1 when run-state.json is missing', () async {
      final dir = await Directory.systemTemp.createTemp('ga_resume_missing_');
      try {
        final err = <String>[];
        final code = await runGaRunnerCli(
          <String>['--resume', dir.path],
          emitStdout: (_) {},
          emitStderr: err.add,
        );
        expect(code, 1);
        expect(err.join('\n'), contains('no resumable run state'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('--resume exits 1 when run-state.json is malformed', () async {
      final dir = await Directory.systemTemp.createTemp('ga_resume_bad_json_');
      try {
        await File('${dir.path}/run-state.json').writeAsString('{ not json');
        final err = <String>[];
        final code = await runGaRunnerCli(
          <String>['--resume', dir.path],
          emitStdout: (_) {},
          emitStderr: err.add,
        );
        expect(code, 1);
        expect(err.join('\n'), contains('failed to parse run-state.json'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('--resume exits 0 when run already completed all generations', () async {
      final dir = await Directory.systemTemp.createTemp('ga_resume_done_');
      try {
        final config = GaConfig(
          populationSize: 1,
          gamesPerProfile: 1,
          maxGenerations: 1,
          gamePlayerCount: 2,
          maxTurns: 3,
          seedProfilesDir: 'seeds',
          gameSetupConfig: GameSetupConfig(
            selectedGreatPowerIds: const ['england', 'france'],
            minorNationCount: 0,
            tribeCount: 2,
            numProvincesOldWorld: 20,
            numProvincesNewWorld: 8,
            seed: 1,
          ),
          outputDir: 'out',
          seed: 1,
        );
        final members = <PopulationMember>[
          PopulationMember(
            slotId: 'profile-000',
            profile: seedAiProfilesById['victoria']!,
          ),
        ];
        await writeProfileFiles(dir.path, members);
        await persistRunState(
          dir.path,
          GaRunState(
            runId: 'ga-run-done',
            config: config,
            currentGeneration: 0,
            population: members,
            bestOverall: const GaBestOverall(
              profileId: 'profile-000',
              fitness: 1.0,
              generation: 0,
            ),
            convergence: GaConvergence(
              bestFitnessPerGeneration: <double>[1.0],
              avgFitnessPerGeneration: <double>[1.0],
            ),
          ),
        );

        final code = await runGaRunnerCli(
          <String>['--resume', dir.path],
          emitStdout: (_) {},
          emitStderr: (_) {},
          observerRunner: const _NoOpObserverRunner(),
        );
        expect(code, 0);
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}

class _NoOpObserverRunner implements ObserverRunner {
  const _NoOpObserverRunner();

  @override
  Future<ObserverRunResult> run({
    required String repoRoot,
    required String setupPath,
    required String profilesDir,
    required String outputDir,
    required int maxTurns,
    required int seed,
  }) async {
    return const ObserverRunResult(exitCode: 0);
  }
}
