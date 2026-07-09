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

Unit wccEngineerWorking(String workTarget) =>
    workAppWorkingUnit(type: kUnitTypeEngineer, workTarget: workTarget);

Unit wccExplorerWorking() =>
    workAppWorkingUnit(type: kUnitTypeExplorer, workTarget: kWorkTargetExplore);

Game wccEngineerCompletionGame({
  required String workTarget,
  TileMapState? tileState,
  List<Province>? provinces,
  List<Player>? players,
  Map<String, String>? portsByProvinceSeaboard,
}) =>
    wccGame(
      units: [wccEngineerWorking(workTarget)],
      tileState: tileState,
      provinces: provinces,
      players: players,
      portsByProvinceSeaboard: portsByProvinceSeaboard,
    );

Game wccBuilderImprovementAtLevel(int level) => wccGame(
      units: [wccBuilderImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, level),
    );

void wccExpectUnitCancelledToOrigin(Game next) {
  final u = wccSingleUnit(next);
  expect(u.status, UnitStatus.idle);
  expect(u.currentWork, isNull);
  expect(u.tileKey, WorkAppIds.originTileKey);
  expect(u.originTileKey, isNull);
  expect(u.assignedTileKey, isNull);
}

void wccExpectRemainingTurns(Game next, int remaining) {
  expect(wccSingleUnit(next).currentWork!.remainingTurns, remaining);
}

void wccExpectPortRegisteredForProvince(Game next) {
  expect(
    next.worldState.portsByProvinceSeaboard.keys.any(
      (k) => k.startsWith(WorkAppIds.provinceId),
    ),
    isTrue,
  );
}

Game wccBuildRoadCapitalAdjacentGame() {
  const capitalTileKey = WorkAppIds.originTileKey;
  return wccEngineerCompletionGame(
    workTarget: kWorkTargetBuildRoad,
    tileState: TileMapState()
        .setRoadLevel(WorkAppIds.tileKey, 0)
        .setRoadLevel(capitalTileKey, 2),
    players: [
      workAppPlayer(
        capitalProvinceId: WorkAppIds.provinceId,
        capitalTile: const CapitalTile(
          regionId: WorkAppIds.ow,
          provinceId: WorkAppIds.provinceId,
          x: 1,
          y: 0,
        ),
      ),
    ],
  );
}

Game wccBuildRoadPortAdjacentGame() {
  const portTileKey = WorkAppIds.originTileKey;
  return wccEngineerCompletionGame(
    workTarget: kWorkTargetBuildRoad,
    tileState: TileMapState()
        .setRoadLevel(WorkAppIds.tileKey, 1)
        .setRoadLevel(portTileKey, 1),
    portsByProvinceSeaboard: const {
      '${WorkAppIds.provinceId}|sea1': portTileKey,
    },
    players: [
      workAppPlayer(techUnlocked: const {kTechIdRoadConstruction: true}),
    ],
  );
}

List<Player> wccSteamPlayers() => [
      workAppPlayer(techUnlocked: const {kTechIdEarlySteamEngine: true}),
    ];

void wccExpectRailCompletionLeavesRoadWhenTileHasNoRoad() {
  final next = wccApply(
    wccRailGame(roadLevel: 0, players: wccSteamPlayers()),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 0);
}

void wccExpectRailCompletionSetsRoadLevelTo4WhenValid() {
  final next = wccApply(
    wccRailGame(roadLevel: 1, players: wccSteamPlayers()),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
}

void wccExpectRailDispatchSetsRoadLevel({
  required int roadLevel,
  required List<Player> players,
  required int expectedLevel,
}) {
  final (state, unit, cw) = wccDispatchRailSetup(
    roadLevel: roadLevel,
    players: players,
  );
  final next = wccDispatchCompleted(state, unit, cw);
  wccExpectRoadLevelOn(next.work.tileState, WorkAppIds.tileKey, expectedLevel);
}

void wccExpectUpgradeTownProvinceLevel({int before = 0, int after = 1}) {
  final unit = workAppUnit(type: kUnitTypeBuilder, status: UnitStatus.working);
  final province = Province(
    id: WorkAppIds.provinceId,
    regionId: WorkAppIds.ow,
    ownerId: 'p1',
    townDevelopmentLevel: before,
  );
  final game = wccGame(
    turnNumber: 1,
    units: [unit],
    provinces: [province],
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetUpgradeTown,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );
  final (state, u, work) = wccDispatchWorkSetup(
    unit: unit,
    game: game,
    cw: cw,
    oldProvinces: [province],
  );
  final next = wccDispatchCompleted(state, u, work);
  expect(next.work.oldProvinces.single.townDevelopmentLevel, after);
}

void wccExpectExploreDispatchCapturesRegion({
  String expectedRegion = WorkAppIds.ow,
}) {
  final unit = workAppUnit(type: kUnitTypeExplorer, status: UnitStatus.working);
  final game = workAppOwnedGame(
    turnNumber: 1,
    units: [unit],
    provinces: const [],
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetExplore,
    tileKey: WorkAppIds.tileKey,
    totalTurns: 1,
    remainingTurns: 0,
  );
  final (state, u, work) = wccDispatchWorkSetup(
    unit: unit,
    game: game,
    cw: cw,
    oldProvinces: const [],
  );
  String? capturedRegionId;
  final next = wccDispatchCompleted(
    state,
    u,
    work,
    onExploreRegion: (s, unit, regionId) {
      capturedRegionId = regionId;
      return s;
    },
  );
  expect(capturedRegionId, expectedRegion);
  expect(identical(next, state), isTrue);
}

void wccExpectImprovementWithEnvyHint() {
  final next = wccApply(
    wccGame(
      turnNumber: 2,
      units: [wccBuilderImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
  );
  wccExpectEnvyHint(next, 'gathering', 2);
}

void wccExpectAiEnvyEvidenceOnCoalCompletion() {
  const aiId = 'ai1';
  final next = wccApply(
    wccGame(
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
  wccExpectEnvyEvidence(next, aiId, 1);
}

void wccExpectSawMillCapStillAllowsLevel4() {
  expect(
    extractionCapForResourceForUnlocked(const {kTechIdSawMill: true}, 'grain'),
    1,
  );
  final next = wccApply(
    wccGame(
      units: [wccBuilderImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 3),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
      players: [
        workAppPlayer(techUnlocked: const {kTechIdSawMill: true}),
      ],
    ),
  );
  wccExpectImprovement(next, 4);
}

void wccExpectConqueredProvinceCancelsWork() {
  final next = wccApply(
    wccGame(
      units: [
        wccBuilderImprovement(totalTurns: 2, remainingTurns: 2),
      ],
      provinces: [workAppOwnedProvince(ownerId: 'p2')],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
    ),
  );
  wccExpectUnitCancelledToOrigin(next);
  wccExpectImprovement(next, 0);
}

void wccExpectTwoTurnImprovementCompletesOnSecondApply() {
  final game = wccGame(
    units: [
      wccBuilderImprovement(
        totalTurns: 2,
        remainingTurns: 2,
        withOriginAssignment: false,
      ),
    ],
    tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
  );
  final afterFirst = wccApply(game);
  wccExpectImprovement(afterFirst, 0);
  wccExpectRemainingTurns(afterFirst, 1);
  final afterSecond = wccApply(afterFirst);
  wccExpectImprovement(afterSecond, 1);
}

void wccExpectExploreSetsVisibility() {
  final next = wccApply(
    wccGame(
      units: [wccExplorerWorking()],
      tileKeysByRegionAndProvince: {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey],
        },
      },
    ),
  );
  wccExpectVisibility(
    next,
    WorkAppIds.tileKey,
    VisibilityLevel.fullyVisible.name,
  );
}

void wccExpectBasicImprovementCompletion() {
  final next = wccApply(wccBuilderImprovementAtLevel(0));
  wccExpectImprovement(next, 1);
  wccExpectUnitIdleCleared(next);
}

void wccExpectImprovementCapsAtLevel4() {
  final next = wccApply(
    wccGame(
      units: [wccBuilderImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 3),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
  );
  wccExpectImprovement(next, 4);
}

void wccExpectBuildRoadLevelIncrease() {
  final next = wccApply(
    wccEngineerCompletionGame(
      workTarget: kWorkTargetBuildRoad,
      tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, 0),
    ),
    tileMapByRegion: const {},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
}

void wccExpectBuildRoadCapitalAdjacentPropagation() {
  const capitalTileKey = WorkAppIds.originTileKey;
  final next = wccApply(
    wccBuildRoadCapitalAdjacentGame(),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
  wccExpectRoadLevel(next, capitalTileKey, 2);
}

void wccExpectBuildRoadPortAdjacentPropagation() {
  const portTileKey = WorkAppIds.originTileKey;
  final next = wccApply(
    wccBuildRoadPortAdjacentGame(),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 2);
  wccExpectRoadLevel(next, portTileKey, 2);
}

void wccExpectBuildPortCompletion() {
  final next = wccApply(
    wccEngineerCompletionGame(workTarget: kWorkTargetBuildPort),
    topology: wccPortSeaTopology(),
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
  wccExpectPortRegisteredForProvince(next);
}

void wccExpectBuildFortCompletion() {
  final next = wccApply(
    wccEngineerCompletionGame(
      workTarget: kWorkTargetBuildFort,
      provinces: [workAppOwnedProvince(fortLevel: 0)],
    ),
  );
  wccExpectFortLevel(next, 1);
}

void wccExpectExploreRevealsBucketOnly() {
  const tileKey2 = WorkAppIds.originTileKey;
  final next = wccApply(
    wccGame(
      units: [wccExplorerWorking()],
      tileKeysByRegionAndProvince: const {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey, tileKey2],
          'P1': ['oldWorld|P1|9|9'],
        },
      },
      playerVisibilityByTile: const {
        'p1': {
          WorkAppIds.tileKey: 'fogged',
          tileKey2: 'unknown',
          'oldWorld|P1|9|9': 'unknown',
        },
      },
    ),
  );
  wccExpectVisibility(
    next,
    WorkAppIds.tileKey,
    VisibilityLevel.fullyVisible.name,
  );
  wccExpectVisibility(
    next,
    tileKey2,
    VisibilityLevel.fullyVisible.name,
  );
  wccExpectVisibility(
    next,
    'oldWorld|P1|9|9',
    VisibilityLevel.unknown.name,
  );
}
