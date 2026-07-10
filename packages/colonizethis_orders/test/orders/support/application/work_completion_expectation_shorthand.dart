// Compact work-completion expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/orders_application_completed_work.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_test/test.dart';
import 'work_application_fixtures.dart';

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
}) => applyBuildAndWorkOrders(
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

void wccExpectRoadLevel(Game next, String tileKey, int level) {
  expect(next.worldState.tileState.roadLevel(tileKey), level);
}

void wccExpectVisibility(
  Game next,
  String tileKey,
  String level, {
  String playerId = 'p1',
}) {
  expect(next.worldState.playerVisibilityByTile[playerId]?[tileKey], level);
}

Game wccRailGame({
  required int roadLevel,
  List<Player>? players,
  int turnNumber = 0,
  bool working = true,
}) {
  final unit = working
      ? workAppWorkingUnit(
          type: kUnitTypeRailBuilder,
          workTarget: kWorkTargetBuildRail,
        )
      : workAppUnit(type: kUnitTypeRailBuilder, status: UnitStatus.working);
  return workAppOwnedGame(
    turnNumber: turnNumber,
    units: [unit],
    tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, roadLevel),
    players:
        players ??
        [
          workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
        ],
  );
}

(BuildWorkState, Unit, CurrentWork) wccDispatchRailSetup({
  required int roadLevel,
  List<Player>? players,
}) {
  final unit = workAppUnit(
    type: kUnitTypeRailBuilder,
    status: UnitStatus.working,
  );
  final tileState = TileMapState().setRoadLevel(WorkAppIds.tileKey, roadLevel);
  final game = workAppOwnedGame(
    turnNumber: 1,
    units: [unit],
    tileState: tileState,
    players:
        players ??
        [
          workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
        ],
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
}) => dispatchCompletedWorkTarget(
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

Game wccEngineerCompletionGame({
  required String workTarget,
  TileMapState? tileState,
  List<Province>? provinces,
  List<Player>? players,
  Map<String, String>? portsByProvinceSeaboard,
}) => workAppOwnedGame(
  units: [workAppWorkingUnit(type: kUnitTypeEngineer, workTarget: workTarget)],
  tileState: tileState,
  provinces: provinces,
  players: players,
  portsByProvinceSeaboard: portsByProvinceSeaboard,
);

void wccExpectBuildImprovementCompletesToLevel(
  int toLevel, {
  int fromLevel = 0,
  Map<String, String>? resourceByTileKey,
  int turnNumber = 0,
  String ownerId = 'p1',
  List<Player>? players,
  Map<String, bool>? aiControlByGpId,
  String? lastHumanCompletedResearchCategory,
  int? lastHumanResearchCategoryCompletionTurn,
}) {
  final next = wccApply(
    workAppOwnedGame(
      turnNumber: turnNumber,
      units: [wccBuilderImprovement(ownerId: ownerId)],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, fromLevel),
      resourceByTileKey: resourceByTileKey,
      provinces: ownerId != 'p1'
          ? [workAppOwnedProvince(ownerId: ownerId)]
          : null,
      players: players,
      aiControlByGpId: aiControlByGpId,
      lastHumanCompletedResearchCategory: lastHumanCompletedResearchCategory,
      lastHumanResearchCategoryCompletionTurn:
          lastHumanResearchCategoryCompletionTurn,
    ),
  );
  wccExpectImprovement(next, toLevel);
  final after = wccSingleUnit(next);
  expect(after.tileKey, WorkAppIds.tileKey);
  expect(after.originTileKey, isNull);
  expect(after.assignedTileKey, isNull);
}
