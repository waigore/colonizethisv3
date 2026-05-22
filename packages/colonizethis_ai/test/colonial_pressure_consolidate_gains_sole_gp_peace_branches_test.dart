// Pins the **consolidate-gains** sole-GP peace branch table at the
// `consolidateGainsSoleGpPeaceTarget` function boundary (Refs #2509 §
// `SPEC/ai/ai-architecture.md` § Diplomacy targeting — "when this GP holds at
// least `kObserverConquestConsolidateMinOwProvinces` and leads the sole enemy
// by `kConsolidateGainsSoleGpProvinceLead` or more (lock observer gains
// before a counter-offensive)").
//
// The function has four distinct outcome paths:
//
//   1. `soleAtWarGreatPowerId(...) == null` -> returns `null`
//      (no sole-GP war: zero GP wars, or two or more GP wars; non-GP
//      enemies are ignored here.)
//   2. `oldWorldProvincesOwned < kObserverConquestConsolidateMinOwProvinces`
//      -> returns `null` (this GP has not yet built enough OW buffer above
//      the observer quota to risk locking in via peace.)
//   3. `oldWorldProvincesOwned < enemyOw + kConsolidateGainsSoleGpProvinceLead`
//      -> returns `null` (insufficient OW lead; the sole-GP war is not
//      "won" enough to consolidate yet.)
//   4. All preconditions met -> returns the sole GP enemy id (`String`).
//
// Sibling coverage that this file complements (but does not duplicate):
//
//   - `diplomacy_planner_stalled_peace_test.dart` already contains a single
//     positive happy-path test for case (4) at `(own=12, enemyOw=5)` only.
//     None of the three guard branches (cases 1–3) and none of the strict
//     `<` boundary inputs (`own == 11` vs `own == 12`,
//     `own == enemyOw + 2` vs `own == enemyOw + 3`) are pinned anywhere
//     today, leaving the predicate vulnerable to silent guard regressions
//     such as flipping `<` to `<=`, dropping the consolidate-min guard, or
//     dropping the lead guard entirely.
//   - `colonial_pressure_test.dart` exercises peer / near-quota / default
//     start peace target helpers, but never calls
//     `consolidateGainsSoleGpPeaceTarget`.
//   - `diplomatic_candidate_scoring_offer_peace*` tests cover the **score
//     bonus** layer that consumes this predicate's result and are not
//     branch tables for the predicate itself.
//
// What's not currently pinned (this file's coverage):
//
//   1. **Sole-GP-null branch.** `soleAtWarGreatPowerId` returns `null` when
//      there are zero GP wars (only minor/tribe enemies are at war, or no
//      war at all) and also when **two or more** GPs are at war. Both
//      shapes must yield `null` from `consolidateGainsSoleGpPeaceTarget`
//      regardless of any OW lead, otherwise the consolidate peace could
//      misfire into a multi-front context where the helper is not
//      intended to act.
//   2. **Consolidate-min boundary (`own >= 12`).** Returns `null` at
//      `own == kObserverConquestConsolidateMinOwProvinces - 1`
//      (one short, regardless of how big the lead is) and returns the
//      enemy at `own == kObserverConquestConsolidateMinOwProvinces`
//      (exact boundary with `>=`). A regression to `>` would silently
//      defer consolidate peace by one province.
//   3. **Lead boundary (`own >= enemyOw + 3`).** Returns `null` at
//      `own == enemyOw + (kConsolidateGainsSoleGpProvinceLead - 1)`
//      (one short of the required lead) and returns the enemy at
//      `own == enemyOw + kConsolidateGainsSoleGpProvinceLead`
//      (exact boundary with `>=`). Independent of the consolidate-min
//      guard above so a single-branch regression on the lead test does
//      not hide behind the size guard.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Builds a Game with two GPs (`focus` and `enemy`) whose OW holdings are
/// exactly [focusOw] and [enemyOw] respectively, optionally including
/// additional GP players from [extraGpIds] (used to construct multi-GP-war
/// shapes for the sole-GP-null branch).
///
/// Diplomacy relations and `playerById` lookups are intentionally minimal —
/// only the predicate's helpers (`soleAtWarGreatPowerId`,
/// `provinceCountOwnedBy`) are exercised by these fixtures.
Game _twoGpGame({
  required int focusOw,
  required int enemyOw,
  List<String> extraGpIds = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-consolidate-${focusOw}_$enemyOw',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 90),
      oldWorld: RegionData(
        provinces: [
          for (var i = 0; i < focusOw; i++)
            Province(
              id: 'oldWorld|focus_$i',
              regionId: 'oldWorld',
              ownerId: 'focus',
            ),
          for (var i = 0; i < enemyOw; i++)
            Province(
              id: 'oldWorld|enemy_$i',
              regionId: 'oldWorld',
              ownerId: 'enemy',
            ),
        ],
        units: const [],
      ),
      newWorld: const RegionData(provinces: [], units: []),
    ),
    players: [
      const Player(
        id: 'focus',
        displayName: 'Focus',
        isHuman: false,
        leaderKey: 'victoria',
      ),
      const Player(
        id: 'enemy',
        displayName: 'Enemy',
        isHuman: false,
        leaderKey: 'napoleon',
      ),
      for (final extra in extraGpIds)
        Player(id: extra, displayName: extra.toUpperCase(), isHuman: false),
    ],
    minorNations: minorNations,
    diplomacyRelations: diplomacyRelations,
  );
}

/// Snapshot for the focus GP with [focusOw] OW holdings and the given
/// at-war faction id list.
AIWorldSnapshot _focusSnapshot({
  required int focusOw,
  required List<String> atWarWith,
}) {
  return AIWorldSnapshot(
    playerId: 'focus',
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(oldWorldProvincesOwned: focusOw),
    colonial: const ColonialSummary(),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('consolidateGainsSoleGpPeaceTarget — sole-GP-null branch', () {
    test('returns null when no Great Powers are at war (only minors)', () {
      final game = _twoGpGame(
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
      );
      final snapshot = _focusSnapshot(focusOw: 20, atWarWith: const ['minor1']);

      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'soleAtWarGreatPowerId is null when only a minor is at war, so '
            'consolidateGainsSoleGpPeaceTarget must short-circuit before '
            'evaluating OW counts. Otherwise a stray minor war could silently '
            'unlock the consolidate peace for a GP that has no sole-GP enemy '
            'to peace at all.',
      );
    });

    test('returns null when two or more Great Powers are at war', () {
      final game = _twoGpGame(
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
      );
      final snapshot = _focusSnapshot(
        focusOw: 20,
        atWarWith: const ['enemy', 'gp3'],
      );

      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'consolidate peace is scoped to the *sole* GP enemy; with two GP '
            'wars active soleAtWarGreatPowerId returns null and this helper '
            'must defer to nearQuotaHoldPeaceTargets / multi-front peace '
            'paths rather than picking an arbitrary one to peace here.',
      );
    });
  });

  group('consolidateGainsSoleGpPeaceTarget — consolidate-min boundary', () {
    test('returns null at own == consolidate-min - 1 even with a huge lead',
        () {
      final game = _twoGpGame(focusOw: 11, enemyOw: 1);
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestConsolidateMinOwProvinces - 1,
        atWarWith: const ['enemy'],
      );

      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'One province below kObserverConquestConsolidateMinOwProvinces '
            '(11 OW today) must defer consolidate peace regardless of how '
            'large the enemy lead is. A regression that flipped `<` to `<=` '
            'here would silently peace one province earlier than SPEC.',
      );
    });

    test('returns enemy at exact consolidate-min boundary with sufficient lead',
        () {
      final game = _twoGpGame(focusOw: 12, enemyOw: 1);
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const ['enemy'],
      );

      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        'enemy',
        reason:
            'Exactly at kObserverConquestConsolidateMinOwProvinces (12 OW) '
            'with a sufficient lead the consolidate peace must fire. A '
            'regression that flipped `<` to `<` or moved the threshold up '
            'would silently delay locking in observer gains.',
      );
    });
  });

  group('consolidateGainsSoleGpPeaceTarget — lead boundary', () {
    test('returns null at own == enemyOw + (lead - 1) with consolidate-min met',
        () {
      // enemyOw = 10, focusOw = 12 -> lead = 2 == 3 - 1. Consolidate-min
      // (12) is met, so the lead guard is the only thing keeping this null.
      final game = _twoGpGame(focusOw: 12, enemyOw: 10);
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const ['enemy'],
      );

      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Lead of exactly (kConsolidateGainsSoleGpProvinceLead - 1) is '
            'one province short of the required gap. The consolidate peace '
            'must defer so the focus GP keeps pressing the war rather than '
            'lock in a marginal lead that a counter-offensive could erase.',
      );
    });

    test('returns enemy at own == enemyOw + lead boundary', () {
      // enemyOw = 9, focusOw = 12 -> lead = 3 == required. Consolidate-min
      // (12) is met, so the lead boundary is the only deciding guard.
      final game = _twoGpGame(focusOw: 12, enemyOw: 9);
      final snapshot = _focusSnapshot(
        focusOw: kObserverConquestConsolidateMinOwProvinces,
        atWarWith: const ['enemy'],
      );

      expect(
        consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot),
        'enemy',
        reason:
            'Lead of exactly kConsolidateGainsSoleGpProvinceLead (3) at the '
            'consolidate-min boundary must fire the peace. A regression that '
            'tightened the gap to `>` would silently delay consolidate peace '
            'past the SPEC-authorized "lock observer gains" trigger.',
      );
    });
  });
}
