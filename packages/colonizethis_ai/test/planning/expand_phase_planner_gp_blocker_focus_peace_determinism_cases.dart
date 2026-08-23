// Case bodies: determinism + stub delegation parity (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import 'expand_phase_planner_gp_blocker_focus_peace_support.dart';

void registerExpandGpBlockerFocusPeaceDeterminismCases() {
  group('Determinism (Must-have #7)', () {
    test('stalledGpBlockerFocusPeaceTargets is identical on repeat', () {
      final game = gpBlockerFocusGpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpBlocker,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusGpBlocker,
          ),
        ],
        atWarFactionIds: const [
          gpBlockerFocusGpBlocker,
          gpBlockerFocusGpDistraction,
        ],
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpBlocker, gpBlockerFocusGpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      final first = stalledGpBlockerFocusPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledGpBlockerFocusPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      expect(first, equals(second));
      expect(first, const [gpBlockerFocusGpDistraction]);
    });

    test('stalledStrongerGpBlockerPeaceTarget is identical on repeat', () {
      final game = gpBlockerFocusGpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpBlocker,
            ),
          for (var i = 0; i < 8; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpDistraction}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpDistraction,
            ),
          const Province(
            id: 'oldWorld|inv_blocker',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusGpBlocker,
          ),
          const Province(
            id: 'oldWorld|inv_distraction',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusGpDistraction,
          ),
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusMinor1,
          ),
        ],
        atWarFactionIds: const [
          gpBlockerFocusGpBlocker,
          gpBlockerFocusGpDistraction,
        ],
        minorNations: const [
          MinorNation(id: gpBlockerFocusMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpBlocker, gpBlockerFocusGpDistraction],
        invadableProvinceIdsSorted: const [
          'oldWorld|inv_blocker',
          'oldWorld|inv_distraction',
        ],
      );
      final first = stalledStrongerGpBlockerPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledStrongerGpBlockerPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      expect(first, equals(second));
      expect(first, gpBlockerFocusGpDistraction);
    });
  });

  group('Stub delegation parity', () {
    test('stalledGpBlockerFocusPeaceTargets stub mirrors canonical', () {
      final game = gpBlockerFocusGpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpOwn,
            ),
          for (var i = 0; i < 10; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpBlocker}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpBlocker,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusGpBlocker,
          ),
        ],
        atWarFactionIds: const [
          gpBlockerFocusGpBlocker,
          gpBlockerFocusGpDistraction,
        ],
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpBlocker, gpBlockerFocusGpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      final canonical = stalledGpBlockerFocusPeaceTargets(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot);
      expect(stub, equals(canonical));
    });

    test('stalledStrongerGpBlockerPeaceTarget stub mirrors canonical', () {
      final game = gpBlockerFocusGpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpOwn,
            ),
          const Province(
            id: 'oldWorld|inv1',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusMinor1,
          ),
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusMinor1,
          ),
        ],
        atWarFactionIds: const [gpBlockerFocusGpBlocker],
        minorNations: const [
          MinorNation(id: gpBlockerFocusMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      final canonical = stalledStrongerGpBlockerPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot);
      expect(stub, equals(canonical));
    });
  });
}
