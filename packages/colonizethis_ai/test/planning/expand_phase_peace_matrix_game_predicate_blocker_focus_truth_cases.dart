// isStalledOldWorldGpBlockerFocus truth table (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_game_predicate_truth_support.dart';

void registerExpandPeaceGamePredicateBlockerFocusTruthCases() {
  // --- isStalledOldWorldGpBlockerFocus (gp5/gp6 roster, GP-only frontier). ---
  runExpandPeaceMatrixPredicateCases(
    'isStalledOldWorldGpBlockerFocus (truth table)',
    isStalledOldWorldGpBlockerFocus,
    <ExpandPeaceMatrixPredicateCase>[
      ExpandPeaceMatrixPredicateCase(
        name:
            'false when at the observer OW quota even with a GP-only invadable '
            'frontier',
        players: expandPeaceMatrixGp5Gp6,
        playerId: expandPeaceMatrixGp5,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            expandPeaceMatrixGp5,
            kObserverConquestMinOwProvincesPerGp,
          ),
          expandPeaceMatrixGp6Frontier,
        ],
        ow: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [expandPeaceMatrixGp6],
        invadable: const ['oldWorld|gp6_frontier'],
        turnNumber: 60,
        expected: false,
        reason:
            'at-quota short-circuit must skip the GP-only frontier delegate',
      ),
      ExpandPeaceMatrixPredicateCase(
        name: 'false when below quota but no invadable provinces remain',
        players: expandPeaceMatrixGp5Gp6,
        playerId: expandPeaceMatrixGp5,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(expandPeaceMatrixGp5, 8),
          expandPeaceMatrixGp6Frontier,
        ],
        ow: 8,
        atWarWith: const [expandPeaceMatrixGp6],
        turnNumber: 60,
        expected: false,
        reason: 'empty invadable list defeats the GP-only frontier delegate',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'false when an invadable province is owned by a minor nation '
            '(minor pivot)',
        players: expandPeaceMatrixGp5Gp6,
        playerId: expandPeaceMatrixGp5,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(expandPeaceMatrixGp5, 8),
          expandPeaceMatrixGp6Frontier,
          const Province(
            id: 'oldWorld|minor1_p1',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        ow: 8,
        atWarWith: const [expandPeaceMatrixGp6],
        invadable: const ['oldWorld|gp6_frontier', 'oldWorld|minor1_p1'],
        turnNumber: 60,
        expected: false,
        reason: 'minor-owned invadable province must break the GP-only focus',
      ),
      ExpandPeaceMatrixPredicateCase(
        name: 'false when every invadable province is owned by a tribe (no GP)',
        players: expandPeaceMatrixGp5Gp6,
        playerId: expandPeaceMatrixGp5,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(expandPeaceMatrixGp5, 8),
          const Province(
            id: 'oldWorld|tribe1_p1',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixTribe1,
          ),
        ],
        tribes: const [Tribe(id: expandPeaceMatrixTribe1, displayName: 'T1')],
        ow: 8,
        invadable: const ['oldWorld|tribe1_p1'],
        turnNumber: 60,
        expected: false,
        reason:
            'tribe-owned invadable provinces do not satisfy the GP-only check',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'true when below quota and every invadable province is owned by a '
            'Great Power (canonical seed-42 gp5/gp6 trap)',
        players: expandPeaceMatrixGp5Gp6,
        playerId: expandPeaceMatrixGp5,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(expandPeaceMatrixGp5, 9),
          expandPeaceMatrixGp6Frontier,
        ],
        ow: 9,
        atWarWith: const [expandPeaceMatrixGp6],
        invadable: const ['oldWorld|gp6_frontier'],
        turnNumber: 60,
        expected: true,
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'true at zero OW provinces with an all-GP invadable list '
            '(lower bound)',
        players: expandPeaceMatrixGp5Gp6,
        playerId: expandPeaceMatrixGp5,
        owProvinces: const [expandPeaceMatrixGp6Frontier],
        ow: 0,
        atWarWith: const [expandPeaceMatrixGp6],
        invadable: const ['oldWorld|gp6_frontier'],
        turnNumber: 60,
        expected: true,
        reason: 'no non-zero OW floor — only the quota ceiling matters',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'true just below the observer OW quota with an all-GP invadable '
            'list (quota - 1 boundary)',
        players: expandPeaceMatrixGp5Gp6,
        playerId: expandPeaceMatrixGp5,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            expandPeaceMatrixGp5,
            kObserverConquestMinOwProvincesPerGp - 1,
          ),
          expandPeaceMatrixGp6Frontier,
        ],
        ow: kObserverConquestMinOwProvincesPerGp - 1,
        atWarWith: const [expandPeaceMatrixGp6],
        invadable: const ['oldWorld|gp6_frontier'],
        turnNumber: 60,
        expected: true,
        reason: 'one province below quota must still trip the predicate',
      ),
    ],
  );
}
