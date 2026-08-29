// Case bodies for the Join-Empire arm of `planColonialAcquisition` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3).
//
// Spec contract (issue #2509 § COLONIAL phase planner §
// planColonialAcquisition, Acquisition method 1):
//
//   "Join Empire
//      → Conditions: embassy with owning tribe, treasury ≥ cost.
//      → Generate establishOverture(tribe) targeting Join Empire chain.
//      → This is the cheapest, fastest path — always preferred first."
//
// The planner aligns the loose "embassy" phrasing with the order-engine
// validator in
// `packages/colonizethis_logic/lib/src/orders/validators/diplomatic/`
// `join_empire_validator.dart`: Join Empire requires the active player's
// overture toward the tribe / minor target to already be at
// `OvertureStage.nap`, plus relation score ≥
// `relationScoreMinFriendly`, plus treasury ≥
// `joinEmpireCostForMinorOrTribe`. These tests pin each gate in
// isolation plus the deterministic-iteration contract on
// `ColonialSummary.invadableNewWorldProvinceIdsSorted`.
//
// `planColonialAcquisition` Join-Empire tests:
//
//   1. **Empty NW invadable -> null:** structural outer guard; no
//      candidate provinces, no acquisition.
//   2. **Missing active player record -> null:** structural outer
//      guard against mis-dispatched calls (e.g. legacy code that
//      reads a snapshot for a non-Player faction).
//   3. **GP-owned NW province -> skip:** Join Empire toward a Great
//      Power has different gates (Empire Building tech + nearly
//      defeated) per the validator; the planner skips GP-owned NW
//      provinces structurally so a tribe-targeted Join Empire is
//      never accidentally emitted toward a GP.
//   4. **Tribe owner without overture -> null:** missing
//      `OvertureState(gpId, targetId)` row -> Join Empire not yet
//      reachable via the validator's `nap` gate.
//   5. **Tribe owner overture at `embassy` (not `nap`) -> null:**
//      validator pin -- Join Empire requires `nap` specifically; an
//      earlier stage cannot advance directly to `joinEmpire`.
//   6. **Tribe owner overture at `nap` + treasury below cost -> null:**
//      treasury gate -- the £$cost = $joinEmpireBaseCost + $n *
//      $joinEmpirePerProvinceCost check from the validator.
//   7. **Tribe owner overture at `nap` + relation below Friendly ->
//      null:** Friendly+ relation gate from the validator.
//   8. **Tribe owner overture at `nap` + Friendly relation + treasury
//      sufficient -> Join Empire target:** canonical happy path.
//   9. **Two valid tribe targets -> first sorted NW province wins:**
//      deterministic iteration over
//      `ColonialSummary.invadableNewWorldProvinceIdsSorted`. The
//      planner picks the tribe whose first sorted invadable NW
//      province has the lowest provinceId.
//  10. **Determinism (Must-have #7):** identical inputs produce
//      identical `ColonialAcquisitionTarget`s across repeated calls.
//
// All tests use synthetic Game/AIWorldSnapshot fixtures with one
// active GP (`gp1`), the candidate tribe / minor (`tribe1`), and
// optional GP-owned NW provinces. The fixtures intentionally keep OW
// state empty -- this planner consumes the colonial NW invadable
// list, treasury, overture state, and province-owner map; nothing
// else.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_acquisition_test_support.dart';
import 'colonial_phase_planner_acquisition_join_empire_iteration_cases.dart';

const String _gp1 = kColonialPhaseGp1;
const String _gp2 = kColonialPhaseGp2;
const String _tribe1 = kColonialPhaseTribe1;
const String _tribe2 = kColonialPhaseTribe2;

const String _province1 = kColonialAcquisitionNwProv1;
const String _province2 = kColonialAcquisitionNwProv2;
const String _province3 = 'newWorld|gp2_a';


void registerColonialPhasePlannerAcquisitionJoinEmpireCasesPartB() {
group('planColonialAcquisition (Join Empire path)', () {
    test('nap + treasury below joinEmpireCostForMinorOrTribe -> null', () {
      // The validator rejects with "Join Empire requires £$cost" when
      // treasury < cost. The planner mirrors the same threshold so
      // it does not suggest an order the engine would reject.
      // `tribe1` owns one NW province -> joinEmpire cost =
      // joinEmpireBaseCost (5000) + 1 * joinEmpirePerProvinceCost
      // (2000) = 7000. Treasury 6999 -> reject.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        activePlayerTreasury: 6999,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[colonialAcquisitionNap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1],
        treasury: 6999,
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Treasury (6999) below joinEmpireBaseCost + 1 * '
            'joinEmpirePerProvinceCost (7000) -> validator would '
            'reject; planner returns null.',
      );
    });

    test('nap + relation below Friendly -> null', () {
      // The validator rejects with "Join Empire requires at least
      // Friendly relations" when score < relationScoreMinFriendly
      // (51). The planner mirrors the gate so it does not suggest
      // a rejected order.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[colonialAcquisitionNap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[
          DiplomacyRelation(
            factionId1: _gp1,
            factionId2: _tribe1,
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Relation score 50 (Neutral) below Friendly threshold '
            '(51) -> validator would reject; planner returns null.',
      );
    });

    test('nap + Friendly + treasury sufficient -> Join Empire target', () {
      // Canonical happy path: all four gates pass for tribe1 over
      // its single NW province `province1`. The planner returns the
      // `(tribe1, joinEmpire)` target so the orchestrator can emit
      // `establishOverture(tribe1)` advancing the chain
      // nap -> joinEmpire on resolution.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[colonialAcquisitionNap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'All four Join Empire gates pass (stage == nap, '
            'Friendly+ relation, treasury >= cost, tribe owner) -> '
            'planner returns the canonical (tribe1, joinEmpire) '
            'target.',
      );
    });
  });

  registerColonialPhasePlannerAcquisitionJoinEmpireCasesIteration();
}
