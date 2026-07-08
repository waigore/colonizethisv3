// Compact applyBuildAndWorkOrders work-completion assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/orders_application_completed_work.dart';
import 'package:colonizethis_orders/src/orders/orders_application_context.dart';
import 'package:colonizethis_test/test.dart';

import 'orders_application_test_support.dart';

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

Orders _ordersToTriggerProcessWork() =>
    Orders(buildUnitOrdersByPlayerId: {'p1': <BuildUnitOrder>[]});

TileMapResult _simpleTileMap() {
  return TileMapResult(
    width: 3,
    height: 3,
    grid: const [
      ['P1', 'P1', 'P1'],
      ['P1', 'P1', 'P1'],
      ['P1', 'P1', 'P1'],
    ],
  );
}

TileMapResult _railMap() {
  return TileMapResult(
    width: 1,
    height: 1,
    grid: const [
      ['P1'],
    ],
    terrainGrid: [
      [TerrainType.plains],
    ],
  );
}

void
_buildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final tileState = TileMapState().setImprovement(tileKey, 0);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    originTileKey: 'oldWorld|P1|1|0',
    assignedTileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  expect(next.worldState.tileState.improvementLevel(tileKey), 1);
  final after = next.worldState.oldWorld.units.single;
  expect(after.tileKey, tileKey);
  expect(after.originTileKey, isNull);
  expect(after.assignedTileKey, isNull);
}

void _buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final tileState = TileMapState().setImprovement(tileKey, 0);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    originTileKey: 'oldWorld|P1|1|0',
    assignedTileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKey: 'grain'},
      tileState: tileState,
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  expect(next.lastHumanCompletedResearchCategory, 'gathering');
  expect(next.lastHumanResearchCategoryCompletionTurn, 2);
}

void
_buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const aiId = 'ai1';
  final tileState = TileMapState().setImprovement(tileKey, 0);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: aiId,
    locationProvinceId: provinceId,
    tileKey: tileKey,
    originTileKey: 'oldWorld|P1|1|0',
    assignedTileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: aiId)],
        units: [unit],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKey: 'coal'},
      tileState: tileState,
    ),
    players: const [
      Player(id: 'human', displayName: 'H', isHuman: true),
      Player(id: aiId, displayName: 'AI', isHuman: false),
    ],
    aiControlByGpId: const {aiId: true},
    lastHumanCompletedResearchCategory: 'gathering',
    lastHumanResearchCategoryCompletionTurn: 0,
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  final envy = next.dossierEvidenceEntries
      .where((e) => e.agendaType == 'envy')
      .toList();
  expect(envy, isNotEmpty);
  expect(envy.single.subjectId, aiId);
  expect(envy.single.scoreDelta, 1);
}

void _buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final tileState = TileMapState().setImprovement(tileKey, 3);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    originTileKey: 'oldWorld|P1|1|0',
    assignedTileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKey: 'grain'},
      tileState: tileState,
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  expect(next.worldState.tileState.improvementLevel(tileKey), 4);
}

void _buildImprovementCompletionDoesNotReApplyExtractionTechCap1291() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  // Assign-time would reject 3→4 with extraction cap 2; completion still applies +1 to stored level.
  expect(
    extractionCapForResourceForUnlocked(const {kTechIdSawMill: true}, 'grain'),
    1,
  );
  final tileState = TileMapState().setImprovement(tileKey, 3);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    originTileKey: 'oldWorld|P1|1|0',
    assignedTileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {tileKey: 'grain'},
      tileState: tileState,
    ),
    players: const [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        techUnlocked: {kTechIdSawMill: true},
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  expect(next.worldState.tileState.improvementLevel(tileKey), 4);
}

void _workCancelledWhenProvinceContainingTargetTileIsConquered376() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  // Unit p1 is working on a tile in P1; province P1 is conquered by p2.
  final tileState = TileMapState().setImprovement(tileKey, 0);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    originTileKey: 'oldWorld|P1|1|0',
    assignedTileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 2,
      remainingTurns: 2,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        // Province owned by p2 (conquered); unit still belongs to p1.
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p2')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  final uAfter = next.worldState.oldWorld.units.single;
  expect(uAfter.status, UnitStatus.idle);
  expect(uAfter.currentWork, isNull);
  expect(uAfter.tileKey, 'oldWorld|P1|1|0');
  expect(uAfter.originTileKey, isNull);
  expect(uAfter.assignedTileKey, isNull);
  // Improvement not applied (work was cancelled).
  expect(next.worldState.tileState.improvementLevel(tileKey), 0);
}

void _multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final tileState = TileMapState().setImprovement(tileKey, 0);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: CurrentWork(
      workTarget: kWorkTargetBuildImprovement,
      tileKey: tileKey,
      totalTurns: 2,
      remainingTurns: 2,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final afterFirst = applyBuildAndWorkOrders(
    game,
    _ordersToTriggerProcessWork(),
  );
  expect(afterFirst.worldState.tileState.improvementLevel(tileKey), 0);
  final uAfterFirst = afterFirst.worldState.oldWorld.units.single;
  expect(uAfterFirst.currentWork!.remainingTurns, 1);
  final afterSecond = applyBuildAndWorkOrders(
    afterFirst,
    _ordersToTriggerProcessWork(),
  );
  expect(afterSecond.worldState.tileState.improvementLevel(tileKey), 1);
}

void _exploreCompletionSetsVisibilityAndClearsCurrentWork() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetExplore,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
        },
      },
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  expect(
    next.worldState.playerVisibilityByTile['p1']?[tileKey],
    VisibilityLevel.fullyVisible.name,
  );
}

void _exploreCompletionRevealsEveryTileInCanonicalFullIdBucket() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey2 = 'oldWorld|P1|1|0';
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetExplore,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        ow: {
          provinceId: [tileKey, tileKey2],
          'P1': ['oldWorld|P1|9|9'],
        },
      },
      playerVisibilityByTile: const {
        'p1': {
          tileKey: 'fogged',
          tileKey2: 'unknown',
          'oldWorld|P1|9|9': 'unknown',
        },
      },
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  expect(
    next.worldState.playerVisibilityByTile['p1']?[tileKey],
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
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final tileState = TileMapState().setRoadLevel(tileKey, 0);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildRoad,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersToTriggerProcessWork(),
    tileMapByRegion: const {},
  );
  expect(next.worldState.tileState.roadLevel(tileKey), 1);
}

void
_buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const capitalTileKey = 'oldWorld|P1|1|0';
  final initialTileState = TileMapState()
      .setRoadLevel(tileKey, 0)
      .setRoadLevel(capitalTileKey, 2);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildRoad,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final player = Player(
    id: 'p1',
    displayName: 'P1',
    isHuman: true,
    capitalProvinceId: provinceId,
    capitalTile: const CapitalTile(
      regionId: ow,
      provinceId: provinceId,
      x: 1,
      y: 0,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: initialTileState,
    ),
    players: [player],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersToTriggerProcessWork(),
    tileMapByRegion: {ow: _simpleTileMap()},
  );

  // Road built on target tile.
  expect(next.worldState.tileState.roadLevel(tileKey), 1);
  // Capital tile was already at level 2 and should remain 2 (no downgrade).
  expect(next.worldState.tileState.roadLevel(capitalTileKey), 2);
}

void
_buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const portTileKey = 'oldWorld|P1|1|0';
  final initialTileState = TileMapState()
      .setRoadLevel(tileKey, 1)
      .setRoadLevel(portTileKey, 1);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildRoad,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final player = Player(
    id: 'p1',
    displayName: 'P1',
    isHuman: true,
    capitalProvinceId: provinceId,
    techUnlocked: const {kTechIdRoadConstruction: true},
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: RegionData(
      provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
      units: [unit],
    ),
    newWorld: const RegionData(),
    tileState: initialTileState,
    portsByProvinceSeaboard: const {'$provinceId|sea1': portTileKey},
  );
  final game = Game(id: 'g', worldState: world, players: [player]);

  final next = applyBuildAndWorkOrders(
    game,
    _ordersToTriggerProcessWork(),
    tileMapByRegion: {ow: _simpleTileMap()},
  );

  // Road on target tile upgraded from 1 -> 2.
  expect(next.worldState.tileState.roadLevel(tileKey), 2);
  // Adjacent port tile upgraded from 1 -> 2.
  expect(next.worldState.tileState.roadLevel(portTileKey), 2);
}

void _buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final topology = MapTopology(
    nodes: const [
      TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
    ],
    edges: const [TopologyEdge(id1: 'P1', id2: 'sea1')],
  );
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildPort,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersToTriggerProcessWork(),
    topology: topology,
  );
  expect(next.worldState.tileState.roadLevel(tileKey), 4);
  expect(
    next.worldState.portsByProvinceSeaboard.keys.any(
      (k) => k.startsWith(provinceId),
    ),
    isTrue,
  );
}

void _buildFortCompletionIncreasesProvinceFortLevel() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeEngineer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildFort,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: 'p1', fortLevel: 0),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
  final next = applyBuildAndWorkOrders(game, _ordersToTriggerProcessWork());
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
}

void _buildRailCompletionLeavesRoadWhenTileHasNoRoad() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final tileState = TileMapState().setRoadLevel(tileKey, 0);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeRailBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildRail,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        techUnlocked: const {kTechIdEarlySteamEngine: true},
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersToTriggerProcessWork(),
    tileMapByRegion: {ow: _railMap()},
  );
  expect(next.worldState.tileState.roadLevel(tileKey), 0);
}

void _buildRailCompletionSetsRoadLevelTo4WhenValid() {
  const ow = OrdersApplicationTestSupport.ow;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  final tileState = TileMapState().setRoadLevel(tileKey, 1);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeRailBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
    currentWork: const CurrentWork(
      workTarget: kWorkTargetBuildRail,
      tileKey: tileKey,
      totalTurns: 1,
      remainingTurns: 1,
    ),
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        techUnlocked: const {kTechIdEarlySteamEngine: true},
      ),
    ],
  );
  final next = applyBuildAndWorkOrders(
    game,
    _ordersToTriggerProcessWork(),
    tileMapByRegion: {ow: _railMap()},
  );
  expect(next.worldState.tileState.roadLevel(tileKey), 4);
}

void _routesKWorkTargetBuildRailThroughHandlerMapEntry() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final tileState = TileMapState().setRoadLevel(tileKey, 1);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeRailBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        techUnlocked: const {kTechIdEarlySteamEngine: true},
      ),
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
    tileMapByRegion: {ow: _railMap()},
    work: work,
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetBuildRail,
    tileKey: tileKey,
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

  expect(next.work.tileState.roadLevel(tileKey), 4);
}

void _buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final tileState = TileMapState().setRoadLevel(tileKey, 0);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeRailBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileState: tileState,
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
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
    tileMapByRegion: {ow: _railMap()},
    work: work,
  );
  const cw = CurrentWork(
    workTarget: kWorkTargetBuildRail,
    tileKey: tileKey,
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

  expect(next.work.tileState.roadLevel(tileKey), 0);
}

void
_upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord() {
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
  );
  const province = Province(
    id: provinceId,
    regionId: ow,
    ownerId: 'p1',
    townDevelopmentLevel: 0,
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: const [province], units: [unit]),
      newWorld: const RegionData(),
      tileState: TileMapState(),
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
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
    tileKey: tileKey,
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
  const ow = OrdersApplicationTestSupport.ow;
  const provinceId = OrdersApplicationTestSupport.provinceId;
  const tileKey = OrdersApplicationTestSupport.tileKey;
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: 'p1',
    locationProvinceId: provinceId,
    tileKey: tileKey,
    status: UnitStatus.working,
  );
  final game = Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(units: [unit]),
      newWorld: const RegionData(),
      tileState: TileMapState(),
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
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
    tileKey: tileKey,
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

  expect(capturedRegionId, ow);
  expect(identical(next, state), isTrue);
}
