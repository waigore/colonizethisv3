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

void registerExpandSoleGpPeaceDecidersUnwinnableCases() {
  group('unwinnableSoleGpFrontierPeaceTarget — sole-enemy guard', () {
    test('returns null when zero Great Powers are at war (only a minor)', () {
      // Builds an explicit minor-only at-war state: gp_own has minor1 in
      // its threats.atWarWith but no GP foes. `soleAtWarGreatPowerId`
      // returns null after `playerById` filters the minor out, so the
      // forced peace path must short-circuit before any deficit
      // comparison.
      final game = Game(
        id: 'g-unwinnable-only-minor-at-war-canonical',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
          oldWorld: RegionData(
            provinces: [
              for (var i = 1; i <= 5; i++)
                Province(
                  id: 'oldWorld|${soleGpPeaceGpOwn}_$i',
                  regionId: 'oldWorld',
                  ownerId: soleGpPeaceGpOwn,
                ),
              for (var i = 1; i <= 12; i++)
                Province(
                  id: 'oldWorld|${soleGpPeaceMinor1}_$i',
                  regionId: 'oldWorld',
                  ownerId: soleGpPeaceMinor1,
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
            score: 30,
          ),
        ],
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 5,
        atWarWith: const [soleGpPeaceMinor1],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Only a minor is in threats.atWarWith; soleAtWarGreatPowerId '
            'returns null and the canonical forced sole-GP-frontier peace '
            'path must short-circuit. A regression that broadened "sole '
            'GP at war" to "sole faction at war" would return "minor1" '
            'here.',
      );
    });

    test('returns null when two Great Powers are at war (multi-front)', () {
      // Two GPs in atWarWith collapses soleAtWarGreatPowerId to null;
      // the canonical forced peace path must defer to multi-front
      // diplomacy collectors.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 12,
        extraGpId: soleGpPeaceGpThird,
        extraGpProvinces: 12,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [soleGpPeaceGpPartner, soleGpPeaceGpThird],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Two GP wars violate the sole-enemy contract; the canonical '
            'forced sole-GP-frontier peace path must defer to multi-front '
            'diplomacy selection rather than unilaterally peace one GP.',
      );
    });
  });

  group('unwinnableSoleGpFrontierPeaceTarget — quota / pivot guards', () {
    test(
      'returns null at the observer OW quota even with a stronger sole GP',
      () {
        // At exactly kObserverConquestMinOwProvincesPerGp the EXPAND-only
        // forced shortcut must exit; consolidation diplomacy now owns the
        // decision.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          partnerProvinces: kObserverConquestMinOwProvincesPerGp + 5,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const [soleGpPeaceGpPartner],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'At-or-above the observer OW quota exits the canonical '
              'unwinnable-sole-GP shortcut so consolidation diplomacy '
              'decides when to peace.',
        );
      },
    );

    test('returns null when canPivotFromSoleGpWarAfterPeace is false', () {
      // Below quota, no minors anywhere, every invadable is GP-owned →
      // the pivot guard short-circuits to false and the forced peace
      // shortcut must defer.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 6,
        partnerProvinces: 12,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 6,
        atWarWith: const [soleGpPeaceGpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${soleGpPeaceGpPartner}_1'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'canPivotFromSoleGpWarAfterPeace=false (no OW minors, every '
            'invadable GP-owned) must short-circuit the canonical forced '
            'peace path before any deficit comparison.',
      );
    });
  });

  group('unwinnableSoleGpFrontierPeaceTarget — deficit band table', () {
    test('returns null on the default-start row when enemy ties (lead 0)', () {
      // own = kObserverDefaultStartOldWorldProvincesPerGp → minDeficit=1.
      // Tied enemy fails `enemyOw < own + 1` → null.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const [soleGpPeaceGpPartner],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Default-start band requires `enemyOw >= own + 1`. A tied '
            'enemy at own=kObserverDefaultStartOldWorldProvincesPerGp '
            'must not peace.',
      );
    });

    test('returns enemy at 9 OW non-GP-only with one-province lead', () {
      // own=9, partner=10 on a non-GP-only frontier → minDeficit=1
      // (8–9 OW non-GP-only row). lead 1 satisfies.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 10,
        extraInvadableMinorOwnerId: 'minor_frontier',
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const [soleGpPeaceGpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        soleGpPeaceGpPartner,
        reason:
            '9 OW non-GP-only with lead 1 peaces (minDeficit=1). Locks '
            'the upper boundary of the 8–9 OW non-GP-only row.',
      );
    });

    test('returns null at 9 OW GP-only frontier when lead is only 1', () {
      // own=9 on a GP-only invadable frontier → minDeficit =
      // kUnwinnableSoleGpMinProvinceDeficit (2). lead 1 fails the band.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 10,
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const [soleGpPeaceGpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${soleGpPeaceGpPartner}_1'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            '9 OW on a GP-only invadable frontier uses '
            'kUnwinnableSoleGpMinProvinceDeficit. Lead 1 must not peace. '
            'A regression that swapped the band selector to `minDeficit=1` '
            'on the GP-only row would silently surrender a near-quota war.',
      );
    });

    test(
      'returns enemy at 9 OW GP-only frontier when lead is exactly the band',
      () {
        // own=9, partner=11 (lead 2 == kUnwinnableSoleGpMinProvinceDeficit).
        // Locks the positive boundary of the GP-only row.
        final game = buildOwnVsPartnerExpandPeaceGame(
          ownProvinces: 9,
          partnerProvinces: 11,
          minorId: 'minor_pivot',
          minorProvinces: 1,
        );
        final snapshot = ownSnapshot(
          oldWorldProvincesOwned: 9,
          atWarWith: const [soleGpPeaceGpPartner],
          invadableProvinceIdsSorted: const ['oldWorld|${soleGpPeaceGpPartner}_1'],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          soleGpPeaceGpPartner,
          reason:
              '9 OW GP-only with lead exactly equal to '
              'kUnwinnableSoleGpMinProvinceDeficit must peace. The '
              'inequality is `enemyOw < own + minDeficit`, so equality '
              'satisfies.',
        );
      },
    );

    test('is deterministic across repeated calls (Must-have #7)', () {
      // Pins Must-have #7 directly at the canonical-home function
      // boundary for the unwinnable decider.
      final game = buildOwnVsPartnerExpandPeaceGame(
        ownProvinces: 9,
        partnerProvinces: 11,
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const [soleGpPeaceGpPartner],
        invadableProvinceIdsSorted: const ['oldWorld|${soleGpPeaceGpPartner}_1'],
      );
      final first = unwinnableSoleGpFrontierPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final second = unwinnableSoleGpFrontierPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      final third = unwinnableSoleGpFrontierPeaceTarget(
        game: game,
        snapshot: snapshot,
      );
      expect(first, soleGpPeaceGpPartner);
      expect(second, first);
      expect(third, first);
    });
  });
}
