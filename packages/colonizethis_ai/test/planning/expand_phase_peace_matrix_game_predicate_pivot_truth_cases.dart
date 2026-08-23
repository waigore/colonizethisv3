// canPivotFromSoleGpWarAfterPeace truth table (Refs #4239 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_game_predicate_truth_support.dart';

void registerExpandPeaceGamePredicatePivotTruthCases() {
  runExpandPeaceMatrixPredicateCases(
    'canPivotFromSoleGpWarAfterPeace (truth table)',
    canPivotFromSoleGpWarAfterPeace,
    <ExpandPeaceMatrixPredicateCase>[
      ExpandPeaceMatrixPredicateCase(
        name: 'quota-met short-circuit returns true even with no minor pivot',
        players: expandPeaceMatrixGp1Gp2,
        playerId: expandPeaceMatrixGp1,
        owProvinces: oldWorldProvincesForExpandPeaceMatrix(
          expandPeaceMatrixGp1,
          kObserverConquestMinOwProvincesPerGp,
          start: 1,
        ),
        ow: kObserverConquestMinOwProvincesPerGp,
        atWarWith: const [expandPeaceMatrixGp2],
        expected: true,
        reason:
            'A GP at the observer OW quota satisfies the leading short '
            'circuit regardless of pivot availability; '
            '`unwinnableSoleGpFrontierPeaceTarget` can then still consider '
            'a sole outgunned-GP peace target. A regression that dropped '
            'this short-circuit would refuse the SPEC-authorized peace '
            'pivot whenever quota-met GPs hold a sole foe without any '
            'remaining minor or invadable-minor frontier.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name: 'quota-exceeded with no minor pivot still returns true',
        players: expandPeaceMatrixGp1Gp2,
        playerId: expandPeaceMatrixGp1,
        owProvinces: oldWorldProvincesForExpandPeaceMatrix(
          expandPeaceMatrixGp1,
          kObserverConquestMinOwProvincesPerGp + 5,
          start: 1,
        ),
        ow: kObserverConquestMinOwProvincesPerGp + 5,
        atWarWith: const [expandPeaceMatrixGp2],
        expected: true,
        reason:
            'The quota-met branch is a `>=` short circuit; OW totals '
            'above quota must keep returning true so consolidate-gains '
            'callers see the same pivot availability.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name: 'below quota with an OW-owning uninvaded minor returns true',
        players: expandPeaceMatrixGp1Gp2,
        playerId: expandPeaceMatrixGp1,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            expandPeaceMatrixGp1,
            8,
            start: 1,
          ),
          const Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        ow: 8,
        atWarWith: const [expandPeaceMatrixGp2],
        invadable: const ['oldWorld|minor1_a'],
        expected: true,
        reason:
            'An OW minor on the map provides the SPEC-authorized minor '
            'pivot when the GP peaces its sole GP foe. A regression '
            'that collapsed the OW `minorsOnMap` scan would strand '
            'below-quota GPs in stalemated sole-GP wars (Refs #2509 '
            'turn-100 verify exit code 5).',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'OW minor already in atWarWith still counts as a pivot '
            '(no at-war filter)',
        players: expandPeaceMatrixGp1Gp2,
        playerId: expandPeaceMatrixGp1,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            expandPeaceMatrixGp1,
            8,
            start: 1,
          ),
          const Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: expandPeaceMatrixMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        ow: 8,
        atWarWith: const [expandPeaceMatrixGp2, expandPeaceMatrixMinor1],
        invadable: const ['oldWorld|minor1_a'],
        expected: true,
        reason:
            'The function is a pivot-availability check; whether the '
            'minor is currently in the at-war set is the higher-level '
            "collector's concern. Pinning this contract keeps that "
            'separation explicit.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'below quota with NW-only minor in invadable list returns true (B3)',
        players: expandPeaceMatrixGp1Gp2,
        playerId: expandPeaceMatrixGp1,
        owProvinces: oldWorldProvincesForExpandPeaceMatrix(
          expandPeaceMatrixGp1,
          8,
          start: 1,
        ),
        nwProvinces: const [
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: expandPeaceMatrixMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: expandPeaceMatrixMinor1, displayName: 'M1'),
        ],
        ow: 8,
        atWarWith: const [expandPeaceMatrixGp2],
        invadable: const ['newWorld|minor1_a'],
        expected: true,
        reason:
            'When no OW minor exists, an invadable-list province with '
            'a minor owner still satisfies the pivot check via the '
            'trailing `any`. A regression that collapsed this scan '
            'would refuse peace whenever the only pivot is an NW '
            'colonial minor frontier.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'below quota with GP-only invadable frontier and no minors returns '
            'false',
        players: expandPeaceMatrixGp1Gp2,
        playerId: expandPeaceMatrixGp1,
        owProvinces: [
          ...oldWorldProvincesForExpandPeaceMatrix(
            expandPeaceMatrixGp1,
            8,
            start: 1,
          ),
          ...oldWorldProvincesForExpandPeaceMatrix(
            expandPeaceMatrixGp2,
            3,
            start: 1,
          ),
        ],
        ow: 8,
        atWarWith: const [expandPeaceMatrixGp2],
        invadable: const ['oldWorld|gp2_1', 'oldWorld|gp2_2'],
        expected: false,
        reason:
            'No minor anywhere and a GP-only invadable frontier means '
            'peacing the sole GP foe leaves no SPEC-legal pivot target. '
            'A regression that defaulted to true here would peace the '
            "GP's only opponent and deadlock the EXPAND strategy "
            '(Refs #2509 § Observer goal phases (Full AI), EXPAND).',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'below quota with empty invadable list and no minors returns false',
        players: expandPeaceMatrixGp1Gp2,
        playerId: expandPeaceMatrixGp1,
        owProvinces: oldWorldProvincesForExpandPeaceMatrix(
          expandPeaceMatrixGp1,
          8,
          start: 1,
        ),
        ow: 8,
        atWarWith: const [expandPeaceMatrixGp2],
        expected: false,
        reason:
            'An empty invadable list combined with no OW minor on the '
            'map provides no pivot; the trailing `any` is false and '
            'the predicate must return false. A regression that '
            'short-circuited the empty-invadable branch to true would '
            'spuriously authorize peace pivots when no pivot exists.',
      ),
      ExpandPeaceMatrixPredicateCase(
        name:
            'just below quota with no minor and no invadable minor returns '
            'false',
        players: expandPeaceMatrixGp1Gp2,
        playerId: expandPeaceMatrixGp1,
        owProvinces: oldWorldProvincesForExpandPeaceMatrix(
          expandPeaceMatrixGp1,
          kObserverConquestMinOwProvincesPerGp - 1,
          start: 1,
        ),
        ow: kObserverConquestMinOwProvincesPerGp - 1,
        atWarWith: const [expandPeaceMatrixGp2],
        expected: false,
        reason:
            'The quota comparison is `>=`, so ownOw = quota - 1 must '
            'NOT short-circuit to true. With no minor pivot, the '
            'predicate must reach the trailing `return false` exit.',
      ),
    ],
  );
}
