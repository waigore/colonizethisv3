// Case bodies: stalledStrongerGpBlockerPeaceTarget pins (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import 'expand_phase_planner_gp_blocker_focus_peace_support.dart';

void registerExpandGpBlockerFocusPeaceTargetCases() {
  group('stalledStrongerGpBlockerPeaceTarget — canonical outer guards', () {
    test('returns null above stalled OW band', () {
      final game = gpBlockerFocusGpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 12; i++)
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
        ],
        atWarFactionIds: const [gpBlockerFocusGpBlocker],
        minorNations: const [MinorNation(id: gpBlockerFocusMinor1, displayName: 'M1')],
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 12,
        atWarWith: const [gpBlockerFocusGpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
        isNull,
      );
    });

    test(
      'returns null when no OW minor remains on the map (GP-blocker focus)',
      () {
        // Mirrors diplomacy_planner_stalled_peace_test: minor exists in
        // minorNations but owns no OW province → anyMinorOwnsOw is false.
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
          atWarFactionIds: const [gpBlockerFocusGpBlocker],
          minorNations: const [MinorNation(id: gpBlockerFocusMinor1, displayName: 'M1')],
        );
        final snapshot = ownSnapshot(
          playerId: gpBlockerFocusGpOwn,
          oldWorldProvincesOwned: 7,
          atWarWith: const [gpBlockerFocusGpBlocker],
          invadableProvinceIdsSorted: const ['oldWorld|inv1'],
        );
        expect(
          stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
          isNull,
        );
      },
    );
  });

  group('stalledStrongerGpBlockerPeaceTarget — fire path', () {
    test('returns strongest non-blocker GP owning invadable OW provinces', () {
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
        atWarFactionIds: const [gpBlockerFocusGpBlocker, gpBlockerFocusGpDistraction],
        minorNations: const [MinorNation(id: gpBlockerFocusMinor1, displayName: 'M1')],
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
      expect(
        stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
        gpBlockerFocusGpDistraction,
        reason:
            'gp3 is the primary blocker; gp5 owns invadable land with '
            'lead 8-7=1 > 0 → strongest non-blocker GP is gp5.',
      );
    });

    test('returns null when sole at-war GP is the primary blocker', () {
      // Mirrors diplomacy_planner_stalled_peace_test first case: only
      // gp3 at war and gp3 is the blocker → no non-blocker candidate.
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
          const Province(
            id: 'oldWorld|inv2',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusGpBlocker,
          ),
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: gpBlockerFocusMinor1,
          ),
        ],
        atWarFactionIds: const [gpBlockerFocusGpBlocker],
        minorNations: const [MinorNation(id: gpBlockerFocusMinor1, displayName: 'M1')],
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpBlocker],
        invadableProvinceIdsSorted: const ['oldWorld|inv1', 'oldWorld|inv2'],
      );
      expect(
        stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot),
        isNull,
      );
    });
  });
}
