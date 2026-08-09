// Case bodies: stalledGpBlockerFocus outer guards + fire path (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

import 'expand_phase_planner_gp_blocker_focus_peace_support.dart';

void registerExpandGpBlockerFocusPeaceGuardsCases() {
  group('stalledGpBlockerFocusPeaceTargets — canonical outer guards', () {
    test('returns const [] when frontier is not GP-only', () {
      // Invadable province owned by a minor →
      // isOldWorldGpOnlyInvadableFrontier is false.
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
        ],
        atWarFactionIds: const [gpBlockerFocusGpBlocker, gpBlockerFocusGpDistraction],
        minorNations: const [MinorNation(id: gpBlockerFocusMinor1, displayName: 'M1')],
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpBlocker, gpBlockerFocusGpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
        reason:
            'Mixed frontier (minor owns invadable) → GP-only guard fails; '
            'stalledFutileGpPeaceTargets owns this shape instead.',
      );
    });

    test('returns const [] when primary blocker is null', () {
      // GP-only frontier shape but no GP owns invadable provinces
      // (unowned invadable) → blocker resolution returns null.
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
            ownerId: null,
          ),
        ],
        atWarFactionIds: const [gpBlockerFocusGpDistraction],
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot),
        isEmpty,
      );
    });
  });

  group('stalledGpBlockerFocusPeaceTargets — fire path', () {
    test('peaces non-blocker GP on GP-only invadable frontier', () {
      // Mirrors colonial_pressure_test § stalledGpBlockerFocusPeaceTargets:
      // gp3 owns the sole invadable province (blocker); gp5 is at war but
      // does not own invadable land → peaced.
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
        atWarFactionIds: const [gpBlockerFocusGpBlocker, gpBlockerFocusGpDistraction],
        extraGpIds: const {gpBlockerFocusGpBlocker},
      );
      final snapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpBlocker, gpBlockerFocusGpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot),
        const [gpBlockerFocusGpDistraction],
      );
    });

    test('sole non-blocker GP war on GP-only frontier returns that GP', () {
      // gpWars.length == 1 && sole GP != blocker → return [soleGp]
      final gpOnlyGame = gpBlockerFocusGpBlockerFocusGame(
        provinces: [
          for (var i = 0; i < 7; i++)
            Province(
              id: 'oldWorld|${gpBlockerFocusGpOwn}_$i',
              regionId: 'oldWorld',
              ownerId: gpBlockerFocusGpOwn,
            ),
          for (var i = 0; i < 5; i++)
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
        atWarFactionIds: const [gpBlockerFocusGpDistraction],
        extraGpIds: const {gpBlockerFocusGpBlocker},
      );
      final gpOnlySnapshot = ownSnapshot(
        playerId: gpBlockerFocusGpOwn,
        oldWorldProvincesOwned: 7,
        atWarWith: const [gpBlockerFocusGpDistraction],
        invadableProvinceIdsSorted: const ['oldWorld|inv1'],
      );
      expect(
        stalledGpBlockerFocusPeaceTargets(
          game: gpOnlyGame,
          snapshot: gpOnlySnapshot,
        ),
        const [gpBlockerFocusGpDistraction],
        reason:
            'Sole GP war where the lone GP is not the blocker → return '
            'that GP so the planner can drop the distraction front.',
      );
    });
  });

}
