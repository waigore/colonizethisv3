// Scenario run tear-offs for work-completion family (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'work_application_fixtures.dart';
import 'work_completion_expectation_shorthand.dart';

void
wccRunBuildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork() {
  wccExpectBuildImprovementCompletesToLevel(1);
}

void
wccRunBuildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile() {
  final envyHintNext = wccApply(
    workAppOwnedGame(
      turnNumber: 2,
      units: [wccBuilderImprovement()],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    ),
  );
  expect(envyHintNext.lastHumanCompletedResearchCategory, 'gathering');
  expect(envyHintNext.lastHumanResearchCategoryCompletionTurn, 2);
}

void
wccRunBuildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint() {
  const aiId = 'ai1';
  final envyEvidenceNext = wccApply(
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
  final envy = envyEvidenceNext.dossierEvidenceEntries
      .where((e) => e.agendaType == 'envy')
      .toList();
  expect(envy, isNotEmpty);
  expect(envy.single.subjectId, aiId);
  expect(envy.single.scoreDelta, 1);
}

void wccRunBuildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax() {
  wccExpectBuildImprovementCompletesToLevel(
    4,
    fromLevel: 3,
    resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
  );
}

void wccRunBuildImprovementCompletionDoesNotReApplyExtractionTechCap1291() {
  expect(
    extractionCapForResourceForUnlocked(const {kTechIdSawMill: true}, 'grain'),
    1,
  );
  wccExpectBuildImprovementCompletesToLevel(
    4,
    fromLevel: 3,
    resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
    players: [
      workAppPlayer(techUnlocked: const {kTechIdSawMill: true}),
    ],
  );
}

void wccRunWorkCancelledWhenProvinceContainingTargetTileIsConquered376() {
  final next = wccApply(
    workAppOwnedGame(
      units: [wccBuilderImprovement(totalTurns: 2, remainingTurns: 2)],
      provinces: [workAppOwnedProvince(ownerId: 'p2')],
      tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
    ),
  );
  final cancelled = wccSingleUnit(next);
  expect(cancelled.status, UnitStatus.idle);
  expect(cancelled.currentWork, isNull);
  expect(cancelled.tileKey, WorkAppIds.originTileKey);
  expect(cancelled.originTileKey, isNull);
  expect(cancelled.assignedTileKey, isNull);
  wccExpectImprovement(next, 0);
}

void wccRunMultiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero() {
  final game = workAppOwnedGame(
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
  expect(wccSingleUnit(afterFirst).currentWork!.remainingTurns, 1);
  final afterSecond = wccApply(afterFirst);
  wccExpectImprovement(afterSecond, 1);
}

void wccRunExploreCompletionSetsVisibilityAndClearsCurrentWork() {
  final next = wccApply(
    workAppOwnedGame(
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
  );
  wccExpectVisibility(
    next,
    WorkAppIds.tileKey,
    VisibilityLevel.fullyVisible.name,
  );
}

void wccRunExploreCompletionRevealsEveryTileInCanonicalFullIdBucket() {
  const tileKey2 = WorkAppIds.originTileKey;
  final next = wccApply(
    workAppOwnedGame(
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
  );
  wccExpectVisibility(
    next,
    WorkAppIds.tileKey,
    VisibilityLevel.fullyVisible.name,
  );
  wccExpectVisibility(next, tileKey2, VisibilityLevel.fullyVisible.name);
  wccExpectVisibility(next, 'oldWorld|P1|9|9', VisibilityLevel.unknown.name);
}

void wccRunBuildRoadCompletionIncreasesRoadLevel() {
  final next = wccApply(
    wccEngineerCompletionGame(
      workTarget: kWorkTargetBuildRoad,
      tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, 0),
    ),
    tileMapByRegion: const {},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
}

void
wccRunBuildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade() {
  const capitalTileKey = WorkAppIds.originTileKey;
  final next = wccApply(
    wccEngineerCompletionGame(
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
    ),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
  wccExpectRoadLevel(next, capitalTileKey, 2);
}

void
wccRunBuildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt() {
  const portTileKey = WorkAppIds.originTileKey;
  final next = wccApply(
    wccEngineerCompletionGame(
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
    ),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 2);
  wccExpectRoadLevel(next, portTileKey, 2);
}

void wccRunBuildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea() {
  final next = wccApply(
    wccEngineerCompletionGame(workTarget: kWorkTargetBuildPort),
    topology: const MapTopology(
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
    ),
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
  expect(
    next.worldState.portsByProvinceSeaboard.keys.any(
      (k) => k.startsWith(WorkAppIds.provinceId),
    ),
    isTrue,
  );
}

void wccRunBuildFortCompletionIncreasesProvinceFortLevel() {
  final next = wccApply(
    wccEngineerCompletionGame(
      workTarget: kWorkTargetBuildFort,
      provinces: [workAppOwnedProvince(fortLevel: 0)],
    ),
  );
  expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
}

void wccRunBuildRailCompletionLeavesRoadWhenTileHasNoRoad() {
  final next = wccApply(
    wccRailGame(roadLevel: 0),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 0);
}

void wccRunBuildRailCompletionSetsRoadLevelTo4WhenValid() {
  final next = wccApply(
    wccRailGame(roadLevel: 1),
    tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
}

void wccRunRoutesKWorkTargetBuildRailThroughHandlerMapEntry() {
  final (railState, railUnit, railCw) = wccDispatchRailSetup(roadLevel: 1);
  final railNext = wccDispatchCompleted(railState, railUnit, railCw);
  expect(railNext.work.tileState.roadLevel(WorkAppIds.tileKey), 4);
}

void
wccRunBuildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies() {
  final (noopState, noopUnit, noopCw) = wccDispatchRailSetup(
    roadLevel: 0,
    players: [workAppPlayer()],
  );
  final noopNext = wccDispatchCompleted(noopState, noopUnit, noopCw);
  expect(noopNext.work.tileState.roadLevel(WorkAppIds.tileKey), 0);
}

void
wccRunUpgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord() {
  final upgradeUnit = workAppUnit(
    type: kUnitTypeBuilder,
    status: UnitStatus.working,
  );
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
  final (upgradeState, upgradeU, upgradeWork) = wccDispatchWorkSetup(
    unit: upgradeUnit,
    game: upgradeGame,
    cw: upgradeCw,
    oldProvinces: [upgradeProvince],
  );
  final upgradeNext = wccDispatchCompleted(upgradeState, upgradeU, upgradeWork);
  expect(upgradeNext.work.oldProvinces.single.townDevelopmentLevel, 1);
}

void
wccRunExploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord() {
  final exploreUnit = workAppUnit(
    type: kUnitTypeExplorer,
    status: UnitStatus.working,
  );
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
  final (exploreState, exploreU, exploreWork) = wccDispatchWorkSetup(
    unit: exploreUnit,
    game: exploreGame,
    cw: exploreCw,
    oldProvinces: const [],
  );
  String? capturedRegionId;
  final exploreNext = wccDispatchCompleted(
    exploreState,
    exploreU,
    exploreWork,
    onExploreRegion: (s, unit, regionId) {
      capturedRegionId = regionId;
      return s;
    },
  );
  expect(capturedRegionId, WorkAppIds.ow);
  expect(identical(exploreNext, exploreState), isTrue);
}
