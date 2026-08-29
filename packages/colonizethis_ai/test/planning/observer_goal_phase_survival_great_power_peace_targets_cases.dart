// Case bodies for survivalGreatPowerPeaceTargets canonical-home pins (#4669 Slice D).

import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_test/test.dart';

import '../support/expand_phase_peace_test_support.dart';

const String _gpStronger = 'gp_stronger';
const String _minor1 = 'minor1';

void registerObserverGoalPhaseSurvivalGreatPowerPeaceTargetsCases() {
  group('survivalGreatPowerPeaceTargets — canonical home', () {
    test('pristine state — every sub-decider short-circuits to empty', () {
      final game = buildSurvivalGreatPowerPeaceGame(ownProvinces: 9, ownRegimentCount: 2);
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kStalledOldWorldProvinceThreshold + 1,
        atWarWith: const [],
      );
      expect(
        survivalGreatPowerPeaceTargets(game: game, snapshot: snapshot).toList(),
        isEmpty,
        reason:
            'A pristine state with no at-war factions and no zero-'
            'regiment / critical-band shape must trigger zero peace '
            'yields. A regression that emitted before the first '
            'sub-decider short-circuit (for example a stray yield in '
            'sync*) would surface here without any sub-decider pin '
            'needing to flip first.',
      );
    });

    test('critical-survival single fire — yields only the stronger GP', () {
      final game = buildSurvivalGreatPowerPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold - 1,
        ownRegimentCount: 1,
        enemyGpId: _gpStronger,
        enemyOwProvinces: 6,
        enemyRegimentCount: 1,
        atWarFactionIds: const [_gpStronger],
      );
      expect(
        survivalGreatPowerPeaceTargets(
          game: game,
          snapshot: ownSnapshot(
            oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
            atWarWith: const [_gpStronger],
          ),
        ).toList(),
        const [_gpStronger],
        reason:
            'criticalWeakGpSurvivalPeaceTargets must be the only '
            'sub-decider that fires when both sides hold 1 regiment '
            'and ownOw is inside the defend band with a stronger GP '
            'foe. A regression that wired the wrong constant into the '
            'lead table or omitted the critical-survival yield from '
            'the aggregator would change this output.',
      );
    });

    test('zero-regiment all-faction single fire — yields only the minor', () {
      final game = buildSurvivalGreatPowerPeaceGame(
        ownProvinces: 5,
        ownRegimentCount: 0,
        minorId: _minor1,
        atWarFactionIds: const [_minor1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [_minor1],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_home'],
      );
      expect(
        survivalGreatPowerPeaceTargets(game: game, snapshot: snapshot).toList(),
        const [_minor1],
        reason:
            'stalledZeroRegimentAllFactionPeaceTargets must be the '
            'only sub-decider that fires when own is zero-regiment '
            'in the stalled band with an at-war minor on an '
            'invadable frontier and no GPs in atWarWith. A regression '
            'that dropped the zero-regiment all-faction yield from '
            'the aggregator (or swapped it for the GP arm) would '
            'change this output.',
      );
    });

    test('yield-order pin — critical-survival precedes zero-regiment '
        'all-faction', () {
      final game = buildSurvivalGreatPowerPeaceGame(
        ownProvinces: kFewOldWorldProvincesDefendThreshold - 1,
        ownRegimentCount: 0,
        enemyGpId: _gpStronger,
        enemyOwProvinces: 6,
        enemyRegimentCount: 0,
        minorId: _minor1,
        atWarFactionIds: const [_gpStronger, _minor1],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
        atWarWith: const [_gpStronger, _minor1],
        invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_home'],
      );
      final yielded = survivalGreatPowerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ).toList();
      expect(
        yielded,
        containsAll(const [_gpStronger, _minor1]),
        reason:
            'Both sub-deciders must fire on this fixture; otherwise '
            'the order pin below is vacuous. If a sub-decider stopped '
            'firing here, audit the canonical helper that owns that '
            'arm first.',
      );
      final strongerFirstIndex = yielded.indexOf(_gpStronger);
      final minorFirstIndex = yielded.indexOf(_minor1);
      expect(
        strongerFirstIndex,
        lessThan(minorFirstIndex),
        reason:
            'The aggregator must yield criticalWeakGpSurvivalPeaceTargets '
            'before stalledZeroRegimentAllFactionPeaceTargets. Reordering '
            'the yield* sequence in the canonical body would break the '
            'LinkedHashSet insertion order that '
            'collectStalledGreatPowerPeaceTargets relies on for its '
            'public peace-target set iteration order.',
      );
    });

    test(
      'Must-have #7 determinism — identical inputs yield identical lists',
      () {
        final game = buildSurvivalGreatPowerPeaceGame(
          ownProvinces: kFewOldWorldProvincesDefendThreshold - 1,
          ownRegimentCount: 0,
          enemyGpId: _gpStronger,
          enemyOwProvinces: 6,
          enemyRegimentCount: 0,
          minorId: _minor1,
          atWarFactionIds: const [_gpStronger, _minor1],
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kFewOldWorldProvincesDefendThreshold,
          atWarWith: const [_gpStronger, _minor1],
          invadableProvinceIdsSorted: const ['oldWorld|${_minor1}_home'],
        );
        final first = survivalGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList();
        final second = survivalGreatPowerPeaceTargets(
          game: game,
          snapshot: snapshot,
        ).toList();
        expect(
          first,
          equals(second),
          reason:
              'Identical inputs must yield identical materialised '
              'iterables across consecutive calls (Refs #2509 Must-have '
              '#7). The Iterable is a sync* generator so each call '
              're-drives the sub-deciders from scratch; both runs must '
              'see the same composition.',
        );
      },
    );
  });
}
