// True-path + determinism pins for `isStalledOldWorldGpBlockerFocus` (Refs #2509 S1 / #4669 Slice B).

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

void registerExpandPhasePlannerStalledOwGpBlockerFocusTrueCases() {
  group('isStalledOldWorldGpBlockerFocus true paths', () {
    test(
      'true when below quota and every invadable province is owned by a Great Power '
      '(canonical seed-42 gp5/gp6 trap)',
      () {
        final game = buildStalledOwGpOnlyInvadableGame(ownOwProvinces: 9);
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: 9,
            invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          isTrue,
        );
      },
    );

    test(
      'true at zero OW provinces with an all-GP invadable list (lower bound)',
      () {
        final game = buildStalledOwGpOnlyInvadableGame(ownOwProvinces: 0);
        const snapshot = AIWorldSnapshot(
          playerId: 'gp5',
          threats: ThreatSummary(atWarWith: ['gp6']),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
          ),
          colonial: ColonialSummary(),
          economy: EconomySummary(),
          relations: {},
        );
        expect(
          isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'No non-zero OW floor — only the quota ceiling matters; the '
              'GP-blocker pivot must fire from the first turn for a GP '
              'starting against a GP-only frontier.',
        );
      },
    );

    test('true just below the observer OW quota with an all-GP invadable list '
        '(quota - 1 boundary)', () {
      final game = buildStalledOwGpOnlyInvadableGame(
        ownOwProvinces: kObserverConquestMinOwProvincesPerGp - 1,
      );
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp - 1,
          invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      expect(
        isStalledOldWorldGpBlockerFocus(game: game, snapshot: snapshot),
        isTrue,
        reason:
            'One province below quota must still trip the predicate so '
            'the EXPAND planner stays in the GP-blocker pivot arm right '
            'up until the quota gate trips.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = buildStalledOwGpOnlyInvadableGame(ownOwProvinces: 9);
      const snapshot = AIWorldSnapshot(
        playerId: 'gp5',
        threats: ThreatSummary(atWarWith: ['gp6']),
        opportunities: OpportunitySummary(),
        conquest: ConquestSummary(
          oldWorldProvincesOwned: 9,
          invadableProvinceIdsSorted: ['oldWorld|gp6_frontier'],
        ),
        colonial: ColonialSummary(),
        economy: EconomySummary(),
        relations: {},
      );
      final first = isStalledOldWorldGpBlockerFocus(
        game: game,
        snapshot: snapshot,
      );
      final second = isStalledOldWorldGpBlockerFocus(
        game: game,
        snapshot: snapshot,
      );
      expect(
        first,
        second,
        reason:
            'Pure helper must return identical results on repeated calls — '
            'required by issue #2509 Must-have #7 (phase planners are pure '
            'functions with deterministic inputs).',
      );
    });
  });
}
