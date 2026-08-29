// hasUninvadedOldWorldMinor truth table — base rows (Refs #4239 Slice C; #4669 Slice B).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_game_predicate_truth_support.dart';

void registerExpandPeaceGamePredicateUninvadedMinorTruthEarlyCases() {
  runExpandPeaceMatrixPredicateCases(
    'hasUninvadedOldWorldMinor (truth table — base rows)',
    hasUninvadedOldWorldMinor,
    <ExpandPeaceMatrixPredicateCase>[
      ExpandPeaceMatrixPredicateCase(
        name: 'empty minor roster -> false',
        players: expandPeaceMatrixGp1Only,
        playerId: expandPeaceMatrixGp1,
        owProvinces: const [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixGp1,
          ),
        ],
        ow: 0,
        turnNumber: 50,
        expected: false,
        reason:
            'No minor nations on the map means the loop body never runs '
            'and the trailing `return false` is the only reachable exit. '
            'A regression that defaulted to true on an empty roster would '
            'incorrectly trigger the EXPAND minor-first peace pivot for '
            'every below-quota GP, peacing every live GP front and '
            'stalling the turn-100 conquest gate.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name: 'uninvaded minor that owns no OW province -> false',
        players: expandPeaceMatrixGp1Only,
        playerId: expandPeaceMatrixGp1,
        owProvinces: const [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixGp1,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        ow: 0,
        turnNumber: 50,
        expected: false,
        reason:
            'A minor that is not in `atWarWith` but owns no OW province '
            'cannot be the target of an EXPAND minor-first declare-war. '
            'The province-scan `any` is false, the loop completes, and '
            'the predicate falls through to `return false`. A regression '
            'that returned true on roster presence alone (without OW '
            'ownership) would trigger minor-first with no real '
            'declare-war target, peacing the wrong GP fronts.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name: 'uninvaded minor owns only NW province -> false',
        players: expandPeaceMatrixGp1Only,
        playerId: expandPeaceMatrixGp1,
        owProvinces: const [
          Province(
            id: 'oldWorld|gp1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixGp1,
          ),
        ],
        nwProvinces: const [
          Province(
            id: 'newWorld|m1_a',
            regionId: 'newWorld',
            ownerId: expandPeaceMatrixMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        ow: 0,
        turnNumber: 50,
        expected: false,
        reason:
            'NW minor holdings do not satisfy the EXPAND minor-first '
            'predicate -- the function iterates `oldWorld.provinces` '
            'only. A regression that scanned both regions would trigger '
            'EXPAND minor-first based on colonial holdings and peace '
            'live OW GP fronts that the minor-first rule was never '
            'meant to gate.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name: 'uninvaded minor owns at least one OW province -> true',
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
        turnNumber: 50,
        expected: true,
        reason:
            'Single uninvaded minor with one OW province satisfies the '
            'EXPAND minor-first precondition (SPEC § EXPAND "exit every '
            'GP front while uninvaded OW minors remain"). This is the '
            'canonical positive path: the first iteration short-circuits '
            'via the `any` predicate, the function returns true without '
            'inspecting the rest of the OW province list.',
      ),
    ],
  );
}
