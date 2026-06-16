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

    test('fills six seats from default + randomized AI when no prior winners',
        () {
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

      final subjectLeaderId = seedAiProfileLeaderIds.firstWhere(
        (leaderId) => seedAiProfilesById[leaderId]!.profileId == subject.profileId,
      );
      final expectedDefaultLeaderProfileIds = seedAiProfileLeaderIds
          .where((leaderId) => leaderId != subjectLeaderId)
          .take(config.sevenGpFallbackDefaultAiSeats)
          .map((leaderId) => seedAiProfilesById[leaderId]!.profileId)
          .toList();
      final seedProfileIds =
          seedAiProfiles.map((profile) => profile.profileId).toSet();
      final defaultLeaderIds = roster
          .map((profile) => profile.profileId)
          .where(seedProfileIds.contains)
          .toList();
      final randomizedIds = roster
          .map((profile) => profile.profileId)
          .where((id) => id.startsWith('seven-gp-rand-'))
          .toList();
      expect(defaultLeaderIds, hasLength(config.sevenGpFallbackDefaultAiSeats));
      expect(
        randomizedIds,
        hasLength(config.sevenGpFallbackRandomizedAiSeats),
      );
      expect(defaultLeaderIds, orderedEquals(expectedDefaultLeaderProfileIds));
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

  group('buildSevenGpOpponentRoster partial prior-winner fallback (Refs #3488)',
      () {
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

    // Prior winners use unique GA-evolved ids that are not seed-leader ids, so
    // the default-leader fallback fill stays distinct from the seated winners.
    List<PriorGenerationWinner> gaWinners(int n) {
      final base = seedAiProfilesById['napoleon']!;
      return <PriorGenerationWinner>[
        for (var i = 0; i < n; i++)
          PriorGenerationWinner(
            profile: AiProfile(
              schemaVersion: base.schemaVersion,
              profileId: 'ga-winner-$i',
              displayName: 'ga-winner-$i',
              parameters: base.parameters,
            ),
            fitness: 100.0 - i,
            generation: i,
          ),
      ];
    }

    for (final n in <int>[1, 3, 5]) {
      test('seats $n prior winners and fills ${6 - n} fallback seats', () {
        final winners = gaWinners(n);
        final roster = buildSevenGpOpponentRoster(
          subjectProfile: subject,
          priorWinners: winners,
          blessedProfiles: const <AiProfile>[],
          config: config,
          rng: math.Random(13),
          masterSeed: 11,
          generation: 4,
          subjectIndex: 0,
        );

        expect(roster, hasLength(6));

        final winnerIds = winners.map((w) => w.profile.profileId).toSet();
        final rosterIds = roster.map((p) => p.profileId).toList();
        // All n prior winners are seated, occupying the first n seats.
        expect(rosterIds.take(n).toSet(), winnerIds);
        // Remaining seats are fallback profiles, not prior winners.
        expect(
          rosterIds.skip(n).where(winnerIds.contains),
          isEmpty,
        );
        // Subject is never seated as an opponent.
        expect(rosterIds.contains(subject.profileId), isFalse);
        // Six distinct opponents overall.
        expect(rosterIds.toSet(), hasLength(6));
      });
    }
  });

  group('buildSevenGpOpponentRoster random selection (Refs #3488)', () {
    late GaConfig randomConfig;
    late AiProfile subject;
    late List<PriorGenerationWinner> winners;

    setUp(() {
      randomConfig = testGaConfig(
        seedProfilesDir: 'seeds',
        gameSetupConfig: testTwoPlayerSetup(),
        sevenGpGamesPerProfile: 1,
        sevenGpOpponentSelection: 'random',
      );
      subject = seedAiProfilesById['victoria']!;
      // Four distinct non-subject prior winners with descending fitness so a
      // shuffle is meaningfully distinguishable from the fitness ordering.
      final ids = seedAiProfileLeaderIds
          .where((id) => seedAiProfilesById[id]!.profileId != subject.profileId)
          .take(4)
          .toList();
      winners = <PriorGenerationWinner>[
        for (var i = 0; i < ids.length; i++)
          PriorGenerationWinner(
            profile: seedAiProfilesById[ids[i]]!,
            fitness: 100.0 - i,
            generation: i,
          ),
      ];
    });

    List<AiProfile> buildWith({required int seed, int generation = 3}) =>
        buildSevenGpOpponentRoster(
          subjectProfile: subject,
          priorWinners: winners,
          blessedProfiles: const <AiProfile>[],
          config: randomConfig,
          rng: math.Random(seed),
          masterSeed: 11,
          generation: generation,
          subjectIndex: 0,
        );

    test('is deterministic for fixed master seed, generation, and inputs', () {
      final a = buildWith(seed: 7).map((p) => p.profileId).toList();
      final b = buildWith(seed: 7).map((p) => p.profileId).toList();
      expect(a, b);
    });

    test('seats every eligible prior winner before fallback and excludes '
        'the subject', () {
      final roster = buildWith(seed: 7);
      expect(roster, hasLength(6));
      final winnerIds = winners.map((w) => w.profile.profileId).toSet();
      // Prior winners are seated first (shuffled), before blessed/default/
      // randomized fallback fill.
      expect(
        roster.take(winners.length).map((p) => p.profileId).toSet(),
        winnerIds,
      );
      expect(
        roster.map((p) => p.profileId).contains(subject.profileId),
        isFalse,
      );
    });

    test('shuffle order is not the top-fitness order for at least one '
        'generation seed (mode actually reorders)', () {
      List<String> topFitnessOrder() => (List<PriorGenerationWinner>.from(
            winners,
          )..sort((a, b) {
              final byFitness = b.fitness.compareTo(a.fitness);
              if (byFitness != 0) return byFitness;
              return a.generation.compareTo(b.generation);
            }))
          .map((w) => w.profile.profileId)
          .toList();

      final topOrder = topFitnessOrder();
      // Scan a handful of generation seeds; the deterministic shuffle must
      // differ from the strict fitness ordering for at least one of them.
      final reordered = <int>[for (var g = 0; g < 8; g++) g].any((g) {
        final order = buildWith(seed: 7, generation: g)
            .take(winners.length)
            .map((p) => p.profileId)
            .toList();
        return !_listEquals(order, topOrder);
      });
      expect(
        reordered,
        isTrue,
        reason: 'random selection must produce an order distinct from '
            'top_fitness for at least one generation seed.',
      );
    });
  });
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
