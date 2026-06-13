import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:path/path.dart' as p;

import 'package:ga_runner/ga_runner.dart';

void main() {
  group('buildInitialPopulation', () {
    test('uses up to seven seeds then mutated variants', () {
      final seeds = seedAiProfiles.take(3).toList();
      final population = buildInitialPopulation(
        seeds: seeds,
        populationSize: 5,
        rng: math.Random(1),
      );
      expect(population.length, 5);
      expect(population[0].slotId, 'profile-000');
      expect(population[4].slotId, 'profile-004');
    });
  });

  group('loadSeedProfilesFromDir', () {
    test('throws when directory missing or empty', () async {
      final dir = await Directory.systemTemp.createTemp('ga_seeds_');
      try {
        expect(
          () => loadSeedProfilesFromDir('${dir.path}/missing'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => loadSeedProfilesFromDir(dir.path),
          throwsA(isA<FormatException>()),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('loads sorted json seeds', () async {
      final dir = await Directory.systemTemp.createTemp('ga_seeds_');
      try {
        for (final id in ['b', 'a']) {
          final profile = seedAiProfilesById[id == 'a' ? 'victoria' : 'napoleon']!;
          await File(p.join(dir.path, '$id.json')).writeAsString(
            jsonEncode(profile.toJson()),
          );
        }
        final loaded = loadSeedProfilesFromDir(dir.path);
        expect(loaded.length, 2);
        expect(loaded.first.profileId, isNotEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('throws when a seed file is not valid profile JSON', () async {
      final dir = await Directory.systemTemp.createTemp('ga_seeds_');
      try {
        await File(p.join(dir.path, 'broken.json')).writeAsString('[]');
        expect(
          () => loadSeedProfilesFromDir(dir.path),
          throwsA(isA<FormatException>()),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('evolvePopulation', () {
    test('carries elites forward and fills the rest via selection', () {
      final current = buildInitialPopulation(
        seeds: seedAiProfiles.take(3).toList(),
        populationSize: 6,
        rng: math.Random(7),
      );
      final fitness = <double>[0.1, 0.9, 0.5, 0.3, 0.8, 0.2];

      final next = evolvePopulation(
        current: current,
        generationFitness: fitness,
        rng: math.Random(7),
      );

      expect(next.length, current.length);
      // Top two fitness members (indices 1 and 4) are preserved as elites.
      final eliteProfiles = next
          .take(kEliteCount)
          .map((m) => m.profile.profileId)
          .toSet();
      expect(eliteProfiles, contains(current[1].profile.profileId));
      expect(eliteProfiles, contains(current[4].profile.profileId));
      expect(next.first.generationsSurvived, 1);
    });

    test('handles single-member population without crossover deadlock', () {
      final current = buildInitialPopulation(
        seeds: seedAiProfiles.take(1).toList(),
        populationSize: 1,
        rng: math.Random(3),
      );

      final next = evolvePopulation(
        current: current,
        generationFitness: <double>[0.5],
        rng: math.Random(3),
      );

      expect(next.length, 1);
    });
  });
}
