part of 'work_completion_expectations.dart';


Game _railCompletionGame({
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
  return _completionGame(
    turnNumber: turnNumber,
    units: [unit],
    tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, roadLevel),
    players: players,
  );
}

void _buildRailCompletionLeavesRoadWhenTileHasNoRoad() {
  final next = applyBuildAndWorkOrders(
    _railCompletionGame(
      roadLevel: 0,
      players: [
        workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
      ],
    ),
    workAppProcessWorkOrders(),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 0);
}

void _buildRailCompletionSetsRoadLevelTo4WhenValid() {
  final next = applyBuildAndWorkOrders(
    _railCompletionGame(
      roadLevel: 1,
      players: [
        workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
      ],
    ),
    workAppProcessWorkOrders(),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 4);
}

(BuildWorkState, Unit, CurrentWork) _dispatchRailSetup({
  required int roadLevel,
  required List<Player> players,
}) {
  final unit = workAppUnit(
    type: kUnitTypeRailBuilder,
    status: UnitStatus.working,
  );
  final tileState = TileMapState().setRoadLevel(WorkAppIds.tileKey, roadLevel);
  final game = _completionGame(
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

void _routesKWorkTargetBuildRailThroughHandlerMapEntry() {
  final (state, unit, cw) = _dispatchRailSetup(
    roadLevel: 1,
    players: [
      workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
    ],
  );
  final next = dispatchCompletedWorkTarget(
    state,
    unit,
    cw,
    () => state.game.worldState.oldWorld.provinces,
    (w, p) => w.copyWith(oldProvinces: p),
    (s, u, regionId) => s,
  );
  expect(next.work.tileState.roadLevel(WorkAppIds.tileKey), 4);
}

void _buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies() {
  final (state, unit, cw) = _dispatchRailSetup(
    roadLevel: 0,
    players: [workAppPlayer()],
  );
  final next = dispatchCompletedWorkTarget(
    state,
    unit,
    cw,
    () => state.game.worldState.oldWorld.provinces,
    (w, p) => w.copyWith(oldProvinces: p),
    (s, u, regionId) => s,
  );
  expect(next.work.tileState.roadLevel(WorkAppIds.tileKey), 0);
}

void
_upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord() {
  final unit = workAppUnit(type: kUnitTypeBuilder, status: UnitStatus.working);
  const province = Province(
    id: WorkAppIds.provinceId,
    regionId: WorkAppIds.ow,
    ownerId: 'p1',
    townDevelopmentLevel: 0,
  );
  final game = _completionGame(
    turnNumber: 1,
    units: [unit],
    provinces: const [province],
  );
  final work = WorkOrderState(
    unitsById: (oldWorld: {unit.id: unit}, newWorld: const {}),
    tileState: TileMapState(),
    visibilityByTile: const {},
    portsByProvinceSeaboard: const {},
    purchasedTilesByTileKey: const {},
    oldProvinces: const [province],
    newProvinces: const [],
  );
  final state = BuildWorkState(
    game: game,
    buildOrders: const {},
    workOrders: const {},
    tileMapByRegion: const {},
    work: work,
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetUpgradeTown,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );

  final next = dispatchCompletedWorkTarget(
    state,
    unit,
    cw,
    () => game.worldState.oldWorld.provinces,
    (w, p) => w.copyWith(oldProvinces: p),
    (s, u, regionId) => s,
  );

  expect(next.work.oldProvinces.single.townDevelopmentLevel, 1);
}

void
_exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord() {
  final unit = workAppUnit(type: kUnitTypeExplorer, status: UnitStatus.working);
  final game = workAppOwnedGame(
    turnNumber: 1,
    units: [unit],
    provinces: const [],
  );
  final work = WorkOrderState(
    unitsById: (oldWorld: {unit.id: unit}, newWorld: const {}),
    tileState: TileMapState(),
    visibilityByTile: const {},
    portsByProvinceSeaboard: const {},
    purchasedTilesByTileKey: const {},
    oldProvinces: const [],
    newProvinces: const [],
  );
  final state = BuildWorkState(
    game: game,
    buildOrders: const {},
    workOrders: const {},
    tileMapByRegion: const {},
    work: work,
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetExplore,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );

  String? capturedRegionId;
  final next = dispatchCompletedWorkTarget(
    state,
    unit,
    cw,
    () => game.worldState.oldWorld.provinces,
    (w, p) => w.copyWith(oldProvinces: p),
    (s, u, regionId) {
      capturedRegionId = regionId;
      return s;
    },
  );

  expect(capturedRegionId, WorkAppIds.ow);
  expect(identical(next, state), isTrue);
}
