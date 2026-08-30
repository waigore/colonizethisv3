// Sole-GP matrix pins (Refs #4602 Slice B).

// ignore_for_file: unused_element

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../support/expand_phase_peace_test_support.dart';
import 'expand_phase_peace_matrix_sole_gp_support.dart';

void registerExpandPeaceSoleGpBlockerGuardCases() {
  runExpandPeaceSoleGpDecider(
    'unwinnableSoleGpFrontierPeaceTarget (truth table)',
    unwinnableSoleGpFrontierPeaceTarget,
    <ExpandPeaceSoleGpCase>[
      ExpandPeaceSoleGpCase(
        name:
            'null when zero Great Powers are at war (only minor in atWarWith)',
        // `soleAtWarGreatPowerId` returns null when no entry in
        // `threats.atWarWith` matches a Great Power. Built inline (not via
        // `_ownVsPartnerGame`) because this is the only case where the at-war
        // partner is a minor, not a Great Power.
        game: Game(
          id: 'g-unwinnable-only-minor-at-war',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
            oldWorld: RegionData(
              provinces: [
                for (var i = 1; i <= 5; i++)
                  Province(
                    id: 'oldWorld|gp_own_$i',
                    regionId: 'oldWorld',
                    ownerId: 'gp_own',
                  ),
                for (var i = 1; i <= 12; i++)
                  Province(
                    id: 'oldWorld|minor1_$i',
                    regionId: 'oldWorld',
                    ownerId: 'minor1',
                  ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp_own', displayName: 'GP_OWN', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp_own',
              factionId2: 'minor1',
              state: RelationState.atWar,
              score: 30,
            ),
          ],
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 5,
          atWarWith: const ['minor1'],
        ),
        reason:
            'Only a minor is in threats.atWarWith, so soleAtWarGreatPowerId '
            'returns null and the forced sole-GP-frontier peace path must '
            'short-circuit before any deficit comparison. A regression that '
            'broadened "sole GP at war" to "sole faction at war" would '
            'return "minor1" here.',
      ),
      ExpandPeaceSoleGpCase(
        name:
            'null when two Great Powers are at war (multi-front, no single '
            'enemy)',
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 6,
          partnerProvinces: 12,
          partnerId: 'gp_partner',
          extraGpId: 'gp_third',
          extraGpProvinces: 12,
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 6,
          atWarWith: const ['gp_partner', 'gp_third'],
        ),
        reason:
            'Two GP wars violate the sole-enemy contract; the forced '
            'sole-GP-frontier peace path must defer to multi-front diplomacy '
            'selection (e.g. nearQuotaHoldPeaceTargets) instead of choosing '
            'one GP unilaterally.',
      ),
      ExpandPeaceSoleGpCase(
        name:
            'null at the observer OW quota even with a stronger sole GP enemy',
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          partnerProvinces: kObserverConquestMinOwProvincesPerGp + 5,
          partnerId: 'gp_partner',
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const ['gp_partner'],
        ),
        reason:
            'At-or-above the observer OW quota exits the unwinnable-sole-GP '
            'shortcut so consolidation diplomacy (`consolidateGainsSoleGp` / '
            '`quotaMetFutileBelowQuotaGp` etc.) decides when to peace.',
      ),
      ExpandPeaceSoleGpCase(
        name:
            'null when no minor pivot remains '
            '(canPivotFromSoleGpWarAfterPeace=false)',
        // own < quota, no minors on the OW map, every invadable GP-owned.
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 6,
          partnerProvinces: 12,
          partnerId: 'gp_partner',
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: 6,
          atWarWith: const ['gp_partner'],
          // Invadable owned by the partner GP (no minor pivot via invadable).
          invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
        ),
        reason:
            'canPivotFromSoleGpWarAfterPeace=false: no OW minors remain and '
            'every invadable belongs to a GP, so peacing the sole GP war '
            'leaves the GP with no minor pivot. The forced peace shortcut '
            'must defer to other survival paths.',
      ),
      ExpandPeaceSoleGpCase(
        name: 'null at default-start when enemy ties OW count (lead 0)',
        // own=kObserverDefaultStartOldWorldProvincesPerGp, minDeficit=1 row.
        // Enemy ties exactly (lead 0). `enemyOw < own + 1` -> null.
        game: buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
          partnerId: 'gp_partner',
          minorId: 'minor_pivot',
          minorProvinces: 1,
        ),
        snapshot: expandPeaceMatrixSnapshot(
          playerId: 'gp_own',
          oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
          atWarWith: const ['gp_partner'],
        ),
        reason:
            'Default-start band requires `enemyOw >= own + 1` (lead >= 1). '
            'A tied enemy at own=7 returns null. Guards against a regression '
            'that swapped `<` for `<=` (would peace at lead 0) or that '
            'inflated the default-start deficit above 1.',
      ),
    ],
  );
}
