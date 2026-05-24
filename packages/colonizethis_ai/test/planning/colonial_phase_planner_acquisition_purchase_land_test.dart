// Unit tests for the `purchase_land` arm (Acquisition method 2) of
// `planColonialAcquisition` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3).
//
// Spec contract (issue #2509 § COLONIAL phase planner §
// planColonialAcquisition, Acquisition method 2):
//
//   "purchase_land
//      → Conditions: idle Merchant unit, tile has resource (prospected
//        if mineral), treasury ≥ purchase cost.
//      → Generate purchase_land work order for Merchant."
//
// The planner's `purchase_land` arm runs only when the Join-Empire
// pass yields no target. Per-province gates mirror the order-engine
// validator in
// `packages/colonizethis_logic/lib/src/orders/validators/`
// `work_order_target_prechecks.dart` (`precheckPurchaseLand`):
//
//   - target province owner is a tribe / minor (not GP, not self);
//   - active player is not at war with that owner;
//   - active player has at least an embassy-stage overture
//     (`OvertureState.hasEmbassy`);
//   - the province contains at least one tile that is itself a valid
//     `purchase_land` candidate: non-empty resource id, not already
//     purchased, treasury covers `purchaseLandCost`, mineral-resource
//     tiles already prospected by the active player.
//
// In addition, the arm has an outer guard: the active player must
// hold at least one idle Merchant ([Unit.type] == [kUnitTypeMerchant],
// [Unit.status] == [UnitStatus.idle]) anywhere in the world.
//
// `planColonialAcquisition` purchase_land tests:
//
//   1. **No idle Merchant -> null:** outer guard pin. Even when a
//      satisfying province exists, missing-Merchant short-circuits
//      the second pass before any per-province loop runs.
//   2. **Working Merchant does not satisfy the guard -> null:**
//      [UnitStatus.working] explicitly excluded, parallels the
//      Builder-status filter pinned by `planColonialCivilian`.
//   3. **GP-owned NW province -> skip (no purchase from GP):**
//      structural mirror of validator's "must be a Minor or Tribe
//      province"; Join Empire and `purchase_land` both filter GPs at
//      `game.playerById(ownerId) != null`.
//   4. **At-war tribe -> skip:** validator-side
//      `relation?.atWar == true` rejection. The planner must not
//      suggest `purchase_land` against a faction it is currently
//      fighting.
//   5. **No overture -> skip:** missing
//      `OvertureState(gpId, targetId)` -> `overture == null` ->
//      `purchase_land` not yet legal (validator requires embassy).
//   6. **Overture at `tradeConsulate` (no embassy yet) -> skip:**
//      pins `OvertureState.hasEmbassy` semantics — only stages in
//      `{embassy, nap, joinEmpire}` satisfy the gate, and
//      `tradeConsulate` is one rung below `embassy`.
//   7. **Tile has no resource entry -> skip:** validator rejects with
//      "Tile has no resource"; the planner mirrors the gate by
//      requiring at least one resource tile in the province.
//   8. **Mineral tile not prospected -> skip:** validator rejects
//      with "Mineral tile must be prospected first"; the planner
//      mirrors the gate using `WorldState.playerProspectedTiles`.
//   9. **Treasury below purchase cost -> skip:** validator rejects
//      with "Insufficient treasury for purchase_land"; the planner
//      mirrors the gate using `purchaseLandCost(resourceId)`.
//  10. **Tile already purchased -> skip:** validator rejects when a
//      tile is already in `WorldState.purchasedTilesByTileKey`; the
//      planner mirrors the gate.
//  11. **Embassy + valid grain tile + idle Merchant -> purchase_land
//      target:** canonical happy path with a non-mineral resource
//      (no prospect requirement). Matches the AC text "Given a GP in
//      COLONIAL with idle Merchant, treasury ≥ purchase cost, and a
//      visible newWorld| province with a valid purchase_land target
//      tile, when planColonialAcquisition runs and Join Empire is
//      unavailable, then the return value is `(tribeFactionId,
//      AcquisitionMethod.purchaseLand)`."
//  12. **Embassy + valid prospected mineral tile + idle Merchant ->
//      purchase_land target:** same path through the mineral-prospect
//      gate. Pins that the planner accepts mineral resources when the
//      tile is in the active player's prospected-tile set.
//  13. **Join Empire and purchase_land both reachable -> Join Empire
//      wins:** priority pin. Even with a valid Merchant + tile pair,
//      a satisfying Join-Empire candidate suppresses the
//      `purchase_land` arm entirely (the spec calls Join Empire "the
//      cheapest, fastest path — always preferred first").
//  14. **Join Empire treasury shortfall -> purchase_land rescue:**
//      the active player has Join-Empire-eligible state (overture at
//      `nap`, Friendly relation) but the treasury does not cover
//      `joinEmpireCostForMinorOrTribe`; treasury still covers the
//      smaller `purchaseLandCost`, so the planner falls through to
//      the second pass and returns `(tribe1, purchaseLand)`. Pins
//      that the second pass exists and that the iteration is *not*
//      collapsed into a single per-province method-tree.
//  15. **Two valid tribe targets -> first sorted invadable NW
//      province wins:** deterministic iteration over
//      `ColonialSummary.invadableNewWorldProvinceIdsSorted`, mirroring
//      the Join-Empire arm's tie-break (Refs #2509 Must-have #7).
//  16. **Determinism (Must-have #7):** identical inputs produce
//      identical `ColonialAcquisitionTarget`s across repeated calls.
//
// All tests use synthetic Game/AIWorldSnapshot fixtures with one
// active GP (`gp1`), the candidate tribe (`tribe1` / `tribe2`), and
// optional GP-owned NW provinces. The fixtures intentionally keep OW
// state empty -- this arm consumes the colonial NW invadable list,
// treasury, overture state, relation state, prospected-tile set,
// purchased-tile map, resource-by-tile map, and the active player's
// idle Merchant roster; nothing else.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';

const String _nwProv1 = 'newWorld|tribe1_a';
const String _nwProv2 = 'newWorld|tribe2_b';
const String _nwProvGp = 'newWorld|gp2_c';

const String _nwTile1 = 'newWorld|tribe1_a|1|1';
const String _nwTile1Alt = 'newWorld|tribe1_a|2|2';
const String _nwTile2 = 'newWorld|tribe2_b|1|1';

/// Builds a `Game` for the `purchase_land` arm tests.
///
/// `units` are placed in the New World region — the Merchant lookup
/// scans both regions via [allUnitsFromWorld], so the test fixture
/// can keep OW empty. `prospectedTilesForGp1` seeds the active
/// player's [WorldState.playerProspectedTiles] entry; `purchasedTiles`
/// seeds [WorldState.purchasedTilesByTileKey] (existing buyer ownership
/// of a tile blocks new `purchase_land` orders).
Game _purchaseLandGame({
  int turnNumber = 130,
  int activePlayerTreasury = 100000,
  List<Province> newWorldProvinces = const [],
  List<Unit> newWorldUnits = const [],
  Map<String, String> resourceByTileKey = const {},
  Set<String> prospectedTilesForGp1 = const {},
  Map<String, String> purchasedTiles = const {},
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
}) {
  return Game(
    id: 'g-2509-colonial-acquisition-purchase-land-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      resourceByTileKey: resourceByTileKey,
      playerProspectedTiles: prospectedTilesForGp1.isEmpty
          ? const <String, Set<String>>{}
          : <String, Set<String>>{_gp1: prospectedTilesForGp1},
      purchasedTilesByTileKey: purchasedTiles,
    ),
    players: [
      Player(
        id: _gp1,
        displayName: 'GP1',
        isHuman: false,
        treasury: activePlayerTreasury,
      ),
      const Player(id: _gp2, displayName: 'GP2', isHuman: false),
    ],
    tribes: const [
      Tribe(id: _tribe1, displayName: 'T1'),
      Tribe(id: _tribe2, displayName: 'T2'),
    ],
    overtureStates: overtureStates,
    diplomacyRelations: diplomacyRelations,
  );
}

AIWorldSnapshot _purchaseLandSnapshot({
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

OvertureState _embassy(String gpId, String targetId, {int sinceTurn = 100}) =>
    OvertureState(
      gpId: gpId,
      targetId: targetId,
      stage: OvertureStage.embassy,
      sinceTurn: sinceTurn,
    );

OvertureState _nap(String gpId, String targetId, {int sinceTurn = 100}) =>
    OvertureState(
      gpId: gpId,
      targetId: targetId,
      stage: OvertureStage.nap,
      sinceTurn: sinceTurn,
    );

OvertureState _tradeConsulate(
  String gpId,
  String targetId, {
  int sinceTurn = 100,
}) => OvertureState(
  gpId: gpId,
  targetId: targetId,
  stage: OvertureStage.tradeConsulate,
  sinceTurn: sinceTurn,
);

DiplomacyRelation _peaceFriendly(String a, String b, {int score = 60}) =>
    DiplomacyRelation(
      factionId1: a,
      factionId2: b,
      score: score,
      level: RelationLevel.friendly,
    );

DiplomacyRelation _atWar(String a, String b, {int score = 10}) =>
    DiplomacyRelation(
      factionId1: a,
      factionId2: b,
      score: score,
      level: RelationLevel.hostile,
      state: RelationState.atWar,
    );

Unit _merchant(
  String id, {
  String provinceId = _nwProv1,
  UnitStatus status = UnitStatus.idle,
  String tileSuffix = '5|5',
}) => Unit(
  id: id,
  type: kUnitTypeMerchant,
  ownerId: _gp1,
  locationProvinceId: provinceId,
  tileKey: '$provinceId|$tileSuffix',
  status: status,
);

void main() {
  group('planColonialAcquisition (purchase_land path)', () {
    test('no idle Merchant -> null (outer guard)', () {
      // The Join-Empire pass returns null because the overture is at
      // `embassy` (not `nap`). The purchase_land pass would otherwise
      // accept the tribe1 fixture, but the active player has zero
      // Merchant units -> outer guard short-circuits the second
      // loop. A regression that suggested `purchase_land` here would
      // emit an order with no eligible Merchant to execute it.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Outer Merchant guard must short-circuit before the per-'
            'province loop fires; otherwise a regression could emit a '
            'purchase_land target with no Merchant to execute it.',
      );
    });

    test('working Merchant does not satisfy outer guard -> null', () {
      // A Merchant exists but is mid-work (`status == working`).
      // [UnitStatus.idle] is required so the resolver can re-task
      // the unit; mirror the Builder-idle filter pinned in
      // `planColonialCivilian`.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m_busy', status: UnitStatus.working)],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Working Merchants are not assignable to a new purchase_'
            'land directive; the planner must short-circuit when no '
            'idle Merchant exists.',
      );
    });

    test('GP-owned NW province -> skip (no purchase from GP)', () {
      // Validator: "purchase_land target must be a Minor or Tribe
      // province". The planner enforces this structurally via
      // `game.playerById(ownerId) != null` -> skip; mirrors the
      // Join-Empire arm's GP-skip pin.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProvGp, regionId: 'newWorld', ownerId: _gp2),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {'newWorld|gp2_c|1|1': 'grain'},
        overtureStates: <OvertureState>[_embassy(_gp1, _gp2)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _gp2)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProvGp]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Validator rejects purchase_land when the owner is another '
            'GP; the planner skips GP-owned NW provinces structurally '
            'so the purchase_land arm is never emitted toward a GP.',
      );
    });

    test('at-war tribe -> skip', () {
      // Validator: "Cannot purchase land: at war with that faction".
      // Even with embassy + valid tile + idle Merchant, the at-war
      // gate must reject the candidate.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_atWar(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'At-war relation rejects purchase_land via the validator; '
            'the planner mirrors that gate.',
      );
    });

    test('no overture -> skip', () {
      // Validator: "Cannot purchase land: embassy required ...". With
      // no `OvertureState(gpId, targetId)` row, `getOverture` returns
      // null -> embassy gate fails.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Missing overture state -> validator rejects with embassy '
            'requirement; planner mirrors the gate.',
      );
    });

    test('overture at tradeConsulate (no embassy) -> skip', () {
      // `OvertureState.hasEmbassy` is true only for stages in
      // `{embassy, nap, joinEmpire}`. The `tradeConsulate` stage
      // sits one rung below `embassy` and must be rejected by the
      // planner just as it is by the validator.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[_tradeConsulate(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Stage `tradeConsulate` -> hasEmbassy = false; validator '
            'and planner both reject. Pins that early-stage overtures '
            'do not unlock the purchase_land path.',
      );
    });

    test('tile has no resource entry -> skip', () {
      // Validator: "Tile has no resource". Without at least one tile
      // in the province carrying a non-empty resource id, the
      // planner cannot find a satisfying `purchase_land` candidate.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const <String, String>{},
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'No resource tiles in the province -> no valid '
            'purchase_land target; validator rejects with "Tile has '
            'no resource"; planner mirrors that gate.',
      );
    });

    test('mineral tile not prospected -> skip', () {
      // Validator: "Mineral tile must be prospected first". The
      // planner mirrors the gate using the active player's
      // `WorldState.playerProspectedTiles` entry. With no entry for
      // gp1, the iron tile fails the gate.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'iron'},
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Mineral tile (`iron`) not in active player\'s prospected '
            'set -> validator rejects; planner mirrors the gate so a '
            'purchase_land target is never emitted toward an '
            'unprospected mineral tile.',
      );
    });

    test('treasury below purchaseLandCost -> skip', () {
      // Validator: "Insufficient treasury for purchase_land (need
      // $cost)". `purchaseLandCost('grain') = 15 *
      // landPurchaseDefaultBasePrice (10) = 150`; treasury 149 fails
      // the gate.
      final game = _purchaseLandGame(
        activePlayerTreasury: 149,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(
        invadableNw: const [_nwProv1],
        treasury: 149,
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Treasury (149) below purchaseLandCost("grain") (150) -> '
            'validator rejects; planner mirrors the gate.',
      );
    });

    test('tile already purchased -> skip', () {
      // Validator: "Tile already purchased by another power" or "You
      // already own this tile". A tile present in
      // `WorldState.purchasedTilesByTileKey` is locked out of
      // additional `purchase_land` orders regardless of buyer
      // identity.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        purchasedTiles: const {_nwTile1: _gp2},
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'Tile in purchasedTilesByTileKey is unavailable for new '
            'purchase_land orders; planner skips and finds no other '
            'satisfying tile in the province.',
      );
    });

    test(
      'embassy + valid grain tile + idle Merchant -> purchase_land target',
      () {
        // Canonical happy path with a non-mineral resource (`grain`)
        // so the prospect gate is structurally satisfied. The
        // active player has an embassy-stage overture, peace
        // relations, treasury well above purchaseLandCost, an idle
        // Merchant, and exactly one resource tile in the candidate
        // province. Acceptance criterion #2509 § "(COLONIAL
        // acquisition — purchase_land)": "Given a GP in COLONIAL
        // with idle Merchant, treasury ≥ purchase cost, and a
        // visible newWorld| province with a valid purchase_land
        // target tile, when planColonialAcquisition runs and Join
        // Empire is unavailable, then the return value is
        // (tribeFactionId, AcquisitionMethod.purchaseLand)."
        final game = _purchaseLandGame(
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          ],
          newWorldUnits: <Unit>[_merchant('m1')],
          resourceByTileKey: const {_nwTile1: 'grain'},
          overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
          diplomacyRelations: <DiplomacyRelation>[
            _peaceFriendly(_gp1, _tribe1),
          ],
        );
        final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
        expect(
          planColonialAcquisition(game: game, snapshot: snapshot),
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.purchaseLand,
          ),
          reason:
              'All purchase_land gates pass (embassy stage, peace, '
              'idle Merchant, grain tile not minerally gated, '
              'treasury covers cost) -> planner returns the canonical '
              '(tribe1, purchaseLand) target. Join Empire is '
              'unavailable here because the overture is at `embassy` '
              'not `nap`.',
        );
      },
    );

    test(
      'embassy + prospected mineral tile + idle Merchant -> purchase_land target',
      () {
        // Same happy path but with an `iron` (mineral) resource. The
        // tile is in the active player's prospected set so the
        // mineral-gate is satisfied; the planner returns the
        // canonical purchase_land target.
        final game = _purchaseLandGame(
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          ],
          newWorldUnits: <Unit>[_merchant('m1')],
          resourceByTileKey: const {_nwTile1: 'iron'},
          prospectedTilesForGp1: const {_nwTile1},
          overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
          diplomacyRelations: <DiplomacyRelation>[
            _peaceFriendly(_gp1, _tribe1),
          ],
        );
        final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
        expect(
          planColonialAcquisition(game: game, snapshot: snapshot),
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.purchaseLand,
          ),
          reason:
              'Mineral resource (`iron`) gated on prospected-tile '
              'membership; with the tile in playerProspectedTiles, '
              'the planner accepts and returns (tribe1, '
              'purchaseLand).',
        );
      },
    );

    test(
      'Join Empire and purchase_land both reachable -> Join Empire wins',
      () {
        // Same `tribe1` is reachable via both paths: overture at
        // `nap` (Join Empire eligible), Friendly+ relation, treasury
        // covering joinEmpire cost AND purchaseLand cost, valid tile
        // and idle Merchant in scope. The Method 1 pass must win;
        // the planner should never even reach the second pass.
        final game = _purchaseLandGame(
          newWorldProvinces: const [
            Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          ],
          newWorldUnits: <Unit>[_merchant('m1')],
          resourceByTileKey: const {_nwTile1: 'grain'},
          overtureStates: <OvertureState>[_nap(_gp1, _tribe1)],
          diplomacyRelations: <DiplomacyRelation>[
            _peaceFriendly(_gp1, _tribe1),
          ],
        );
        final snapshot = _purchaseLandSnapshot(invadableNw: const [_nwProv1]);
        expect(
          planColonialAcquisition(game: game, snapshot: snapshot),
          const ColonialAcquisitionTarget(
            targetFactionId: _tribe1,
            method: AcquisitionMethod.joinEmpire,
          ),
          reason:
              'Join Empire is "the cheapest, fastest path — always '
              'preferred first" per the spec; when Method 1 is '
              'reachable the second pass is suppressed.',
        );
      },
    );

    test('Join Empire treasury shortfall + purchase_land treasury OK -> '
        'purchase_land target', () {
      // Active player has Join-Empire-eligible overture / relation
      // state for `tribe1`, but treasury is below
      // joinEmpireBaseCost (5000) + 1 * joinEmpirePerProvinceCost
      // (2000) = 7000. Treasury is still well above
      // purchaseLandCost('grain') (150), so the second pass
      // accepts. Pins that:
      //   - the second pass actually runs after Method 1 fails;
      //   - the Method 2 gates differ from Method 1's (e.g. no
      //     `nap` requirement; embassy is enough).
      final game = _purchaseLandGame(
        activePlayerTreasury: 1000,
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[_nap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_peaceFriendly(_gp1, _tribe1)],
      );
      final snapshot = _purchaseLandSnapshot(
        invadableNw: const [_nwProv1],
        treasury: 1000,
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
        reason:
            'Method 1 fails the joinEmpire treasury gate (1000 < '
            '7000); Method 2 accepts because purchaseLandCost("grain") '
            '(150) is well within treasury and the embassy gate is '
            'satisfied by stage `nap` (hasEmbassy = true).',
      );
    });

    test('two valid tribe targets -> first sorted invadable NW wins', () {
      // Both tribe1 and tribe2 satisfy every purchase_land gate
      // (embassy, peace, valid grain tile, no purchasedTiles
      // collision). The planner picks the tribe whose NW province
      // appears first in `invadableNewWorldProvinceIdsSorted`
      // (ascending). With `_nwProv1 = newWorld|tribe1_a` <
      // `_nwProv2 = newWorld|tribe2_b` the iteration hits tribe1
      // first.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain', _nwTile2: 'grain'},
        overtureStates: <OvertureState>[
          _embassy(_gp1, _tribe1),
          _embassy(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          _peaceFriendly(_gp1, _tribe1),
          _peaceFriendly(_gp1, _tribe2),
        ],
      );
      final snapshot = _purchaseLandSnapshot(
        invadableNw: const [_nwProv1, _nwProv2],
      );
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
        reason:
            'Iteration over `invadableNewWorldProvinceIdsSorted` is '
            'ascending; the first satisfying province (tribe1) wins '
            'the deterministic tie-break (Refs #2509 Must-have #7).',
      );
    });

    test('determinism: identical inputs produce identical targets', () {
      // Must-have #7 pin: repeated calls on the same game / snapshot
      // must return byte-identical results. Mixed fixture exercises
      // the at-war filter (tribe2 atWar), the embassy gate (tribe1
      // embassy), the alt-tile selection (`_nwTile1Alt` carrying
      // `grain` while `_nwTile1` lacks any resource entry), and the
      // sorted iteration over invadable NW provinces.
      final game = _purchaseLandGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1Alt: 'grain', _nwTile2: 'grain'},
        overtureStates: <OvertureState>[
          _embassy(_gp1, _tribe1),
          _embassy(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          _peaceFriendly(_gp1, _tribe1),
          _atWar(_gp1, _tribe2),
        ],
      );
      final snapshot = _purchaseLandSnapshot(
        invadableNw: const [_nwProv1, _nwProv2],
      );
      final first = planColonialAcquisition(game: game, snapshot: snapshot);
      final second = planColonialAcquisition(game: game, snapshot: snapshot);
      expect(second, first);
      expect(
        first,
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
        reason:
            'Determinism test must run on a satisfying input. tribe1 '
            'wins because tribe2 is at war (excluded) and tribe1 has '
            'a valid grain tile in `_nwTile1Alt`.',
      );
    });
  });
}
