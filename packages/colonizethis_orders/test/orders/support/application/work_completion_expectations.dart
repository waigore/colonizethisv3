// Compact applyBuildAndWorkOrders work-completion assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/orders_application_completed_work.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_test/test.dart';

import 'work_application_fixtures.dart';

/// Pins for [workCompletionScenarios] rows.
enum WorkCompletionTarget {
  buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork,
  buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile,
  buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint,
  buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax,
  buildImprovementCompletionDoesNotReApplyExtractionTechCap1291,
  workCancelledWhenProvinceContainingTargetTileIsConquered376,
  multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero,
  exploreCompletionSetsVisibilityAndClearsCurrentWork,
  exploreCompletionRevealsEveryTileInCanonicalFullIdBucket,
  buildRoadCompletionIncreasesRoadLevel,
  buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade,
  buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt,
  buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea,
  buildFortCompletionIncreasesProvinceFortLevel,
  buildRailCompletionLeavesRoadWhenTileHasNoRoad,
  buildRailCompletionSetsRoadLevelTo4WhenValid,
  routesKWorkTargetBuildRailThroughHandlerMapEntry,
  buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies,
  upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord,
  exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord,
}

void runWorkCompletionExpectation(WorkCompletionTarget target) {
  switch (target) {
    case WorkCompletionTarget
        .buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork:
      _buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork();
    case WorkCompletionTarget
        .buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile:
      _buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile();
    case WorkCompletionTarget
        .buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint:
      _buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint();
    case WorkCompletionTarget
        .buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax:
      _buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax();
    case WorkCompletionTarget
        .buildImprovementCompletionDoesNotReApplyExtractionTechCap1291:
      _buildImprovementCompletionDoesNotReApplyExtractionTechCap1291();
    case WorkCompletionTarget
        .workCancelledWhenProvinceContainingTargetTileIsConquered376:
      _workCancelledWhenProvinceContainingTargetTileIsConquered376();
    case WorkCompletionTarget
        .multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero:
      _multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero();
    case WorkCompletionTarget
        .exploreCompletionSetsVisibilityAndClearsCurrentWork:
      _exploreCompletionSetsVisibilityAndClearsCurrentWork();
    case WorkCompletionTarget
        .exploreCompletionRevealsEveryTileInCanonicalFullIdBucket:
      _exploreCompletionRevealsEveryTileInCanonicalFullIdBucket();
    case WorkCompletionTarget.buildRoadCompletionIncreasesRoadLevel:
      _buildRoadCompletionIncreasesRoadLevel();
    case WorkCompletionTarget
        .buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade:
      _buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade();
    case WorkCompletionTarget
        .buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt:
      _buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt();
    case WorkCompletionTarget
        .buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea:
      _buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea();
    case WorkCompletionTarget.buildFortCompletionIncreasesProvinceFortLevel:
      _buildFortCompletionIncreasesProvinceFortLevel();
    case WorkCompletionTarget.buildRailCompletionLeavesRoadWhenTileHasNoRoad:
      _buildRailCompletionLeavesRoadWhenTileHasNoRoad();
    case WorkCompletionTarget.buildRailCompletionSetsRoadLevelTo4WhenValid:
      _buildRailCompletionSetsRoadLevelTo4WhenValid();
    case WorkCompletionTarget.routesKWorkTargetBuildRailThroughHandlerMapEntry:
      _routesKWorkTargetBuildRailThroughHandlerMapEntry();
    case WorkCompletionTarget
        .buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies:
      _buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies();
    case WorkCompletionTarget
        .upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord:
      _upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord();
    case WorkCompletionTarget
        .exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord:
      _exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord();
  }
}

Unit _builderCompletingImprovement({
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

Game _completionGame({
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

void
_buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [_builderCompletingImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 1);
  final after = next.worldState.oldWorld.units.single;
  expect(after.tileKey, WorkAppIds.tileKey);
  expect(after.originTileKey, isNull);
  expect(after.assignedTileKey, isNull);
}

void _buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      turnNumber: 2,
      units: [_builderCompletingImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.lastHumanCompletedResearchCategory, 'gathering');
  expect(next.lastHumanResearchCategoryCompletionTurn, 2);
}

void
_buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint() {
  const aiId = 'ai1';
  final next = applyBuildAndWorkOrders(
    _completionGame(
      turnNumber: 1,
      units: [_builderCompletingImprovement(ownerId: aiId)],
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
    workAppProcessWorkOrders(),
  );
  final envy = next.dossierEvidenceEntries
      .where((e) => e.agendaType == 'envy')
      .toList();
  expect(envy, isNotEmpty);
  expect(envy.single.subjectId, aiId);
  expect(envy.single.scoreDelta, 1);
}

void _buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [_builderCompletingImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 3),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 4);
}

void _buildImprovementCompletionDoesNotReApplyExtractionTechCap1291() {
  // Assign-time would reject 3→4 with extraction cap 2; completion still applies +1 to stored level.
  expect(
    extractionCapForResourceForUnlocked(const {kTechIdSawMill: true}, 'grain'),
    1,
  );
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [_builderCompletingImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 3),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
      players: [
        workAppPlayer(techUnlocked: const {kTechIdSawMill: true}),
      ],
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 4);
}

void _workCancelledWhenProvinceContainingTargetTileIsConquered376() {
  // Unit p1 is working on a tile in P1; province P1 is conquered by p2.
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [_builderCompletingImprovement(totalTurns: 2, remainingTurns: 2)],
      // Province owned by p2 (conquered); unit still belongs to p1.
      provinces: [workAppOwnedProvince(ownerId: 'p2')],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
    ),
    workAppProcessWorkOrders(),
  );
  final uAfter = next.worldState.oldWorld.units.single;
  expect(uAfter.status, UnitStatus.idle);
  expect(uAfter.currentWork, isNull);
  expect(uAfter.tileKey, WorkAppIds.originTileKey);
  expect(uAfter.originTileKey, isNull);
  expect(uAfter.assignedTileKey, isNull);
  // Improvement not applied (work was cancelled).
  expect(next.worldState.tileState.improvementLevel(WorkAppIds.tileKey), 0);
}

void _multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero() {
  final game = _completionGame(
    units: [
      _builderCompletingImprovement(
        totalTurns: 2,
        remainingTurns: 2,
        withOriginAssignment: false,
      ),
    ],
    tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
  );
  final afterFirst = applyBuildAndWorkOrders(game, workAppProcessWorkOrders());
  expect(
    afterFirst.worldState.tileState.improvementLevel(WorkAppIds.tileKey),
    0,
  );
  final uAfterFirst = afterFirst.worldState.oldWorld.units.single;
  expect(uAfterFirst.currentWork!.remainingTurns, 1);
  final afterSecond = applyBuildAndWorkOrders(
    afterFirst,
    workAppProcessWorkOrders(),
  );
  expect(
    afterSecond.worldState.tileState.improvementLevel(WorkAppIds.tileKey),
    1,
  );
}

void _exploreCompletionSetsVisibilityAndClearsCurrentWork() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeExplorer,
          workTarget: kWorkTargetExplore,
        ),
      ],
      tileKeysByRegionAndProvince: {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey],
        },
      },
    ),
    workAppProcessWorkOrders(),
  );
  expect(
    next.worldState.playerVisibilityByTile['p1']?[WorkAppIds.tileKey],
    VisibilityLevel.fullyVisible.name,
  );
}

void _exploreCompletionRevealsEveryTileInCanonicalFullIdBucket() {
  const tileKey2 = WorkAppIds.originTileKey;
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeExplorer,
          workTarget: kWorkTargetExplore,
        ),
      ],
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
    workAppProcessWorkOrders(),
  );
  expect(
    next.worldState.playerVisibilityByTile['p1']?[WorkAppIds.tileKey],
    VisibilityLevel.fullyVisible.name,
  );
  expect(
    next.worldState.playerVisibilityByTile['p1']?[tileKey2],
    VisibilityLevel.fullyVisible.name,
  );
  expect(
    next.worldState.playerVisibilityByTile['p1']?['oldWorld|P1|9|9'],
    VisibilityLevel.unknown.name,
  );
}

void _buildRoadCompletionIncreasesRoadLevel() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildRoad,
        ),
      ],
      tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, 0),
    ),
    workAppProcessWorkOrders(),
    tileMapByRegion: const {},
  );
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 1);
}

void
_buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade() {
  const capitalTileKey = WorkAppIds.originTileKey;
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildRoad,
        ),
      ],
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
    ),
    workAppProcessWorkOrders(),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );

  // Road built on target tile.
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 1);
  // Capital tile was already at level 2 and should remain 2 (no downgrade).
  expect(next.worldState.tileState.roadLevel(capitalTileKey), 2);
}

void
_buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt() {
  const portTileKey = WorkAppIds.originTileKey;
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildRoad,
        ),
      ],
      tileState: TileMapState()
          .setRoadLevel(WorkAppIds.tileKey, 1)
          .setRoadLevel(portTileKey, 1),
      portsByProvinceSeaboard: const {
        '${WorkAppIds.provinceId}|sea1': portTileKey,
      },
      players: [
        workAppPlayer(techUnlocked: const {kTechIdRoadConstruction: true}),
      ],
    ),
    workAppProcessWorkOrders(),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );

  // Road on target tile upgraded from 1 -> 2.
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 2);
  // Adjacent port tile upgraded from 1 -> 2.
  expect(next.worldState.tileState.roadLevel(portTileKey), 2);
}

void _buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea() {
  final topology = MapTopology(
    nodes: const [
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
    edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
  );
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildPort,
        ),
      ],
    ),
    workAppProcessWorkOrders(),
    topology: topology,
  );
  expect(next.worldState.tileState.roadLevel(WorkAppIds.tileKey), 4);
  expect(
    next.worldState.portsByProvinceSeaboard.keys.any(
      (k) => k.startsWith(WorkAppIds.provinceId),
    ),
    isTrue,
  );
}

void _buildFortCompletionIncreasesProvinceFortLevel() {
  final next = applyBuildAndWorkOrders(
    _completionGame(
      units: [
        workAppWorkingUnit(
          type: kUnitTypeEngineer,
          workTarget: kWorkTargetBuildFort,
        ),
      ],
      provinces: [workAppOwnedProvince(fortLevel: 0)],
    ),
    workAppProcessWorkOrders(),
  );
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
}

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
