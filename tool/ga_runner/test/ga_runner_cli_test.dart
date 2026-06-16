import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner.dart';
import 'package:ga_runner/ga_runner_cli.dart';

import 'test_ga_config.dart';
import 'package:ga_runner/observer/observer_runner.dart';

/// Writes a minimal-but-valid `ga-config.json` to [path], overriding
/// `seed_profiles_dir` and `output_dir` with the supplied values.
Future<void> _writeConfig(
  String path, {
  required String seedProfilesDir,
  required String outputDir,
}) async {
  await File(path).writeAsString(
    jsonEncode(<String, dynamic>{
      'population_size': 2,
      'games_per_profile': 1,
      'max_generations': 1,
      'game_player_count': 2,
      'max_turns': 3,
      'seed_profiles_dir': seedProfilesDir,
      'game_setup_config': <String, dynamic>{
        'selectedGreatPowerIds': <String>['england', 'france'],
        'minorNationCount': 3,
        'tribeCount': 3,
        'numProvincesOldWorld': 23,
        'numProvincesNewWorld': 12,
        'seed': 1,
      },
      'output_dir': outputDir,
      'seed': 1,
    }),
  );
}

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

    test('rejects supplying both --config and --resume', () async {
      final err = <String>[];
      final code = await runGaRunnerCli(
        <String>['--config', 'ga-config.json', '--resume', 'some-dir'],
        emitStdout: (_) {},
        emitStderr: err.add,
      );
      expect(code, 64);
      expect(err.join('\n'), contains('exactly one'));
    });

    test('rejects an unknown option with usage exit code', () async {
      final err = <String>[];
      final out = <String>[];
      final code = await runGaRunnerCli(
        <String>['--bogus'],
        emitStdout: out.add,
        emitStderr: err.add,
      );
      expect(code, 64);
      expect(err.join('\n'), contains('Error:'));
      expect(out.join('\n'), contains('Usage:'));
    });

    test('--config exits 1 when the config file is missing', () async {
      final err = <String>[];
      final code = await runGaRunnerCli(
        <String>['--config', 'definitely-not-here.json'],
        emitStdout: (_) {},
        emitStderr: err.add,
      );
      expect(code, 1);
      expect(err.join('\n'), contains('config file not found'));
    });

    test('--config exits 1 when the config JSON is malformed', () async {
      final dir = await Directory.systemTemp.createTemp('ga_config_bad_json_');
      try {
        final configPath = '${dir.path}/ga-config.json';
        await File(configPath).writeAsString('{ not json');
        final err = <String>[];
        final code = await runGaRunnerCli(
          <String>['--config', configPath],
          emitStdout: (_) {},
          emitStderr: err.add,
        );
        expect(code, 1);
        expect(err.join('\n'), contains('invalid ga-config.json'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('--config exits 1 when seed_profiles_dir is missing', () async {
      final dir = await Directory.systemTemp.createTemp('ga_config_seed_missing_');
      try {
        final configPath = '${dir.path}/ga-config.json';
        await _writeConfig(
          configPath,
          seedProfilesDir: '${dir.path}/no-such-seeds',
          outputDir: '${dir.path}/out',
        );
        final err = <String>[];
        final code = await runGaRunnerCli(
          <String>['--config', configPath],
          emitStdout: (_) {},
          emitStderr: err.add,
          observerRunner: const _NoOpObserverRunner(),
        );
        expect(code, 1);
        expect(err.join('\n'), contains('seed_profiles_dir not found'));
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('--config exits 1 when seed_profiles_dir is empty', () async {
      final dir = await Directory.systemTemp.createTemp('ga_config_seed_empty_');
      try {
        final seedsDir = Directory('${dir.path}/seeds')..createSync();
        final configPath = '${dir.path}/ga-config.json';
        await _writeConfig(
          configPath,
          seedProfilesDir: seedsDir.path,
          outputDir: '${dir.path}/out',
        );
        final err = <String>[];
        final code = await runGaRunnerCli(
          <String>['--config', configPath],
          emitStdout: (_) {},
          emitStderr: err.add,
          observerRunner: const _NoOpObserverRunner(),
        );
        expect(code, 1);
        expect(err.join('\n'), contains('seed_profiles_dir is empty'));
      } finally {
        await dir.delete(recursive: true);
      }
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
        final config = testGaConfig(
          populationSize: 1,
          gamesPerProfile: 1,
          maxGenerations: 1,
          maxTurns: 3,
          seedProfilesDir: 'seeds',
          gameSetupConfig: testTwoPlayerSetup(seed: 1),
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
