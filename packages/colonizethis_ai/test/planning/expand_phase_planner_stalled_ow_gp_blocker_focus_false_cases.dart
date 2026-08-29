// False-path pins for `isStalledOldWorldGpBlockerFocus` (Refs #2509 S1 / #4669 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

void registerExpandPhasePlannerStalledOwGpBlockerFocusFalseCases() {
  group('isStalledOldWorldGpBlockerFocus false paths', () {
    test(
      'false when at the observer OW quota even with a GP-only invadable frontier',
      () {
        final game = buildStalledOwGpOnlyInvadableGame(
          ownOwProvinces: kObserverConquestMinOwProvincesPerGp,
        );
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
            invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'At-quota short-circuit must skip the GP-only frontier delegate '
              'so the EXPAND-only GP-blocker pivot does not leak into '
              'COLONIAL / DEVELOP play.',
        );
      },
    );

    test('false when below quota but no invadable provinces remain', () {
      final game = buildStalledOwGpOnlyInvadableGame(ownOwProvinces: 8);
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(oldWorldProvincesOwned: 8),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'Empty invadable list defeats the GP-only frontier delegate so '
            'the GP-blocker pivot does not fire on a sealed map state.',
      );
    });

    test(
      'false when an invadable province is owned by a minor nation (minor pivot)',
      () {
        final game = buildStalledOwMinorAndGpInvadableGame(ownOwProvinces: 8);
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 8,
            invadableProvinceIdsSorted: [
              'oldWorld|gp6_frontier',
              'oldWorld|minor1_p1',
            ],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          isFalse,
          reason:
              'Minor-owned invadable province must break the GP-only focus '
              'so the EXPAND planner pivots to the minor first instead of '
              'declaring on the lone GP blocker.',
        );
      },
    );

    test('false when every invadable province is owned by a tribe (no GP)', () {
      final game = buildStalledOwTribeOnlyInvadableGame(ownOwProvinces: 8);
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 8,
          invadableProvinceIdsSorted: ['oldWorld|tribe1_p1'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'Tribe-owned invadable provinces do not satisfy the GP-only '
            'frontier delegate; the helper must report false so the '
            'EXPAND planner stays out of the GP-blocker pivot arm.',
      );
    });
  });
}
