// hasUninvadedOldWorldMinor truth table — at-war / mixed-minor rows (Refs #4239 Slice C; #4669 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_game_predicate_truth_support.dart';

void registerExpandPeaceGamePredicateUninvadedMinorTruthLateCases() {
  runExpandPeaceMatrixPredicateCases(
    'hasUninvadedOldWorldMinor (truth table — at-war / mixed minors)',
    hasUninvadedOldWorldMinor,
    <ExpandPeaceMatrixPredicateCase>[
      ExpandPeaceMatrixPredicateCase(
        name: 'only candidate minor is in atWarWith -> false (skip branch)',
        players: expandPeaceMatrixGp1Only,
        playerId: expandPeaceMatrixGp1,
        owProvinces: const [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixGp1,
          ),
          Province(
            id: 'oldWorld|m1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        ow: 0,
        atWarWith: const [expandPeaceMatrixMinor1],
        turnNumber: 50,
        expected: false,
        reason:
            'An at-war minor is "invaded" for the purpose of minor-first '
            'and must be skipped via `continue`. Even though the minor '
            'still owns OW (`oldWorld|m1_a`), the `atWarWith.contains` '
            'guard runs **before** the province `any` scan, so the '
            'province ownership never participates in the decision. A '
            'regression that inverted the guard would re-engage '
            'minor-first on every already-declared minor war and peace '
            'live GP fronts at quota.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'mixed minors: first at-war (skipped), second uninvaded + OW -> '
            'true',
        players: expandPeaceMatrixGp1Only,
        playerId: expandPeaceMatrixGp1,
        owProvinces: const [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixGp1,
          ),
          Province(
            id: 'oldWorld|m1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor1,
          ),
          Province(
            id: 'oldWorld|m2_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor2,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
          MinorNation(id: expandPeaceMatrixMinor2, displayName: 'M2'),
        ],
        ow: 0,
        atWarWith: const [expandPeaceMatrixMinor1],
        turnNumber: 50,
        expected: true,
        reason:
            'The first minor (`minor1`) is in `atWarWith` and must be '
            '`continue`d; the second minor (`minor2`) is uninvaded and '
            'still owns `oldWorld|m2_a`, so the second iteration\'s '
            '`any` predicate returns true. A regression that returned '
            'after the first `continue` (or otherwise short-circuited '
            'on the first skipped minor) would mis-report no '
            'minor-first target despite a clear declare-war candidate.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'mixed minors: first uninvaded no-OW, second uninvaded + OW -> true',
        players: expandPeaceMatrixGp1Only,
        playerId: expandPeaceMatrixGp1,
        owProvinces: const [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixGp1,
          ),
          Province(
            id: 'oldWorld|m2_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor2,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
          MinorNation(id: expandPeaceMatrixMinor2, displayName: 'M2'),
        ],
        ow: 0,
        turnNumber: 50,
        expected: true,
        reason:
            'The first minor (`minor1`) is uninvaded but owns no OW '
            'province; the inner `any` returns false and the outer '
            'loop must keep iterating, not return false early. The '
            'second minor (`minor2`) supplies the positive `any`. A '
            'regression that returned false after the first failed '
            'inner scan would miss every minor-first target whenever '
            'the no-OW minor was iterated first.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name: 'every minor is at-war -> false',
        players: expandPeaceMatrixGp1Only,
        playerId: expandPeaceMatrixGp1,
        owProvinces: const [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixGp1,
          ),
          Province(
            id: 'oldWorld|m1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor1,
          ),
          Province(
            id: 'oldWorld|m2_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor2,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
          MinorNation(id: expandPeaceMatrixMinor2, displayName: 'M2'),
        ],
        ow: 0,
        atWarWith: const [expandPeaceMatrixMinor1, expandPeaceMatrixMinor2],
        turnNumber: 50,
        expected: false,
        reason:
            'No uninvaded minor remains: every iteration `continue`s on '
            'the `atWarWith` check, and the trailing `return false` is '
            'the only reachable exit. A regression that ignored the '
            'at-war guard would falsely re-engage EXPAND minor-first '
            'on a roster that has no minor declare-war target left, '
            'peacing live GP fronts in the late EXPAND window.',
      ),
    ],
  );
}
