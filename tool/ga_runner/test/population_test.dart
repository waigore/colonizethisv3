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
  });
}
