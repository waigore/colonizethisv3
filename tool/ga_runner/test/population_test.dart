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

    test('throws FormatException when a seed file is malformed', () async {
      final dir = await Directory.systemTemp.createTemp('ga_seeds_');
      try {
        await File(p.join(dir.path, 'bad.json')).writeAsString('{ not json');
        expect(
          () => loadSeedProfilesFromDir(dir.path),
          throwsA(isA<FormatException>()),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('throws when a seed file is not a profile object', () async {
      final dir = await Directory.systemTemp.createTemp('ga_seeds_');
      try {
        await File(p.join(dir.path, 'arr.json')).writeAsString('[1, 2, 3]');
        expect(
          () => loadSeedProfilesFromDir(dir.path),
          throwsA(isA<FormatException>()),
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('evolvePopulation (Refs #3439)', () {
    test('keeps the top two elites unchanged and grows their survival count', () {
      final current = buildInitialPopulation(
        seeds: seedAiProfiles.take(5).toList(),
        populationSize: 5,
        rng: math.Random(7),
      );
      final fitness = <double>[0.1, 0.9, 0.5, 0.2, 0.7];

      final next = evolvePopulation(
        current: current,
        generationFitness: fitness,
        rng: math.Random(7),
      );

      expect(next.length, current.length);
      // Sorted fitness desc => indices 1 (0.9) then 4 (0.7) are elites.
      expect(next[0].slotId, current[1].slotId);
      expect(next[0].profile, same(current[1].profile));
      expect(next[0].generationsSurvived, current[1].generationsSurvived + 1);
      expect(next[1].slotId, current[4].slotId);
      expect(next[1].profile, same(current[4].profile));
    });

    test('fills non-elite slots with deterministic children for a fixed seed', () {
      final current = buildInitialPopulation(
        seeds: seedAiProfiles.take(5).toList(),
        populationSize: 5,
        rng: math.Random(11),
      );
      final fitness = <double>[0.3, 0.8, 0.4, 0.9, 0.1];

      final a = evolvePopulation(
        current: current,
        generationFitness: fitness,
        rng: math.Random(99),
      );
      final b = evolvePopulation(
        current: current,
        generationFitness: fitness,
        rng: math.Random(99),
      );

      expect(a.length, 5);
      // Sorted fitness desc => indices 3 (0.9) and 1 (0.8) are elites, so they
      // retain slot ids profile-003 and profile-001. Children fill the
      // remaining slot ids in ascending order: profile-000, 002, 004.
      expect(a[0].slotId, 'profile-003');
      expect(a[1].slotId, 'profile-001');
      expect(a[2].slotId, 'profile-000');
      expect(a[3].slotId, 'profile-002');
      expect(a[4].slotId, 'profile-004');
      // Same seed => identical child parameters (determinism).
      for (var i = 0; i < a.length; i++) {
        expect(a[i].slotId, b[i].slotId);
        expect(a[i].profile.parameters, b[i].profile.parameters);
      }
    });

    test('assigns a unique slot id to every member when elites are mid-roster', () {
      final current = buildInitialPopulation(
        seeds: seedAiProfiles.take(5).toList(),
        populationSize: 5,
        rng: math.Random(11),
      );
      // Elites are the high-index members (slots profile-003 and profile-004),
      // the case where naive sequential child slot ids would collide.
      final fitness = <double>[0.1, 0.2, 0.3, 0.9, 0.8];

      final next = evolvePopulation(
        current: current,
        generationFitness: fitness,
        rng: math.Random(5),
      );

      final slotIds = next.map((m) => m.slotId).toList();
      expect(slotIds.toSet().length, next.length);
      expect(
        slotIds.toSet(),
        {'profile-000', 'profile-001', 'profile-002', 'profile-003', 'profile-004'},
      );
    });

    test('handles a single-member population without crossover deadlock', () {
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
      // Only slot is the sole elite, preserved unchanged.
      expect(next[0].slotId, current[0].slotId);
      expect(next[0].profile, same(current[0].profile));
    });
  });
}
