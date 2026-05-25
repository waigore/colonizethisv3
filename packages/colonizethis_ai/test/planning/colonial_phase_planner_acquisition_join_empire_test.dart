// Unit tests for the Join-Empire arm of `planColonialAcquisition` in
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

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';
const String _minor1 = 'minor1';

const String _province1 = 'newWorld|tribe1_a';
const String _province2 = 'newWorld|tribe2_b';
const String _province3 = 'newWorld|gp2_a';

Game _acquisitionGame({
  int turnNumber = 130,
  int activePlayerTreasury = 100000,
  List<Province> newWorldProvinces = const [],
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 100000),
    Player(id: _gp2, displayName: 'GP2', isHuman: false),
  ],
  List<Tribe> tribes = const [
    Tribe(id: _tribe1, displayName: 'T1'),
    Tribe(id: _tribe2, displayName: 'T2'),
  ],
  List<MinorNation> minorNations = const [
    MinorNation(id: _minor1, displayName: 'M1'),
  ],
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
}) {
  final patchedPlayers = <Player>[
    for (final p in players)
      if (p.id == _gp1) p.copyWith(treasury: activePlayerTreasury) else p,
  ];
  return Game(
    id: 'g-2509-colonial-acquisition-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: newWorldProvinces),
    ),
    players: patchedPlayers,
    tribes: tribes,
    minorNations: minorNations,
    overtureStates: overtureStates,
    diplomacyRelations: diplomacyRelations,
  );
}

AIWorldSnapshot _acquisitionSnapshot({
  required List<String> invadableNw,
  String playerId = _gp1,
  int treasury = 100000,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 10,
      provincesToVictory: 31,
    ),
    colonial: ColonialSummary(invadableNewWorldProvinceIdsSorted: invadableNw),
    economy: EconomySummary(treasury: treasury),
    relations: const {},
  );
}

OvertureState _nap(String gpId, String targetId, {int sinceTurn = 100}) =>
    OvertureState(
      gpId: gpId,
      targetId: targetId,
      stage: OvertureStage.nap,
      sinceTurn: sinceTurn,
    );

OvertureState _embassy(String gpId, String targetId, {int sinceTurn = 100}) =>
    OvertureState(
      gpId: gpId,
      targetId: targetId,
      stage: OvertureStage.embassy,
      sinceTurn: sinceTurn,
    );

DiplomacyRelation _friendly(String a, String b, {int score = 60}) =>
    DiplomacyRelation(
      factionId1: a,
      factionId2: b,
      score: score,
      level: RelationLevel.friendly,
    );

void main() {
  group('planColonialAcquisition (Join Empire path)', () {
    test('empty invadable NW -> null (outer guard)', () {
      // No NW provinces to acquire -> the planner short-circuits
      // before reading the overture / relation / treasury gates. A
      // regression that emitted a target for an empty list would
      // produce an out-of-band acquisition order.
      final game = _acquisitionGame();
      final snapshot = _acquisitionSnapshot(invadableNw: const []);
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
      final game = _acquisitionGame();
      final snapshot = _acquisitionSnapshot(
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
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _province3, regionId: 'newWorld', ownerId: _gp2),
        ],
        overtureStates: <OvertureState>[_nap(_gp1, _gp2)],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _gp2)],
      );
      final snapshot = _acquisitionSnapshot(invadableNw: const [_province3]);
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
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _tribe1)],
      );
      final snapshot = _acquisitionSnapshot(invadableNw: const [_province1]);
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
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _tribe1)],
      );
      final snapshot = _acquisitionSnapshot(invadableNw: const [_province1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Overture at embassy stage (not nap) -> Join Empire '
            'precondition not met; planner returns null and the '
            'follow-up overture planner advances the chain.',
      );
    });

    test('nap + treasury below joinEmpireCostForMinorOrTribe -> null', () {
      // The validator rejects with "Join Empire requires £$cost" when
      // treasury < cost. The planner mirrors the same threshold so
      // it does not suggest an order the engine would reject.
      // `tribe1` owns one NW province -> joinEmpire cost =
      // joinEmpireBaseCost (5000) + 1 * joinEmpirePerProvinceCost
      // (2000) = 7000. Treasury 6999 -> reject.
      final game = _acquisitionGame(
        activePlayerTreasury: 6999,
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[_nap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _tribe1)],
      );
      final snapshot = _acquisitionSnapshot(
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
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[_nap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[
          DiplomacyRelation(
            factionId1: _gp1,
            factionId2: _tribe1,
            score: 50,
            level: RelationLevel.neutral,
          ),
        ],
      );
      final snapshot = _acquisitionSnapshot(invadableNw: const [_province1]);
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
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[_nap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _tribe1)],
      );
      final snapshot = _acquisitionSnapshot(invadableNw: const [_province1]);
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

    test('two valid tribe targets -> first sorted invadable NW wins', () {
      // Both tribe1 and tribe2 satisfy every Join Empire gate. The
      // planner picks the tribe whose NW province appears first in
      // `invadableNewWorldProvinceIdsSorted` (ascending). With
      // `province1 = newWorld|tribe1_a` < `province2 = newWorld|tribe2_b`
      // the iteration hits tribe1 first.
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _province2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        overtureStates: <OvertureState>[
          _nap(_gp1, _tribe1),
          _nap(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          _friendly(_gp1, _tribe1),
          _friendly(_gp1, _tribe2),
        ],
      );
      final snapshot = _acquisitionSnapshot(
        invadableNw: const [_province1, _province2],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'Iteration over `invadableNewWorldProvinceIdsSorted` is '
            'ascending; the first satisfying province (tribe1) wins '
            'the deterministic tie-break (Refs #2509 Must-have #7).',
      );
    });

    test('second sorted tribe wins when first sorted tribe fails a gate', () {
      // Same two-target setup, but tribe1 fails the treasury gate
      // (single-province join-empire cost 7000 > 5000 treasury) while
      // tribe2 (also single-province, cost 7000) also fails. Drop the
      // treasury below tribe1 cost but raise NW province count so
      // tribe2 fails earlier. We instead use overture stage: tribe1
      // at `embassy` (fails the nap gate), tribe2 at `nap` -> tribe2
      // wins. Pins the per-target gate evaluation order independently
      // of the iteration order.
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _province2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        overtureStates: <OvertureState>[
          _embassy(_gp1, _tribe1),
          _nap(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          _friendly(_gp1, _tribe1),
          _friendly(_gp1, _tribe2),
        ],
      );
      final snapshot = _acquisitionSnapshot(
        invadableNw: const [_province1, _province2],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe2,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'tribe1 fails the nap gate (overture at embassy) so the '
            'iteration falls through to tribe2 whose overture is at '
            'nap. The second-sorted province wins when the first '
            'fails a gate.',
      );
    });

    test('determinism: identical inputs produce identical targets', () {
      // Must-have #7 pin: repeated calls on the same game / snapshot
      // must return byte-identical results.
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _province1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _province2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        overtureStates: <OvertureState>[
          _nap(_gp1, _tribe1),
          _nap(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          _friendly(_gp1, _tribe1),
          _friendly(_gp1, _tribe2),
        ],
      );
      final snapshot = _acquisitionSnapshot(
        invadableNw: const [_province1, _province2],
      );
      final first = planColonialAcquisition(game: game, snapshot: snapshot);
      final second = planColonialAcquisition(game: game, snapshot: snapshot);
      expect(second, first);
      expect(
        first,
        isNotNull,
        reason: 'Determinism test must run on a satisfying input.',
      );
    });
  });
}
