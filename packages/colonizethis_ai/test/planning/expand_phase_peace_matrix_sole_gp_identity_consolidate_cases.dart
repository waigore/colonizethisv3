// Sole-GP matrix pins (Refs #4602 Slice B).

// ignore_for_file: unused_element

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_sole_gp_support.dart';

void registerExpandPeaceSoleGpIdentityConsolidateCases() {
  runExpandPeaceSoleGpDecider(
    'consolidateGainsSoleGpPeaceTarget (truth table)',
    consolidateGainsSoleGpPeaceTarget,
    <ExpandPeaceSoleGpCase>[
      ExpandPeaceSoleGpCase(
        name: 'returns null when no Great Powers are at war (only minors)',
        game: buildExpandPeaceConsolidateTwoGpGame(
          focusOw: 20,
          enemyOw: 5,
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'focus',
              factionId2: 'minor1',
              state: RelationState.atWar,
              score: 10,
            ),
          ],
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'focus',
          atWarWith: const ['minor1'],
          oldWorldProvincesOwned: 20,
        ),
        reason:
            'soleAtWarGreatPowerId is null when only a minor is at war, so '
            'consolidateGainsSoleGpPeaceTarget must short-circuit before '
            'evaluating OW counts. Otherwise a stray minor war could silently '
            'unlock the consolidate peace for a GP that has no sole-GP enemy '
            'to peace at all.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'returns null when two or more Great Powers are at war',
        game: buildExpandPeaceConsolidateTwoGpGame(
          focusOw: 20,
          enemyOw: 5,
          extraGpIds: const ['gp3'],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'focus',
              factionId2: 'enemy',
              state: RelationState.atWar,
              score: 10,
            ),
            DiplomacyRelation(
              factionId1: 'focus',
              factionId2: 'gp3',
              state: RelationState.atWar,
              score: 10,
            ),
          ],
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'focus',
          atWarWith: const ['enemy', 'gp3'],
          oldWorldProvincesOwned: 20,
        ),
        reason:
            'consolidate peace is scoped to the *sole* GP enemy; with two GP '
            'wars active soleAtWarGreatPowerId returns null and this helper '
            'must defer to nearQuotaHoldPeaceTargets / multi-front peace '
            'paths rather than picking an arbitrary one to peace here.',
      ),
      ExpandPeaceSoleGpCase(
        name:
            'returns null at own == consolidate-min - 1 even with a huge lead',
        game: buildExpandPeaceConsolidateTwoGpGame(focusOw: 11, enemyOw: 1),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'focus',
          atWarWith: const ['enemy'],
          oldWorldProvincesOwned:
              kObserverConquestConsolidateMinOwProvinces - 1,
        ),
        reason:
            'One province below kObserverConquestConsolidateMinOwProvinces '
            '(11 OW today) must defer consolidate peace regardless of how '
            'large the enemy lead is. A regression that flipped `<` to `<=` '
            'here would silently peace one province earlier than SPEC.',
      ),
      ExpandPeaceSoleGpCase(
        name:
            'returns enemy at exact consolidate-min boundary with sufficient '
            'lead',
        game: buildExpandPeaceConsolidateTwoGpGame(focusOw: 12, enemyOw: 1),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'focus',
          atWarWith: const ['enemy'],
          oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        ),
        expected: 'enemy',
        reason:
            'Exactly at kObserverConquestConsolidateMinOwProvinces (12 OW) '
            'with a sufficient lead the consolidate peace must fire. A '
            'regression that flipped `<` to `<` or moved the threshold up '
            'would silently delay locking in observer gains.',
      ),
      ExpandPeaceSoleGpCase(
        name:
            'returns null at own == enemyOw + (lead - 1) with consolidate-min '
            'met',
        // enemyOw = 10, focusOw = 12 -> lead = 2 == 3 - 1. Consolidate-min
        // (12) is met, so the lead guard is the only thing keeping this null.
        game: buildExpandPeaceConsolidateTwoGpGame(focusOw: 12, enemyOw: 10),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'focus',
          atWarWith: const ['enemy'],
          oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        ),
        reason:
            'Lead of exactly (kConsolidateGainsSoleGpProvinceLead - 1) is '
            'one province short of the required gap. The consolidate peace '
            'must defer so the focus GP keeps pressing the war rather than '
            'lock in a marginal lead that a counter-offensive could erase.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'returns enemy at own == enemyOw + lead boundary',
        // enemyOw = 9, focusOw = 12 -> lead = 3 == required. Consolidate-min
        // (12) is met, so the lead boundary is the only deciding guard.
        game: buildExpandPeaceConsolidateTwoGpGame(focusOw: 12, enemyOw: 9),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'focus',
          atWarWith: const ['enemy'],
          oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        ),
        expected: 'enemy',
        reason:
            'Lead of exactly kConsolidateGainsSoleGpProvinceLead (3) at the '
            'consolidate-min boundary must fire the peace. A regression that '
            'tightened the gap to `>` would silently delay consolidate peace '
            'past the SPEC-authorized "lock observer gains" trigger.',
      ),
    ],
  );
}
