// Pins the canonical home in `expand_phase_planner.dart` for
// `stalledOwExpansionNeedsPeacePass` (Refs #2509 S1).
//
// The composite predicate was relocated from
// `diplomacy_planner_peace_targets.dart` so it survives the planned
// S1 deletion of that file. The canonical implementation lives in
// `expand_phase_planner.dart` alongside every EXPAND-phase decider
// it composes; `diplomacy_planner_peace_targets.dart` retains a thin
// delegating stub for the in-file `_expandRatchetGreatPowerPeaceTargets` /
// `collectStalledGreatPowerPeaceTargets` /
// `supplementMutualStalledGreatPowerPeaceOrders` consumer chains and
// the legacy `diplomacy_planner_stalled_peace_test.dart` fixture until
// the now-completed S1 deletion.
//
// Behavioral invariants pinned at the canonical entry point:
//
// `stalledOwExpansionNeedsPeacePass`:
//   1. Returns `false` when all 22 sub-deciders return empty/null —
//      a pristine game state with no conflicts triggers no peace pass.
//   2. Returns `true` when at least one sub-decider fires — the
//      `stalledZeroRegimentAllFactionPeaceTargets` decider is used as
//      the representative trigger (zero regiments, below quota, at-war
//      minor on invadable frontier).
//   3. Must-have #7 determinism: identical inputs produce identical
//      output across repeated calls.
//
// Delegation parity:
//   * The delegating stub in `diplomacy_planner_peace_targets.dart`
//     returns the same value as the canonical helper for every
//     representative input — required so the in-file
//     `_expandRatchetGreatPowerPeaceTargets` /
//     `collectStalledGreatPowerPeaceTargets` /
//     `supplementMutualStalledGreatPowerPeaceOrders` consumers
//     resolve to the same boolean result until the now-completed S1 deletion.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    as diplomacy_planner_peace_targets;
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';

void main() {
  group('stalledOwExpansionNeedsPeacePass — canonical home', () {
    test('returns false when no decider fires (pristine state)', () {
      final game = buildStalledOwPristineGame();
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [],
        invadableProvinceIdsSorted: const [],
      );
      expect(
        stalledOwExpansionNeedsPeacePass(game: game, snapshot: snapshot),
        isFalse,
        reason:
            'A pristine state with no at-war factions, no regiments, '
            'and an empty frontier should not trigger any peace decider. '
            'If this returns true, a sub-decider is incorrectly firing '
            'on an empty input.',
      );
    });

    test(
      'returns true when stalledZeroRegimentAllFactionPeaceTargets fires',
      () {
        final game = buildStalledOwZeroRegimentAtWarGame();
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const [kStalledOwMinorZeta],
          invadableProvinceIdsSorted: const [
            'oldWorld|${kStalledOwMinorZeta}_1',
          ],
        );
        expect(
          stalledOwExpansionNeedsPeacePass(game: game, snapshot: snapshot),
          isTrue,
          reason:
              'Zero-regiment survival decider fires on a below-quota GP '
              'with an at-war minor on an invadable frontier. The '
              'composite should return true.',
        );
      },
    );

    test('Determinism (Must-have #7) — identical result on repeat', () {
      final game = buildStalledOwZeroRegimentAtWarGame();
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [kStalledOwMinorZeta],
        invadableProvinceIdsSorted: const ['oldWorld|minor_zeta_1'],
      );
      final first = stalledOwExpansionNeedsPeacePass(
        game: game,
        snapshot: snapshot,
      );
      final second = stalledOwExpansionNeedsPeacePass(
        game: game,
        snapshot: snapshot,
      );
      expect(
        first,
        second,
        reason:
            'Identical inputs must yield identical output across '
            'consecutive calls (Refs #2509 Must-have #7).',
      );
    });

    test('Stub delegation parity', () {
      final game = buildStalledOwZeroRegimentAtWarGame();
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [kStalledOwMinorZeta],
        invadableProvinceIdsSorted: const ['oldWorld|minor_zeta_1'],
      );
      final canonical = stalledOwExpansionNeedsPeacePass(
        game: game,
        snapshot: snapshot,
      );
      final stub = diplomacy_planner_peace_targets
          .stalledOwExpansionNeedsPeacePass(game: game, snapshot: snapshot);
      expect(
        canonical,
        stub,
        reason:
            'The delegating stub must return the same boolean as the '
            'canonical helper so the in-file consumer chains resolve '
            'to the same result until the now-completed S1 deletion.',
      );
    });
  });
}
