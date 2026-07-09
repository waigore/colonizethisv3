// Compact work-completion expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/orders_application_completed_work.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_test/test.dart';

import 'work_application_fixtures.dart';

Game wccGame({
  required List<Unit> units,
  TileMapState? tileState,
  List<Province>? provinces,
  List<Player>? players,
  Map<String, String>? resourceByTileKey,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  Map<String, Map<String, String>>? playerVisibilityByTile,
  Map<String, String>? portsByProvinceSeaboard,
  int turnNumber = 0,
  Map<String, bool>? aiControlByGpId,
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
}) {
  return workAppOwnedGame(
    units: units,
    provinces: provinces,
    players: players,
    tileState: tileState,
    resourceByTileKey: resourceByTileKey,
    tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    playerVisibilityByTile: playerVisibilityByTile,
    portsByProvinceSeaboard: portsByProvinceSeaboard,
    turnNumber: turnNumber,
    aiControlByGpId: aiControlByGpId,
    lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory,
    lastHumanResearchCategoryCompletionTurn:
        lastHumanResearchCategoryCompletionTurn,
  );
}

Unit wccBuilderImprovement({
  String ownerId = 'p1',
  int totalTurns = 1,
  int remainingTurns = 1,
  bool withOriginAssignment = true,
}) {
  return workAppWorkingUnit(
    type: kUnitTypeBuilder,
    workTarget: kWorkTargetBuildImprovement,
    ownerId: ownerId,
    totalTurns: totalTurns,
    remainingTurns: remainingTurns,
    originTileKey: withOriginAssignment ? WorkAppIds.originTileKey : null,
    assignedTileKey: withOriginAssignment ? WorkAppIds.tileKey : null,
  );
}

Game wccApply(
  Game game, {
  Map<String, TileMapResult>? tileMapByRegion,
  MapTopology? topology,
}) =>
    applyBuildAndWorkOrders(
      game,
      workAppProcessWorkOrders(),
      tileMapByRegion: tileMapByRegion,
      topology: topology,
    );

Unit wccSingleUnit(Game game) => game.worldState.oldWorld.units.single;

void wccExpectImprovement(
  Game next,
  int level, {
  String tileKey = WorkAppIds.tileKey,
}) {
  expect(next.worldState.tileState.improvementLevel(tileKey), level);
}

void wccExpectUnitIdleCleared(
  Game next, {
  String tileKey = WorkAppIds.tileKey,
}) {
  final after = wccSingleUnit(next);
  expect(after.tileKey, tileKey);
  expect(after.originTileKey, isNull);
  expect(after.assignedTileKey, isNull);
}

void wccExpectRoadLevel(Game next, String tileKey, int level) {
  expect(next.worldState.tileState.roadLevel(tileKey), level);
}

void wccExpectRoadLevelOn(TileMapState tileState, String tileKey, int level) {
  expect(tileState.roadLevel(tileKey), level);
}

void wccExpectVisibility(
  Game next,
  String tileKey,
  String level, {
  String playerId = 'p1',
}) {
  expect(next.worldState.playerVisibilityByTile[playerId]?[tileKey], level);
}

void wccExpectFortLevel(Game next, int level) {
  expect(next.worldState.oldWorld.provinces.single.fortLevel, level);
}

void wccExpectEnvyHint(Game next, String category, int turn) {
  expect(next.lastHumanCompletedResearchCategory, category);
  expect(next.lastHumanResearchCategoryCompletionTurn, turn);
}

void wccExpectEnvyEvidence(Game next, String subjectId, int scoreDelta) {
  final envy = next.dossierEvidenceEntries
      .where((e) => e.agendaType == 'envy')
      .toList();
  expect(envy, isNotEmpty);
  expect(envy.single.subjectId, subjectId);
  expect(envy.single.scoreDelta, scoreDelta);
}

Game wccRailGame({
  required int roadLevel,
  required List<Player> players,
  int turnNumber = 0,
  bool working = true,
}) {
  final unit = working
      ? workAppWorkingUnit(
          type: kUnitTypeRailBuilder,
          workTarget: kWorkTargetBuildRail,
        )
      : workAppUnit(type: kUnitTypeRailBuilder, status: UnitStatus.working);
  return wccGame(
    turnNumber: turnNumber,
    units: [unit],
    tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, roadLevel),
    players: players,
  );
}

MapTopology wccPortSeaTopology() {
  return const MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: WorkAppIds.ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea1',
        regionId: WorkAppIds.ow,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: 'P1', id2: 'sea1')],
  );
}

(BuildWorkState, Unit, CurrentWork) wccDispatchRailSetup({
  required int roadLevel,
  required List<Player> players,
}) {
  final unit = workAppUnit(
    type: kUnitTypeRailBuilder,
    status: UnitStatus.working,
  );
  final tileState = TileMapState().setRoadLevel(WorkAppIds.tileKey, roadLevel);
  final game = wccGame(
    turnNumber: 1,
    units: [unit],
    tileState: tileState,
    players: players,
  );
  final work = WorkOrderState(
    unitsById: (oldWorld: {unit.id: unit}, newWorld: const {}),
    tileState: tileState,
    visibilityByTile: const {},
    portsByProvinceSeaboard: const {},
    purchasedTilesByTileKey: const {},
    oldProvinces: game.worldState.oldWorld.provinces,
    newProvinces: const [],
  );
  final state = BuildWorkState(
    game: game,
    buildOrders: const {},
    workOrders: const {},
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
    work: work,
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetBuildRail,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );
  return (state, unit, cw);
}

BuildWorkState wccDispatchCompleted(
  BuildWorkState state,
  Unit unit,
  CurrentWork cw, {
  BuildWorkState Function(BuildWorkState, Unit, String)? onExploreRegion,
}) =>
    dispatchCompletedWorkTarget(
      state,
      unit,
      cw,
      () => state.game.worldState.oldWorld.provinces,
      (w, p) => w.copyWith(oldProvinces: p),
      onExploreRegion ?? (s, u, regionId) => s,
    );

(BuildWorkState, Unit, CurrentWork) wccDispatchWorkSetup({
  required Unit unit,
  required Game game,
  required CurrentWork cw,
  Map<String, TileMapResult>? tileMapByRegion,
  List<Province>? oldProvinces,
}) {
  final work = WorkOrderState(
    unitsById: (oldWorld: {unit.id: unit}, newWorld: const {}),
    tileState: game.worldState.tileState,
    visibilityByTile: const {},
    portsByProvinceSeaboard: const {},
    purchasedTilesByTileKey: const {},
    oldProvinces: oldProvinces ?? game.worldState.oldWorld.provinces,
    newProvinces: const [],
  );
  final state = BuildWorkState(
    game: game,
    buildOrders: const {},
    workOrders: const {},
    tileMapByRegion: tileMapByRegion ?? const {},
    work: work,
  );
  return (state, unit, cw);
}
