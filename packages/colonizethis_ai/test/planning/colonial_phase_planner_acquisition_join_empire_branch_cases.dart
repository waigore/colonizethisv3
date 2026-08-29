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

const String _gp1 = kColonialPhaseGp1;
const String _gp2 = kColonialPhaseGp2;
const String _tribe1 = kColonialPhaseTribe1;
const String _tribe2 = kColonialPhaseTribe2;

const String _province1 = kColonialAcquisitionNwProv1;
const String _province2 = kColonialAcquisitionNwProv2;
const String _province3 = 'newWorld|gp2_a';


void registerColonialPhasePlannerAcquisitionJoinEmpireCasesPartA() {
group('planColonialAcquisition (Join Empire path)', () {
    test('empty invadable NW -> null (outer guard)', () {
      // No NW provinces to acquire -> the planner short-circuits
      // before reading the overture / relation / treasury gates. A
      // regression that emitted a target for an empty list would
      // produce an out-of-band acquisition order.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
      );
      final snapshot = buildColonialAcquisitionSnapshot(invadableNw: const []);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Empty invadable NW list short-circuits before the gate '
            'loop runs.',
      );
    });

    test('missing active player record -> null (outer guard)', () {
      // The snapshot references a player id that does not exist in
      // `game.players`. The planner's outer guard returns null so a
      // mis-dispatched call (e.g. snapshot built for a stale roster)
      // cannot emit an acquisition order.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1],
        playerId: 'gp-ghost',
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No matching Player record -> outer guard returns null '
            'before the candidate loop.',
      );
    });

    test('GP-owned NW province -> skip (no Join Empire toward GP)', () {
      // The candidate NW province is owned by another Great Power
      // (gp2). Join Empire toward a Great Power has different gates
      // (Empire Building tech + "nearly defeated") per the validator
      // and is out of scope for COLONIAL tribe / minor acquisition.
      // The planner skips GP-owned NW provinces structurally so the
      // tribe-targeted Join Empire is never accidentally emitted
      // toward a GP.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        newWorldProvinces: const [
          Province(id: _province3, regionId: 'newWorld', ownerId: _gp2),
        ],
        overtureStates: <OvertureState>[colonialAcquisitionNap(_gp1, _gp2)],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _gp2),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province3],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'GP-owned NW provinces are skipped by `game.playerById` '
            'returning non-null; Join Empire toward another GP has '
            'separate gates and never resolves through this planner.',
      );
    });

    test('tribe owner without overture -> null', () {
      // No `OvertureState(gpId, targetId)` row -> the overture
      // chain has not started, so Join Empire is not reachable
      // (`nap` is the precondition).
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Missing overture state -> Join Empire precondition '
            '(stage == nap) not met; planner returns null.',
      );
    });

    test('overture stage = embassy (not nap) -> null', () {
      // The validator gates on `currentStage == OvertureStage.nap`;
      // an earlier stage like `embassy` cannot advance directly to
      // `joinEmpire`. The planner mirrors the validator's gate.
      final game = buildColonialAcquisitionGame(
        gameIdPrefix: 'g-2509-colonial-acquisition',
        minorNations: kColonialAcquisitionDefaultMinors,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[
          colonialAcquisitionEmbassy(_gp1, _tribe1),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          colonialAcquisitionFriendly(_gp1, _tribe1),
        ],
      );
      final snapshot = buildColonialAcquisitionSnapshot(
        invadableNw: const [_province1],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Overture at embassy stage (not nap) -> Join Empire '
            'precondition not met; planner returns null and the '
            'follow-up overture planner advances the chain.',
      );
    });

  });
}
