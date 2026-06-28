// Unit tests for the own-colony exclusion in `planColonialAcquisition`
// (`packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`,
// Refs #3758 R4 / S3).
//
// Spec contract (SPEC/ai/phase-planner-architecture.md § Own-colony
// exclusion; SPEC/game/diplomacy.md § GP–Tribe Join Empire → colony):
// after Tribe Join Empire resolves, the Tribe becomes a colony that
// STAYS in the game and keeps owning NW provinces, so those provinces
// remain in `ColonialSummary.invadableNewWorldProvinceIdsSorted`. The
// planner must exclude any NW province whose owner is a Tribe that is
// already the active player's own colony (`colonyOfGpId == playerId`)
// from ALL THREE acquisition arms (joinEmpire, purchase_land,
// declareWar), so the AI never re-targets, re-buys land in, or declares
// war on its own colony. Colonies of a DIFFERENT GP are NOT excluded.
//
// These tests build a per-arm "would otherwise succeed" fixture and
// assert the own-colony filter flips the result to null (negative
// cases), plus a positive control showing a different-GP colony is not
// excluded, and a multi-target case where the own colony is skipped in
// favour of a valid sibling tribe.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'ai_planner_fixtures.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';

const String _nwProv1 = 'newWorld|tribe1_a';
const String _nwProv2 = 'newWorld|tribe2_b';

const String _nwTile1 = 'newWorld|tribe1_a|1|1';

Game _acquisitionGame({
  int turnNumber = 130,
  int activePlayerTreasury = 100000,
  List<Province> newWorldProvinces = const [],
  List<Unit> newWorldUnits = const [],
  List<Army> armies = const [],
  Map<String, String> resourceByTileKey = const {},
  List<OvertureState> overtureStates = const [],
  List<DiplomacyRelation> diplomacyRelations = const [],
  List<ColonyState> colonyStates = const [],
}) {
  return Game(
    id: 'g-3758-colony-filter-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: const RegionData(),
      newWorld: RegionData(provinces: newWorldProvinces, units: newWorldUnits),
      armies: armies,
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
    colonyStates: colonyStates,
  );
}

AIWorldSnapshot _snapshot({
  required List<String> invadableNw,
  int treasury = 100000,
}) {
  return AIWorldSnapshot(
    playerId: _gp1,
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

Unit _merchant(String id, {String provinceId = _nwProv1}) => Unit(
  id: id,
  type: kUnitTypeMerchant,
  ownerId: _gp1,
  locationProvinceId: provinceId,
  tileKey: '$provinceId|5|5',
  status: UnitStatus.idle,
);

ColonyState _ownColony(String tribeId) =>
    ColonyState(tribeId: tribeId, colonyOfGpId: _gp1, sinceTurn: 100);

void main() {
  group('planColonialAcquisition own-colony exclusion (Refs #3758 S3)', () {
    test('Join Empire arm excludes the active player\'s own colony', () {
      // tribe1 satisfies every Join Empire gate (overture at nap,
      // Friendly+ relation, treasury >= cost), so without the colony
      // filter the planner would return (tribe1, joinEmpire). Because
      // tribe1 is already gp1's colony, the planner must skip it and
      // return null (no other candidate exists).
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[_nap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _tribe1)],
        colonyStates: <ColonyState>[_ownColony(_tribe1)],
      );
      final snapshot = _snapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'tribe1 is gp1\'s own colony; the Join Empire arm must skip '
            'it even though all four gates otherwise pass.',
      );
    });

    test('purchase_land arm excludes the active player\'s own colony', () {
      // tribe1 satisfies the purchase_land gates (idle Merchant,
      // embassy, peace, valid grain tile). Overture is at `embassy`
      // (not `nap`) so the Join Empire arm is unavailable. Without the
      // colony filter the planner would return (tribe1, purchaseLand);
      // the own-colony exclusion flips it to null.
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        newWorldUnits: <Unit>[_merchant('m1')],
        resourceByTileKey: const {_nwTile1: 'grain'},
        overtureStates: <OvertureState>[_embassy(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _tribe1)],
        colonyStates: <ColonyState>[_ownColony(_tribe1)],
      );
      final snapshot = _snapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'tribe1 is gp1\'s own colony; the purchase_land arm must '
            'skip it even though Merchant/embassy/tile gates pass.',
      );
    });

    test('declareWar arm excludes the active player\'s own colony', () {
      // tribe1 satisfies the declareWar gates (standing regiment,
      // treasury, at peace) and has no overture (so Join Empire and
      // purchase_land are unavailable). Without the colony filter the
      // planner would return (tribe1, declareWar); the own-colony
      // exclusion flips it to null — a GP must not conquer its own
      // colony.
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        armies: <Army>[homeArmyWithRegimentsAtCapital(_gp1, 5)],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _tribe1)],
        colonyStates: <ColonyState>[_ownColony(_tribe1)],
      );
      final snapshot = _snapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        isNull,
        reason:
            'tribe1 is gp1\'s own colony; the declareWar arm must skip '
            'it even though regiments + treasury + peace gates pass.',
      );
    });

    test('a colony of a DIFFERENT GP is not excluded (Join Empire wins)', () {
      // tribe1 owns the NW province and a colony record exists, but it
      // belongs to gp2 (a different GP). The own-colony filter applies
      // only to gp1's own colonies, so tribe1 stays eligible and the
      // Join Empire arm returns (tribe1, joinEmpire). Re-resolution
      // replaces the prior record per SPEC/game/diplomacy.md.
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
        ],
        overtureStates: <OvertureState>[_nap(_gp1, _tribe1)],
        diplomacyRelations: <DiplomacyRelation>[_friendly(_gp1, _tribe1)],
        colonyStates: <ColonyState>[
          ColonyState(tribeId: _tribe1, colonyOfGpId: _gp2, sinceTurn: 100),
        ],
      );
      final snapshot = _snapshot(invadableNw: const [_nwProv1]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe1,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'tribe1 is a colony of gp2, not gp1; the own-colony filter '
            'must not exclude another GP\'s colony.',
      );
    });

    test('own colony is skipped in favour of a valid sibling tribe', () {
      // tribe1 (gp1\'s colony) sorts first in the invadable list but is
      // excluded; tribe2 satisfies the Join Empire gates and is not a
      // colony, so the planner falls through to (tribe2, joinEmpire).
      final game = _acquisitionGame(
        newWorldProvinces: const [
          Province(id: _nwProv1, regionId: 'newWorld', ownerId: _tribe1),
          Province(id: _nwProv2, regionId: 'newWorld', ownerId: _tribe2),
        ],
        overtureStates: <OvertureState>[
          _nap(_gp1, _tribe1),
          _nap(_gp1, _tribe2),
        ],
        diplomacyRelations: <DiplomacyRelation>[
          _friendly(_gp1, _tribe1),
          _friendly(_gp1, _tribe2),
        ],
        colonyStates: <ColonyState>[_ownColony(_tribe1)],
      );
      final snapshot = _snapshot(invadableNw: const [_nwProv1, _nwProv2]);
      expect(
        planColonialAcquisition(game: game, snapshot: snapshot),
        const ColonialAcquisitionTarget(
          targetFactionId: _tribe2,
          method: AcquisitionMethod.joinEmpire,
        ),
        reason:
            'The first-sorted province is owned by gp1\'s own colony '
            '(excluded); the planner falls through to the next valid '
            'tribe (tribe2).',
      );
    });
  });
}
