part of 'work_completion_expectation_shorthand.dart';

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
    players: players ??
        [workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true})],
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
    players: players ??
        [workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true})],
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

Game wccEngineerCompletionGame({
  required String workTarget,
  TileMapState? tileState,
  List<Province>? provinces,
  List<Player>? players,
  Map<String, String>? portsByProvinceSeaboard,
}) =>
    workAppOwnedGame(
      units: [
        workAppWorkingUnit(type: kUnitTypeEngineer, workTarget: workTarget),
      ],
      tileState: tileState,
      provinces: provinces,
      players: players,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
    );

(BuildWorkState, Unit, CurrentWork) wccDispatchUpgradeTownSetup() {
  final upgradeUnit =
      workAppUnit(type: kUnitTypeBuilder, status: UnitStatus.working);
  final upgradeProvince = Province(
    id: WorkAppIds.provinceId,
    regionId: WorkAppIds.ow,
    ownerId: 'p1',
    townDevelopmentLevel: 0,
  );
  final upgradeGame = workAppOwnedGame(
    turnNumber: 1,
    units: [upgradeUnit],
    provinces: [upgradeProvince],
  );
  const upgradeCw = CurrentWork(
    workTarget: kWorkTargetUpgradeTown,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );
  return wccDispatchWorkSetup(
    unit: upgradeUnit,
    game: upgradeGame,
    cw: upgradeCw,
    oldProvinces: [upgradeProvince],
  );
}

(BuildWorkState, Unit, CurrentWork) wccDispatchExploreSetup() {
  final exploreUnit =
      workAppUnit(type: kUnitTypeExplorer, status: UnitStatus.working);
  final exploreGame = workAppOwnedGame(
    turnNumber: 1,
    units: [exploreUnit],
    provinces: const [],
  );
  const exploreCw = CurrentWork(
    workTarget: kWorkTargetExplore,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );
  return wccDispatchWorkSetup(
    unit: exploreUnit,
    game: exploreGame,
    cw: exploreCw,
    oldProvinces: const [],
  );
}

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
      provinces: ownerId != 'p1' ? [workAppOwnedProvince(ownerId: ownerId)] : null,
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

void wccExpectBuildImprovementEnvyMirrorHint() {
  final next = wccApply(
    workAppOwnedGame(
      turnNumber: 2,
      units: [wccBuilderImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
  );
  expect(next.lastHumanCompletedResearchCategory, 'gathering');
  expect(next.lastHumanResearchCategoryCompletionTurn, 2);
}

void wccExpectBuildImprovementEnvyEvidenceForAi() {
  const aiId = 'ai1';
  final next = wccApply(
    workAppOwnedGame(
      turnNumber: 1,
      units: [wccBuilderImprovement(ownerId: aiId)],
      provinces: [workAppOwnedProvince(ownerId: aiId)],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      resourceByTileKey: const {WorkAppIds.tileKey: 'coal'},
      players: const [
        Player(id: 'human', displayName: 'H', isHuman: true),
        Player(id: aiId, displayName: 'AI', isHuman: false),
      ],
      aiControlByGpId: const {aiId: true},
      lastHumanCompletedResearchCategory: 'gathering',
      lastHumanResearchCategoryCompletionTurn: 0,
    ),
  );
  final envy = next.dossierEvidenceEntries
      .where((e) => e.agendaType == 'envy')
      .toList();
  expect(envy, isNotEmpty);
  expect(envy.single.subjectId, aiId);
  expect(envy.single.scoreDelta, 1);
}

void wccExpectBuildImprovementTechCap1291Unchanged() {
  expect(
    extractionCapForResourceForUnlocked(const {kTechIdSawMill: true}, 'grain'),
    1,
  );
  wccExpectBuildImprovementCompletesToLevel(
    4,
    fromLevel: 3,
    resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    players: [workAppPlayer(techUnlocked: const {kTechIdSawMill: true})],
  );
}
