import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'package:ga_runner/config/ga_config.dart';
import 'package:ga_runner/setup/seven_gp_opponent_roster.dart';

import 'test_ga_config.dart';

void main() {
  group('buildSevenGpOpponentRoster', () {
    late GaConfig config;
    late AiProfile subject;

    setUp(() {
      config = testGaConfig(
        seedProfilesDir: 'seeds',
        gameSetupConfig: testTwoPlayerSetup(),
        sevenGpGamesPerProfile: 1,
      );
      subject = seedAiProfilesById['victoria']!;
    });

    test('fills six seats from default + randomized AI when no prior winners', () {
      final roster = buildSevenGpOpponentRoster(
        subjectProfile: subject,
        priorWinners: const <PriorGenerationWinner>[],
        blessedProfiles: const <AiProfile>[],
        config: config,
        rng: math.Random(42),
        masterSeed: 11,
        generation: 0,
        subjectIndex: 0,
      );
      expect(roster, hasLength(6));
      expect(
        roster.map((p) => p.profileId).contains(subject.profileId),
        isFalse,
      );
    });

    test('excludes subject profile from opponents', () {
      final roster = buildSevenGpOpponentRoster(
        subjectProfile: subject,
        priorWinners: const <PriorGenerationWinner>[],
        blessedProfiles: const <AiProfile>[],
        config: config,
        rng: math.Random(1),
        masterSeed: 11,
        generation: 0,
        subjectIndex: 0,
      );
      for (final opponent in roster) {
        expect(opponent.profileId, isNot(subject.profileId));
      }
    });

    test('prefers top-fitness prior winners before fallback fill', () {
      final low = PriorGenerationWinner(
        profile: seedAiProfilesById['napoleon']!,
        fitness: 10,
        generation: 0,
      );
      final high = PriorGenerationWinner(
        profile: seedAiProfilesById['isabella']!,
        fitness: 90,
        generation: 1,
      );
      final roster = buildSevenGpOpponentRoster(
        subjectProfile: subject,
        priorWinners: <PriorGenerationWinner>[low, high],
        blessedProfiles: const <AiProfile>[],
        config: config,
        rng: math.Random(99),
        masterSeed: 11,
        generation: 2,
        subjectIndex: 0,
      );
      expect(roster.first.profileId, high.profile.profileId);
      expect(roster.any((p) => p.profileId == low.profile.profileId), isTrue);
    });

    test('deterministic for fixed seed and inputs', () {
      List<AiProfile> run(int seed) => buildSevenGpOpponentRoster(
            subjectProfile: subject,
            priorWinners: const <PriorGenerationWinner>[],
            blessedProfiles: const <AiProfile>[],
            config: config,
            rng: math.Random(seed),
            masterSeed: 11,
            generation: 0,
            subjectIndex: 0,
          );

      final a = run(7).map((p) => p.profileId).toList();
      final b = run(7).map((p) => p.profileId).toList();
      expect(a, b);
    });
  });
}
