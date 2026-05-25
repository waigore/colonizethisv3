// Pins the `unwinnableSoleGpFrontierPeaceTarget` branch table (Refs #2509
// § Observer goal phases (Full AI) — "Forced offerPeace toward the sole at-war
// Great Power ...").
//
//   SPEC/ai/ai-architecture.md § Domain planner order / Diplomacy targeting:
//     "Forced offerPeace toward the sole at-war Great Power when this GP is
//     below kObserverConquestMinOwProvincesPerGp and that enemy leads by at
//     least kUnwinnableSoleGpMinProvinceDeficit OW provinces while holdings
//     are at or below default observer start size OR the Old World frontier
//     is GP-only invadable, OR leads by 1 OW province when holdings are 8–9
//     without a GP-only invadable frontier (pivot to minors) ..."
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `diplomacy_planner_stalled_peace_test.dart` — one positive case at
//     ownOw=5 with a minor on the OW map (`pivot` via minorsOnMap) and a
//     stronger sole GP enemy (5 vs 12). Pins the "stronger sole GP enemy
//     returned" happy path only.
//   - `diplomacy_planner_below_quota_peace_test.dart` — three positive cases:
//     - ownOw=6 on a GP-only frontier vs enemy=12 (lead 6 ≫ minDeficit=1
//       because own ≤ kObserverDefaultStartOldWorldProvincesPerGp).
//     - ownOw=8 on a non-GP-only frontier vs enemy=9 (lead 1 satisfies
//       minDeficit=1 in the 8–9-OW non-GP-only branch).
//     - ownOw=7 default-start vs enemy=8 (lead 1 satisfies minDeficit=1).
//     All positive. None pin the null branches or the GP-only-frontier
//     minDeficit=`kUnwinnableSoleGpMinProvinceDeficit` (2) path.
//
// What this file pins that no sibling pins today:
//
//   1. **Sole-enemy guard fall-throughs:** `soleAtWarGreatPowerId == null`
//      collapses the predicate to `null` regardless of how outgunned this
//      GP is. Pins both the 0-GP-wars-at-war (only minor in
//      `threats.atWarWith`) and the 2-GPs-at-war (multi-front) shapes so a
//      regression that loosened "sole" to "any GP at war" surfaces here.
//   2. **Quota short-circuit:** `isBelowObserverConquestQuota == false` at
//      exactly `kObserverConquestMinOwProvincesPerGp` returns `null` even
//      when a stronger sole GP enemy could otherwise drive the peace
//      decision. Pins the boundary between EXPAND/COLONIAL (own >= quota)
//      and the EXPAND-only forced-peace shortcut.
//   3. **`canPivotFromSoleGpWarAfterPeace == false` short-circuit:** With
//      no minors on the OW map and every invadable province owned by Great
//      Powers, no minor pivot exists and the forced sole-GP peace path
//      must defer to other diplomacy logic instead of peacing the only war
//      that could still bleed enemy regiments (Refs #2509 — preserve the
//      late-game survival peace paths via other helpers).
//   4. **`minDeficit` selection table:** The three rows in the minDeficit
//      ternary chain are not all pinned at their negative boundary today:
//      - **default-start row (own ≤ 7):** `enemyOw == own` (lead 0) returns
//        `null` (only the +1 lead positive shape is pinned today). A
//        regression that swapped `<` for `<=` or that always used the
//        higher `kUnwinnableSoleGpMinProvinceDeficit` would silently flip
//        this row.
//      - **8–9 OW non-GP-only row:** `enemyOw == own` (lead 0) returns
//        `null` (only the +1 lead positive shape is pinned today).
//        Re-validates the lead-1-suffices rule from the existing test at
//        ownOw=8 by re-pinning it at ownOw=9 (boundary of the upper band).
//      - **8–9 OW GP-only row:** `minDeficit = kUnwinnableSoleGpMinProvinceDeficit`
//        is not pinned today at all. Cover negative (`lead 1 → null`) and
//        positive (`lead 2 → enemy`) at both ownOw=8 and ownOw=9 so the
//        GP-only ternary branch is locked at both boundaries.
//
// Each test isolates one row in the branch table by constructing the
// smallest `Game` + `AIWorldSnapshot` shape that exercises that row, so a
// regression that flips one edge fails this file with a focused diagnostic.

import 'package:colonizethis_ai/src/perception/perception_snapshot.dart';
import 'package:colonizethis_ai/src/planning/colonial_pressure.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Builds a minimal `Game` where `gp_own` holds [ownProvinces] OW provinces,
/// the at-war partner `partnerId` holds [partnerProvinces] OW provinces, and
/// the OW map optionally carries a [minorId]-owned province and/or
/// [extraInvadableMinorId]-owned invadable province (the snapshot's
/// `invadableProvinceIdsSorted` is constructed by the caller).
///
/// Diplomacy relations between `gp_own` and `partnerId` default to atWar.
/// The optional [extraGpId] (with [extraGpProvinces] OW provinces and an
/// extra at-war relation toward `gp_own`) opts into the multi-GP-war shape
/// used to pin the sole-enemy guard's 2-GPs branch.
Game _ownVsPartnerGame({
  required int ownProvinces,
  required int partnerProvinces,
  required String partnerId,
  String? extraGpId,
  int extraGpProvinces = 0,
  String? minorId,
  int minorProvinces = 0,
  String? extraInvadableMinorOwnerId,
  bool atWarWithPartner = true,
  bool atWarWithExtraGp = true,
  bool atWarWithMinor = false,
}) {
  final provinces = <Province>[
    for (var i = 1; i <= ownProvinces; i++)
      Province(
        id: 'oldWorld|gp_own_$i',
        regionId: 'oldWorld',
        ownerId: 'gp_own',
      ),
    for (var i = 1; i <= partnerProvinces; i++)
      Province(
        id: 'oldWorld|${partnerId}_$i',
        regionId: 'oldWorld',
        ownerId: partnerId,
      ),
    if (extraGpId != null)
      for (var i = 1; i <= extraGpProvinces; i++)
        Province(
          id: 'oldWorld|${extraGpId}_$i',
          regionId: 'oldWorld',
          ownerId: extraGpId,
        ),
    if (minorId != null)
      for (var i = 1; i <= minorProvinces; i++)
        Province(
          id: 'oldWorld|${minorId}_$i',
          regionId: 'oldWorld',
          ownerId: minorId,
        ),
    if (extraInvadableMinorOwnerId != null)
      Province(
        id: 'oldWorld|invadable_minor',
        regionId: 'oldWorld',
        ownerId: extraInvadableMinorOwnerId,
      ),
  ];

  final players = <Player>[
    const Player(id: 'gp_own', displayName: 'GP_OWN', isHuman: false),
    Player(id: partnerId, displayName: partnerId, isHuman: false),
    if (extraGpId != null)
      Player(id: extraGpId, displayName: extraGpId, isHuman: false),
  ];

  final minorNations = <MinorNation>[
    if (minorId != null) MinorNation(id: minorId, displayName: minorId),
    if (extraInvadableMinorOwnerId != null)
      MinorNation(
        id: extraInvadableMinorOwnerId,
        displayName: extraInvadableMinorOwnerId,
      ),
  ];

  final relations = <DiplomacyRelation>[
    if (atWarWithPartner)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: partnerId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (extraGpId != null && atWarWithExtraGp)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: extraGpId,
        state: RelationState.atWar,
        score: 30,
      ),
    if (minorId != null && atWarWithMinor)
      DiplomacyRelation(
        factionId1: 'gp_own',
        factionId2: minorId,
        state: RelationState.atWar,
        score: 30,
      ),
  ];

  return Game(
    id: 'g-unwinnable-sole-gp-${ownProvinces}_vs_$partnerProvinces',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 80),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    diplomacyRelations: relations,
  );
}

/// Builds the snapshot for `gp_own` with the given `oldWorldProvincesOwned`,
/// `atWarWith`, and `invadableProvinceIdsSorted`. All other summaries default
/// to empty (only the `unwinnableSoleGpFrontierPeaceTarget` inputs matter).
AIWorldSnapshot _ownSnapshot({
  required int oldWorldProvincesOwned,
  required List<String> atWarWith,
  List<String> invadableProvinceIdsSorted = const [],
}) {
  return AIWorldSnapshot(
    playerId: 'gp_own',
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      invadableProvinceIdsSorted: invadableProvinceIdsSorted,
    ),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('unwinnableSoleGpFrontierPeaceTarget — sole-enemy guard', () {
    test(
      'null when zero Great Powers are at war (only minor in atWarWith)',
      () {
        // `soleAtWarGreatPowerId` returns null when no entry in
        // `threats.atWarWith` matches a Great Power (`game.playerById` only
        // resolves Great Powers; minor nations live on `game.minorNations`).
        // With an OW-stalled GP that would otherwise want to peace anyone
        // (own=5 vs minor enemy=12), the sole-enemy guard must short-circuit
        // before any deficit comparison so the predicate never peaces a
        // minor as if it were a Great Power.
        //
        // Inline (not via `_ownVsPartnerGame`) because this is the only case
        // where the at-war partner is a minor, not a Great Power, and the
        // helper would otherwise register the partner as a Player and defeat
        // the sole-GP-guard intent.
        final game = Game(
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
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 5,
          atWarWith: const ['minor1'],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Only a minor is in threats.atWarWith, so soleAtWarGreatPowerId '
              'returns null and the forced sole-GP-frontier peace path must '
              'short-circuit before any deficit comparison. A regression that '
              'broadened "sole GP at war" to "sole faction at war" would '
              'return "minor1" here.',
        );
      },
    );

    test(
      'null when two Great Powers are at war (multi-front, no single enemy)',
      () {
        // soleAtWarGreatPowerId requires exactly one GP in the at-war set.
        // With two stronger GPs at war the predicate must defer to multi-front
        // peace paths (nearQuotaHoldPeaceTargets etc.); a sole-front forced
        // peace toward either GP here would skip the multi-front blocker
        // selection logic and could leak the wrong target.
        final game = _ownVsPartnerGame(
          ownProvinces: 6,
          partnerProvinces: 12,
          partnerId: 'gp_partner',
          extraGpId: 'gp_third',
          extraGpProvinces: 12,
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const ['gp_partner', 'gp_third'],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'Two GP wars violate the sole-enemy contract; the forced '
              'sole-GP-frontier peace path must defer to multi-front diplomacy '
              'selection (e.g. nearQuotaHoldPeaceTargets) instead of choosing '
              'one GP unilaterally.',
        );
      },
    );
  });

  group('unwinnableSoleGpFrontierPeaceTarget — quota / pivot guards', () {
    test(
      'null at the observer OW quota even with a stronger sole GP enemy',
      () {
        // The forced sole-GP-frontier peace path is an EXPAND-only shortcut.
        // At exactly kObserverConquestMinOwProvincesPerGp the GP has met the
        // observer quota and consolidation diplomacy (consolidate gains,
        // quota-met futile peace, etc.) owns the peace decision. The forced
        // shortcut must not fire even when the enemy still leads in OW.
        final game = _ownVsPartnerGame(
          ownProvinces: kObserverConquestMinOwProvincesPerGp,
          partnerProvinces: kObserverConquestMinOwProvincesPerGp + 5,
          partnerId: 'gp_partner',
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp,
          atWarWith: const ['gp_partner'],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'At-or-above the observer OW quota exits the unwinnable-sole-GP '
              'shortcut so consolidation diplomacy (`consolidateGainsSoleGp` / '
              '`quotaMetFutileBelowQuotaGp` etc.) decides when to peace.',
        );
      },
    );

    test(
      'null when no minor pivot remains (canPivotFromSoleGpWarAfterPeace=false)',
      () {
        // Build a state where own < quota, no minors exist on the OW map, and
        // every invadable province is GP-owned. canPivotFromSoleGpWarAfterPeace
        // returns false, so the forced peace path must defer (e.g., to the
        // critical-weak survival paths) — peacing the only GP war here would
        // leave the GP with no front and no minor pivot, blocking expansion.
        final game = _ownVsPartnerGame(
          ownProvinces: 6,
          partnerProvinces: 12,
          partnerId: 'gp_partner',
        );
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 6,
          atWarWith: const ['gp_partner'],
          // Invadable owned by the partner GP (no minor pivot via invadable).
          invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              'canPivotFromSoleGpWarAfterPeace=false: no OW minors remain and '
              'every invadable belongs to a GP, so peacing the sole GP war '
              'leaves the GP with no minor pivot. The forced peace shortcut '
              'must defer to other survival paths.',
        );
      },
    );
  });

  group('unwinnableSoleGpFrontierPeaceTarget — deficit table', () {
    // default-start band (own ≤ kObserverDefaultStartOldWorldProvincesPerGp):
    test('null at default-start when enemy ties OW count (lead 0)', () {
      // own=kObserverDefaultStartOldWorldProvincesPerGp, minDeficit=1 row.
      // Enemy ties exactly (lead 0). `enemyOw < own + 1` → null. The
      // existing positive at lead 1 lives in
      // `diplomacy_planner_below_quota_peace_test.dart` so this file pins
      // the negative boundary.
      final game = _ownVsPartnerGame(
        ownProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerProvinces: kObserverDefaultStartOldWorldProvincesPerGp,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: kObserverDefaultStartOldWorldProvincesPerGp,
        atWarWith: const ['gp_partner'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Default-start band requires `enemyOw >= own + 1` (lead ≥ 1). '
            'A tied enemy at own=7 returns null. Guards against a regression '
            'that swapped `<` for `<=` (would peace at lead 0) or that '
            'inflated the default-start deficit above 1.',
      );
    });

    // 8–9 OW band, non-GP-only frontier (minDeficit=1):
    test('null at 8 OW non-GP-only when enemy ties (lead 0)', () {
      // own=8 ≥ kObserverConquestMinOwProvincesPerGp - 2, !GP-only frontier
      // (minor on the invadable), minDeficit=1. Enemy ties → null. Pins
      // the negative boundary the existing 8-OW positive case
      // (`diplomacy_planner_below_quota_peace_test.dart`) does not cover.
      final game = _ownVsPartnerGame(
        ownProvinces: 8,
        partnerProvinces: 8,
        partnerId: 'gp_partner',
        extraInvadableMinorOwnerId: 'minor_frontier',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            '8 OW non-GP-only band still requires lead ≥ 1. A regression '
            'that promoted ties to peace would peace too eagerly when the '
            'GP is at parity with its enemy.',
      );
    });

    test('null at 9 OW non-GP-only when enemy ties (lead 0)', () {
      // Re-pin the 8–9 OW non-GP-only minDeficit=1 row at the upper boundary
      // (own=9). The condition is `own >= kObserverConquestMinOwProvincesPerGp
      // - 2 && !gpOnly`, so own=9 must also use minDeficit=1.
      final game = _ownVsPartnerGame(
        ownProvinces: 9,
        partnerProvinces: 9,
        partnerId: 'gp_partner',
        extraInvadableMinorOwnerId: 'minor_frontier',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            '9 OW non-GP-only also uses minDeficit=1. Tied enemy at own=9 '
            'still returns null. A regression that narrowed the 8–9-OW '
            'non-GP-only branch to own=8 only would silently flip this row.',
      );
    });

    test('returns enemy at 9 OW non-GP-only with one-province lead', () {
      // Positive boundary pin for the 9-OW row (the existing positive case
      // covers own=8 only). Enemy=10 leads by 1; minDeficit=1; satisfies.
      final game = _ownVsPartnerGame(
        ownProvinces: 9,
        partnerProvinces: 10,
        partnerId: 'gp_partner',
        extraInvadableMinorOwnerId: 'minor_frontier',
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|invadable_minor'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        'gp_partner',
        reason:
            '9 OW non-GP-only with lead-1 enemy must peace (minDeficit=1). '
            'Mirrors the existing 8-OW pin and locks the upper boundary '
            'of the 8–9 OW non-GP-only row.',
      );
    });

    // 8–9 OW band, GP-only frontier (minDeficit=kUnwinnableSoleGpMinProvinceDeficit):
    test(
      'null at 8 OW GP-only frontier when enemy leads by only 1 (needs 2)',
      () {
        // own=8 on a GP-only invadable frontier triggers the
        // `kUnwinnableSoleGpMinProvinceDeficit` row. Enemy=9 (lead 1) is
        // strictly below own + 2 → null. Pins the negative boundary not
        // covered today.
        final game = _ownVsPartnerGame(
          ownProvinces: 8,
          partnerProvinces: 9,
          partnerId: 'gp_partner',
          minorId: 'minor_pivot',
          minorProvinces: 1,
        );
        // GP-only invadable: the invadable province is the partner's, no
        // minor owns any invadable.
        final snapshot = _ownSnapshot(
          oldWorldProvincesOwned: 8,
          atWarWith: const ['gp_partner'],
          invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
        );
        expect(
          unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
          isNull,
          reason:
              '8 OW on a GP-only invadable frontier requires lead ≥ '
              'kUnwinnableSoleGpMinProvinceDeficit (currently 2). Lead 1 must '
              'not trigger the forced peace shortcut so the GP keeps the war '
              'open against a near-peer GP-only blocker.',
        );
      },
    );

    test('returns enemy at 8 OW GP-only frontier when enemy leads by 2', () {
      // own=8 GP-only frontier, enemy=10 (lead 2 == minDeficit). `<` is
      // strict so 10 >= 8+2 → enemy. Pins the positive boundary for the
      // GP-only minDeficit row.
      final game = _ownVsPartnerGame(
        ownProvinces: 8,
        partnerProvinces: 10,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 8,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        'gp_partner',
        reason:
            '8 OW GP-only with lead exactly equal to '
            'kUnwinnableSoleGpMinProvinceDeficit must peace (the inequality '
            'is `enemyOw < own + minDeficit`, so equality satisfies). '
            'Guards against a regression to a strict `>` lead requirement.',
      );
    });

    test('null at 9 OW GP-only frontier when enemy leads by only 1', () {
      // Upper boundary of the GP-only band (own=9). Lead 1 still fails the
      // minDeficit=2 row. Pins that the GP-only branch applies at own=9.
      final game = _ownVsPartnerGame(
        ownProvinces: 9,
        partnerProvinces: 10,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            '9 OW on a GP-only invadable frontier still uses '
            'kUnwinnableSoleGpMinProvinceDeficit. Lead 1 returns null. A '
            'regression that exempted own=9 from the GP-only branch would '
            'silently peace at lead 1 and surrender the near-quota war.',
      );
    });

    test('returns enemy at 9 OW GP-only frontier when enemy leads by 2', () {
      // own=9 GP-only frontier, enemy=11 (lead 2). Locks the positive
      // boundary at the upper end of the GP-only band so both own=8 and
      // own=9 are pinned at lead == kUnwinnableSoleGpMinProvinceDeficit.
      final game = _ownVsPartnerGame(
        ownProvinces: 9,
        partnerProvinces: 11,
        partnerId: 'gp_partner',
        minorId: 'minor_pivot',
        minorProvinces: 1,
      );
      final snapshot = _ownSnapshot(
        oldWorldProvincesOwned: 9,
        atWarWith: const ['gp_partner'],
        invadableProvinceIdsSorted: const ['oldWorld|gp_partner_1'],
      );
      expect(
        unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot),
        'gp_partner',
        reason:
            '9 OW GP-only with lead exactly equal to '
            'kUnwinnableSoleGpMinProvinceDeficit must peace. Locks the '
            'upper boundary of the GP-only row.',
      );
    });
  });
}
