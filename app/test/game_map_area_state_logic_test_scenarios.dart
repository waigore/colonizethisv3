// State-logic scenario fixtures for `game_map_area_state_logic_part*_test.dart`
// (Refs #4183 Slice E). Lives outside `app/test/support/` so scenario tables do
// not count toward the support LOC ratchet.
// SPEC: SPEC/program/repo-lint.md § Stay-split families.

import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show kWorkTargetProspect;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter_test/flutter_test.dart';

const kStateLogicHumanPlayerId = 'gp1';
const kStateLogicExplorerId = 'u_explorer';

RegionMapViewData stateLogicBaseRegion(
  String regionId, {
  List<CivilianTileMarkerView> markers = const [],
  List<CellViewData>? cells,
}) {
  return RegionMapViewData(
    regionId: regionId,
    width: 2,
    height: 1,
    cellSize: 16,
    cells:
        cells ??
        const [
          CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false),
          CellViewData(x: 1, y: 0, regionCellId: 'p1', isSea: false),
        ],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {},
    unitMarkers: const [],
    civilianTileMarkers: markers,
  );
}

CivilianTileMarkerView stateLogicCivilianMarker({
  required String tileKey,
  required String unitId,
  required String unitType,
  int x = 0,
  int y = 0,
  String localProvinceId = 'p1',
}) {
  return CivilianTileMarkerView(
    tileKey: tileKey,
    x: x,
    y: y,
    localProvinceId: localProvinceId,
    unitIds: [unitId],
    unitTypes: {unitId: unitType},
    representativeUnitType: unitType,
    stackCount: 1,
    representativeIsAssigned: false,
  );
}

ct_models.Province stateLogicProv(String regionId, String localId) =>
    ct_models.Province(id: '$regionId|$localId', regionId: regionId);

ct_models.Unit stateLogicUnit({
  required String id,
  required String type,
  required String provinceId,
  required String tileKey,
  String ownerId = kStateLogicHumanPlayerId,
}) => ct_models.Unit(
  id: id,
  type: type,
  ownerId: ownerId,
  locationProvinceId: provinceId,
  tileKey: tileKey,
  status: ct_models.UnitStatus.idle,
);

ct_models.WorkOrder stateLogicWorkOrder({
  required String unitId,
  required String target,
  required String targetTileKey,
}) => ct_models.WorkOrder(
  unitId: unitId,
  target: target,
  targetTileKey: targetTileKey,
);

ct_models.Game stateLogicHumanGame({
  ct_models.RegionData? oldWorld,
  ct_models.RegionData? newWorld,
  Map<String, Map<String, String>>? playerVisibilityByTile,
}) {
  return ct_models.Game(
    id: 'g',
    worldState: ct_models.WorldState(
      turnState: const ct_models.TurnState(
        phase: ct_models.TurnPhase.orders,
        turnNumber: 1,
      ),
      oldWorld: oldWorld ?? const ct_models.RegionData(provinces: [], units: []),
      newWorld: newWorld ?? const ct_models.RegionData(provinces: [], units: []),
      playerVisibilityByTile: playerVisibilityByTile ?? const {},
    ),
    players: const [
      ct_models.Player(
        id: kStateLogicHumanPlayerId,
        displayName: 'Human',
        isHuman: true,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}

ct_models.Game stateLogicGameExplorerOldToNew({required String sourceTile}) {
  return stateLogicHumanGame(
    oldWorld: ct_models.RegionData(
      provinces: [
        stateLogicProv('oldWorld', 'p1'),
        stateLogicProv('oldWorld', 'pA'),
      ],
      units: [
        stateLogicUnit(
          id: kStateLogicExplorerId,
          type: ct_models.kUnitTypeExplorer,
          provinceId: 'oldWorld|p1',
          tileKey: sourceTile,
        ),
      ],
    ),
    newWorld: ct_models.RegionData(
      provinces: [
        stateLogicProv('newWorld', 'p1'),
        stateLogicProv('newWorld', 'pA'),
        stateLogicProv('newWorld', 'pB'),
      ],
      units: const [],
    ),
  );
}

ct_models.Game stateLogicGameExplorerNewToOld({required String sourceTile}) {
  return stateLogicHumanGame(
    oldWorld: ct_models.RegionData(
      provinces: [stateLogicProv('oldWorld', 'p1')],
      units: const [],
    ),
    newWorld: ct_models.RegionData(
      provinces: [stateLogicProv('newWorld', 'p1')],
      units: [
        stateLogicUnit(
          id: kStateLogicExplorerId,
          type: ct_models.kUnitTypeExplorer,
          provinceId: 'newWorld|p1',
          tileKey: sourceTile,
        ),
      ],
    ),
  );
}

ct_models.Orders stateLogicProspectOrder(String targetTile) => ct_models.Orders(
  workOrdersByPlayerId: {
    kStateLogicHumanPlayerId: [
      stateLogicWorkOrder(
        unitId: kStateLogicExplorerId,
        target: kWorkTargetProspect,
        targetTileKey: targetTile,
      ),
    ],
  },
);

RegionMapViewData stateLogicProjectDraft({
  required RegionMapViewData region,
  required ct_models.Game game,
  required ct_models.Orders orders,
  String humanPlayerId = kStateLogicHumanPlayerId,
}) => GameMapAreaStateLogicDraftProjection.projectCivilianMarkersForHumanDraft(
  region: region,
  game: game,
  orders: orders,
  humanPlayerId: humanPlayerId,
);

RegionMapViewData stateLogicRegionWithExplorerMarker(
  String regionId,
  String sourceTile,
) => stateLogicBaseRegion(
  regionId,
  markers: [
    stateLogicCivilianMarker(
      tileKey: sourceTile,
      unitId: kStateLogicExplorerId,
      unitType: ct_models.kUnitTypeExplorer,
    ),
  ],
);

void expectStateLogicSingleProjectedTile({
  required RegionMapViewData region,
  required ct_models.Game game,
  required ct_models.Orders orders,
  required String tileKey,
}) {
  final projected = stateLogicProjectDraft(
    region: region,
    game: game,
    orders: orders,
  );
  expect(projected.civilianTileMarkers, hasLength(1));
  expect(projected.civilianTileMarkers.single.tileKey, tileKey);
}

void expectStateLogicEmptyProjection({
  required RegionMapViewData region,
  required ct_models.Game game,
  required ct_models.Orders orders,
}) {
  expect(
    stateLogicProjectDraft(region: region, game: game, orders: orders)
        .civilianTileMarkers,
    isEmpty,
  );
}
