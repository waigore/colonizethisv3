// Case bodies for `expand_phase_planner_sole_gp_peace_deciders_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

// Pins the canonical `unwinnableSoleGpFrontierPeaceTarget` and
// `consolidateGainsSoleGpPeaceTarget` sole-GP peace deciders in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// Both deciders were relocated from `colonial_pressure.dart` so they
// survive the now-completed S1 deletion of that file. The canonical
// implementations live in `expand_phase_planner.dart`.
//
// Live consumers (post-relocation):
//   * `unwinnableSoleGpFrontierPeaceTarget` is the below-quota EXPAND
//     shortcut that peaces an unwinnable sole-GP war so the planner can
//     pivot back to a minor frontier. Composes the canonical helpers
//     `soleAtWarGreatPowerId` (sole-GP precondition),
//     `canPivotFromSoleGpWarAfterPeace` (pivot-guard) and
//     `isOldWorldGpOnlyInvadableFrontier` (band selector) with the
//     deficit band table from `SPEC/ai/ai-architecture.md`
//     § Diplomacy targeting.
//   * `consolidateGainsSoleGpPeaceTarget` is the quota-met companion: it
//     locks in observer gains once the active player has secured a
//     comfortable OW buffer above the observer quota and leads the lone
//     GP enemy by at least `kConsolidateGainsSoleGpProvinceLead` OW
//     provinces.
//
// Behavioral invariants pinned here (all deterministic — Must-have #7):
//
//   1. `unwinnableSoleGpFrontierPeaceTarget` short-circuits to `null`
//      when `soleAtWarGreatPowerId` returns `null` (no GP foe / two-plus
//      GP foes), when the active player is at or above the observer OW
//      quota, and when `canPivotFromSoleGpWarAfterPeace` is `false`
//      (no minor pivot available).
//   2. `unwinnableSoleGpFrontierPeaceTarget` selects deficit band `1`
//      on the default-start row (`own ≤
//      kObserverDefaultStartOldWorldProvincesPerGp`) and the 8–9 OW
//      non-GP-only row, and the larger
//      `kUnwinnableSoleGpMinProvinceDeficit` on the 8–9 OW GP-only
//      invadable frontier row. Both boundaries (lead one short → null;
//      lead exactly equal to deficit → enemy) are pinned at the upper
//      8–9 OW band so the band-selection logic cannot silently regress.
//   3. `consolidateGainsSoleGpPeaceTarget` short-circuits to `null` when
//      `soleAtWarGreatPowerId` returns `null`, when
//      `oldWorldProvincesOwned` is strictly below
//      `kObserverConquestConsolidateMinOwProvinces`, and when the OW
//      lead is strictly below `kConsolidateGainsSoleGpProvinceLead`.
//      Both `>=` boundaries (own == consolidate-min, own == enemyOw +
//      lead) are pinned so a regression to `>` cannot delay or skip
//      the consolidate peace.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/expand_phase_peace_test_support.dart';


import 'expand_phase_planner_sole_gp_peace_deciders_support.dart';

void registerExpandSoleGpPeaceDecidersConsolidateCases() {

  group('consolidateGainsSoleGpPeaceTarget — sole-GP-null branch', () {
    test('returns null when no Great Powers are at war (only a minor)', () {
      // Minor-only at-war state: soleAtWarGreatPowerId is null, the
      // canonical consolidate shortcut must short-circuit.
      final game = Game(
        id: 'g-consolidate-only-minor-at-war-canonical',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
          oldWorld: RegionData(
            provinces: [
              for (
                var i = 0;
                i < kObserverConquestConsolidateMinOwProvinces;
                i++
              )
                Province(
                  id: 'oldWorld|${soleGpPeaceGpOwn}_$i',
                  regionId: 'oldWorld',
                  ownerId: soleGpPeaceGpOwn,
                ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: soleGpPeaceGpOwn, displayName: 'GP_OWN', isHuman: false),
        ],
        minorNations: const [MinorNation(id: soleGpPeaceMinor1, displayName: 'M1')],
        diplomacyRelations: const [
          DiplomacyRelation(
            factionId1: soleGpPeaceGpOwn,
            factionId2: soleGpPeaceMinor1,
            state: RelationState.atWar,
            score: 10,
          ),
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const [soleGpPeaceMinor1],
      );
      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'soleAtWarGreatPowerId is null when only a minor is at war, '
            'so the canonical consolidate shortcut must short-circuit '
            'before evaluating OW counts.',
      );
    });

    test('returns null when two Great Powers are at war', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestConsolidateMinOwProvinces,
        partnerProvinces: 1,
        extraGpId: soleGpPeaceGpThird,
        extraGpProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const [soleGpPeaceGpPartner, soleGpPeaceGpThird],
      );
      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Two GP wars violate the sole-GP precondition; the canonical '
            'consolidate shortcut must defer to multi-front collectors.',
      );
    });
  });

  group('consolidateGainsSoleGpPeaceTarget — consolidate-min boundary', () {
    test('returns null at own == consolidate-min - 1 with a huge lead', () {
      // own = 11 (= consolidate-min - 1), enemy = 1. Lead is 10 (≫ required
      // kConsolidateGainsSoleGpProvinceLead) but consolidate-min guard
      // short-circuits first.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestConsolidateMinOwProvinces - 1,
        partnerProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces - 1,
        atWarWith: const [soleGpPeaceGpPartner],
      );
      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'One province below kObserverConquestConsolidateMinOwProvinces '
            'must defer consolidate peace regardless of how large the '
            'enemy lead is. A regression that flipped `<` to `<=` would '
            'silently peace one province earlier than SPEC.',
      );
    });

    test(
      'returns enemy at exact consolidate-min boundary with sufficient lead',
      () {
        // own = consolidate-min, enemy = 1. Lead is consolidate-min - 1
        // (≥ kConsolidateGainsSoleGpProvinceLead). Locks the `>=`
        // boundary at the canonical-home function.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverConquestConsolidateMinOwProvinces,
          partnerProvinces: 1,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
          atWarWith: const [soleGpPeaceGpPartner],
        );
        expect(
          consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
          soleGpPeaceGpPartner,
          reason:
              'Exactly at kObserverConquestConsolidateMinOwProvinces with a '
              'sufficient lead the canonical consolidate peace must fire.',
        );
      },
    );
  });

  group('consolidateGainsSoleGpPeaceTarget — lead boundary', () {
    test(
      'returns null at own == enemyOw + (lead - 1) with consolidate-min met',
      () {
        // own = consolidate-min, enemy = consolidate-min - (lead - 1)
        //                              = consolidate-min - 2.
        // Lead is exactly kConsolidateGainsSoleGpProvinceLead - 1 → null.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverConquestConsolidateMinOwProvinces,
          partnerProvinces:
              kObserverConquestConsolidateMinOwProvinces -
              (kConsolidateGainsSoleGpProvinceLead - 1),
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
          atWarWith: const [soleGpPeaceGpPartner],
        );
        expect(
          consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Lead of exactly (kConsolidateGainsSoleGpProvinceLead - 1) '
              'is one province short of the required gap. The canonical '
              'consolidate peace must defer.',
        );
      },
    );

    test('returns enemy at own == enemyOw + lead boundary', () {
      // own = consolidate-min, enemy = consolidate-min - lead. Lead is
      // exactly kConsolidateGainsSoleGpProvinceLead → enemy.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestConsolidateMinOwProvinces,
        partnerProvinces:
            kObserverConquestConsolidateMinOwProvinces -
            kConsolidateGainsSoleGpProvinceLead,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const [soleGpPeaceGpPartner],
      );
      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        soleGpPeaceGpPartner,
        reason:
            'Lead of exactly kConsolidateGainsSoleGpProvinceLead at the '
            'consolidate-min boundary must fire the canonical peace. A '
            'regression that tightened the gap to `>` would silently '
            'delay consolidate peace past the SPEC-authorized "lock '
            'observer gains" trigger.',
      );
    });

    test('is deterministic across repeated calls (Must-have #7)', () {
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverConquestConsolidateMinOwProvinces,
        partnerProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const [soleGpPeaceGpPartner],
      );
      final first = consolidateGainsSoleGpPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final second = consolidateGainsSoleGpPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final third = consolidateGainsSoleGpPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      expect(first, soleGpPeaceGpPartner);
      expect(second, first);
      expect(third, first);
    });
  });
}
