import 'dart:convert';
import 'dart:io';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/ga_runner.dart';

void main() {
  group('GaRunState persistence', () {
    test('round-trips through atomic persist and load', () async {
      final dir = await Directory.systemTemp.createTemp('ga_state_');
      try {
        final config = GaConfig(
          populationSize: 2,
          gamesPerProfile: 1,
          maxGenerations: 1,
          gamePlayerCount: 2,
          maxTurns: 5,
          seedProfilesDir: 'seeds',
          gameSetupConfig: GameSetupConfig(
            selectedGreatPowerIds: const ['england', 'france'],
            minorNationCount: 0,
            tribeCount: 3,
            numProvincesOldWorld: 20,
            numProvincesNewWorld: 10,
          ),
          outputDir: 'out',
          seed: 42,
        );
        final members = <PopulationMember>[
          PopulationMember(
            slotId: 'profile-000',
            profile: seedAiProfilesById['victoria']!,
            fitnessHistory: <double>[1.5],
            generationsSurvived: 1,
          ),
          PopulationMember(
            slotId: 'profile-001',
            profile: seedAiProfilesById['napoleon']!,
          ),
        ];
        final state = GaRunState(
          runId: 'ga-run-test',
          config: config,
          currentGeneration: 0,
          population: members,
          bestOverall: const GaBestOverall(
            profileId: 'profile-000',
            fitness: 1.5,
            generation: 0,
          ),
          convergence: GaConvergence(
            bestFitnessPerGeneration: <double>[1.5],
            avgFitnessPerGeneration: <double>[0.75],
          ),
        );
        await writeProfileFiles(dir.path, members);
        await persistRunState(dir.path, state);

        final loaded = loadRunState(dir.path);
        expect(loaded.runId, 'ga-run-test');
        expect(loaded.currentGeneration, 0);
        expect(loaded.population.length, 2);
        expect(loaded.population.first.fitnessHistory, <double>[1.5]);
        expect(loaded.bestOverall.fitness, 1.5);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('rejects missing population profile file on load', () async {
      final dir = await Directory.systemTemp.createTemp('ga_state_missing_profile_');
      try {
        await File('${dir.path}/run-state.json').writeAsString(
          jsonEncode(<String, dynamic>{
            'schema_version': kGaRunStateSchemaVersion,
            'run_id': 'ga-run-missing-profile',
            'config': <String, dynamic>{
              'seed_profiles_dir': 'seeds',
              'seed': 1,
              'game_player_count': 2,
              'game_setup_config': <String, dynamic>{
                'selectedGreatPowerIds': <String>['england', 'france'],
              },
            },
            'current_generation': 0,
            'population': <Map<String, dynamic>>[
              <String, dynamic>{
                'profile_id': 'profile-000',
                'fitness_history': <double>[],
                'generations_survived': 0,
              },
            ],
            'best_overall': <String, dynamic>{
              'profile_id': 'profile-000',
              'fitness': 0.0,
              'generation': 0,
            },
            'convergence': <String, dynamic>{
              'best_fitness_per_generation': <double>[],
              'avg_fitness_per_generation': <double>[],
            },
          }),
        );
        expect(
          () => loadRunState(dir.path),
          throwsA(
            predicate<FormatException>(
              (e) => e.message.contains('missing population profile file'),
            ),
          ),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('rejects unknown schema version', () async {
      final dir = await Directory.systemTemp.createTemp('ga_state_bad_');
      try {
        await File('${dir.path}/run-state.json').writeAsString(
          jsonEncode(<String, dynamic>{
            'schema_version': 99,
            'config': <String, dynamic>{},
          }),
        );
        expect(
          () => loadRunState(dir.path),
          throwsA(isA<FormatException>()),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
