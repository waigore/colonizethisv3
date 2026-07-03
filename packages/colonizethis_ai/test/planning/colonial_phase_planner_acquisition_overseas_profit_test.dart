// Unit tests for the overseas-profit-aware target selection in the
// `purchase_land` arm of `planColonialAcquisition`
// (`packages/colonizethis_ai/lib/src/planning/colonial_phase_planner_acquisition.dart`,
// Refs #3758 R7 / S6).
//
// Spec contract (SPEC/ai/phase-planner-architecture.md § Overseas-
// profit-aware purchase-land target selection; SPEC/game/world-market.md
// § Overseas profit): buying land on a tribe/minor tile earns the buyer
// an ongoing overseas profit share `(relationScore / 100) × 0.40`, so a
// higher-relation owner yields a strictly larger share. The
// `purchase_land` arm therefore selects the eligible owner with the
// HIGHEST relation score rather than the first owner in adjacency-
// distance iteration order. Equal relation scores fall back to the
// legacy first-in-iteration-order tiebreak.
//
// These tests build two tribes that BOTH satisfy every `purchase_land`
// gate (idle Merchant, embassy overture, peace, valid grain tile) and
// vary only the relation score and the iteration order, isolating the
// new selection lever from the unchanged gate logic.

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

const String _nwTile1 = 'newWorld|tribe1_a|1|1';
const String _nwTile2 = 'newWorld|tribe2_b|1|1';

Game _purchaseLandGame({
  int turnNumber = 130,
  int activePlayerTreasury = 100000,
  List<Province> newWorldProvinces = const [],
  List<Unit> newWorldUnits = const [],
  Map<String, String> resourceByTileKey = const {},
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
}) {
  return Game(
    id: 'g-3758-overseas-profit-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      resourceByTileKey: resourceByTileKey,
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

AIWorldSnapshot _snapshot({required List<String> invadableNw}) {
  return AIWorldSnapshot(
    playerId: _gp1,
    threats: const ThreatSummary(),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 10,
      provincesToVictory: 31,
    ),
    colonial: ColonialSummary(invadableNewWorldProvinceIdsSorted: invadableNw),
    economy: const EconomySummary(treasury: 100000),
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

DiplomacyRelation _peaceFriendly(String a, String b, {required num score}) =>
    DiplomacyRelation(
      factionId1: a,
      factionId2: b,
      score: score,
      level: RelationLevel.friendly,
    );

Unit _merchant(String id, {String provinceId = _nwProv1}) => Unit(
  id: id,
  type: kUnitTypeMerchant,
  ownerId: _gp1,
  locationProvinceId: provinceId,
  tileKey: '$provinceId|5|5',
  status: UnitStatus.idle,
);

void main() {
  group('planColonialAcquisition purchase_land overseas-profit selection '
      '(Refs #3758 S6)', () {
    test('higher-relation owner is preferred over a closer lower-relation '
        'owner', () {
      // Both tribes satisfy every purchase_land gate. tribe2 sorts FIRST
      // (its province leads the invadable list) but has a low relation
      // (40.0); tribe1 sorts second but has a high relation (90.0).
      // Overseas profit scales with relation, so the planner must pick
      // tribe1 even though tribe2 is encountered first.
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
          _peaceFriendly(_gp1, _tribe1, score: 90.0),
          _peaceFriendly(_gp1, _tribe2, score: 40.0),
        ],
      );
      // tribe2 first in iteration order, tribe1 second.
      final snapshot = _snapshot(invadableNw: const [_nwProv2, _nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
        reason:
            'tribe1 (relation 90.0) yields a larger overseas profit share '
            'than tribe2 (relation 40.0), so the purchase_land arm prefers '
            'tribe1 even though tribe2 is iterated first.',
      );
    });

    test('equal relation scores fall back to the first-in-iteration-order '
        'owner', () {
      // Both tribes satisfy every gate with EQUAL relation (60.0). The
      // overseas-profit tiebreak is a strict `>` so the earliest-iterated
      // owner wins, preserving the legacy first-match selection. tribe1's
      // province leads the invadable list.
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
          _peaceFriendly(_gp1, _tribe1, score: 60.0),
          _peaceFriendly(_gp1, _tribe2, score: 60.0),
        ],
      );
      final snapshot = _snapshot(invadableNw: const [_nwProv1, _nwProv2]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
        reason:
            'Equal relation scores (60.0 vs 60.0) fall back to the legacy '
            'first-in-iteration-order tiebreak; tribe1 leads the invadable '
            'list so it wins.',
      );
    });

    test('determinism: identical inputs produce identical targets', () {
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
          _peaceFriendly(_gp1, _tribe1, score: 90.0),
          _peaceFriendly(_gp1, _tribe2, score: 40.0),
        ],
      );
      final snapshot = _snapshot(invadableNw: const [_nwProv2, _nwProv1]);
      final first = planColonialAcquisition(game: game, snapshot: snapshot);
      final second = planColonialAcquisition(game: game, snapshot: snapshot);
      expect(second, first);
      expect(
        first,
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.purchaseLand,
        ),
      );
    });
  });
}
