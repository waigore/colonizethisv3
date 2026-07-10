// Table-driven applyBuildAndWorkOrders work-completion scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../scenario_runner.dart';
import 'work_application_fixtures.dart';
import 'work_completion_expectation_shorthand.dart';

void wccRunBuildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork() {
  wccExpectBuildImprovementCompletesToLevel(1);
}

void wccRunBuildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile() {
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

void wccRunBuildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint() {
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
    players: [workAppPlayer(techUnlocked: const {kTechIdSawMill: true})],
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
  wccExpectCancelledIdleAtOrigin(next);
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
  wccExpectImprovement(wccApply(afterFirst), 1);
}

void wccRunExploreCompletionSetsVisibilityAndClearsCurrentWork() {
  wccExpectFullyVisible(wccApply(wccExploreWorkingGame()), WorkAppIds.tileKey);
}

void wccRunExploreCompletionRevealsEveryTileInCanonicalFullIdBucket() {
  const tileKey2 = WorkAppIds.originTileKey;
  const other = 'oldWorld|P1|9|9';
  final next = wccApply(
    wccExploreWorkingGame(
      tileKeysByRegionAndProvince: const {
        WorkAppIds.ow: {
          WorkAppIds.provinceId: [WorkAppIds.tileKey, tileKey2],
          'P1': [other],
        },
      },
      playerVisibilityByTile: const {
        'p1': {
          WorkAppIds.tileKey: 'fogged',
          tileKey2: 'unknown',
          other: 'unknown',
        },
      },
    ),
  );
  wccExpectFullyVisible(next, WorkAppIds.tileKey);
  wccExpectFullyVisible(next, tileKey2);
  wccExpectVisibility(next, other, VisibilityLevel.unknown.name);
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

void wccRunBuildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade() {
  const capital = WorkAppIds.originTileKey;
  final next = wccApply(
    wccRoadPropagateGame(
      workTileRoad: 0,
      adjacentRoad: 2,
      adjacentTileKey: capital,
      players: [
        workAppPlayer(
          capitalProvinceId: WorkAppIds.provinceId,
          capitalTile: workAppCapitalTile(x: 1),
        ),
      ],
    ),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
  wccExpectRoadLevel(next, capital, 2);
}

void wccRunBuildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt() {
  const port = WorkAppIds.originTileKey;
  final next = wccApply(
    wccRoadPropagateGame(
      workTileRoad: 1,
      adjacentRoad: 1,
      adjacentTileKey: port,
      portsByProvinceSeaboard: const {
        '${WorkAppIds.provinceId}|sea1': port,
      },
      players: [
        workAppPlayer(techUnlocked: const {kTechIdRoadConstruction: true}),
      ],
    ),
    tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
  );
  wccExpectRoadLevel(next, WorkAppIds.tileKey, 2);
  wccExpectRoadLevel(next, port, 2);
}

void wccRunBuildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea() {
  final next = wccApply(
    wccEngineerCompletionGame(workTarget: kWorkTargetBuildPort),
    topology: const MapTopology(
      nodes: [
        TopologyNode(id: 'P1', regionId: WorkAppIds.ow, type: TopologyNodeType.province),
        TopologyNode(id: 'sea1', regionId: WorkAppIds.ow, type: TopologyNodeType.seaZone),
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

void wccRunBuildRailCompletionLeavesRoadWhenTileHasNoRoad() =>
    wccExpectRailApply(0, 0);

void wccRunBuildRailCompletionSetsRoadLevelTo4WhenValid() =>
    wccExpectRailApply(1, 4);

void wccRunRoutesKWorkTargetBuildRailThroughHandlerMapEntry() =>
    wccExpectRailDispatch(1, 4);

void wccRunBuildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies() =>
    wccExpectRailDispatch(0, 0, players: [workAppPlayer()]);

void wccRunUpgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord() {
  final province = Province(
    id: WorkAppIds.provinceId,
    regionId: WorkAppIds.ow,
    ownerId: 'p1',
    townDevelopmentLevel: 0,
  );
  final (state, unit, cw) = wccDispatchTargetSetup(
    unitType: kUnitTypeBuilder,
    workTarget: kWorkTargetUpgradeTown,
    provinces: [province],
  );
  expect(
    wccDispatchCompleted(state, unit, cw).work.oldProvinces.single
        .townDevelopmentLevel,
    1,
  );
}

void wccRunExploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord() {
  final (state, unit, cw) = wccDispatchTargetSetup(
    unitType: kUnitTypeExplorer,
    workTarget: kWorkTargetExplore,
  );
  String? capturedRegionId;
  final next = wccDispatchCompleted(
    state,
    unit,
    cw,
    onExploreRegion: (s, _, regionId) {
      capturedRegionId = regionId;
      return s;
    },
  );
  expect(capturedRegionId, WorkAppIds.ow);
  expect(identical(next, state), isTrue);
}

/// Canonical scenarios for work-completion family tests.
/// Labels match former suite descriptions (single-line `label:` for CI).
List<RunnableScenario> workCompletionScenarios() => [
  // dart format off
  rs('build_improvement completion increases improvement level and clears currentWork', wccRunBuildImprovementCompletionIncreasesImprovementLevelAndClearsCurrentWork),
  rs('build_improvement completion sets envy mirror hint for human on extraction tile', wccRunBuildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile),
  rs('build_improvement completion adds envy evidence when AI mirrors human gathering hint', wccRunBuildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint),
  rs('build_improvement completion raises stored level from 3 to 4 (global max)', wccRunBuildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax),
  rs('build_improvement completion does not re-apply extraction tech cap (#1291)', wccRunBuildImprovementCompletionDoesNotReApplyExtractionTechCap1291, '#1291'),
  rs('work cancelled when province containing target tile is conquered (#376)', wccRunWorkCancelledWhenProvinceContainingTargetTileIsConquered376, '#376'),
  rs('multi-turn work decrements remainingTurns and completes only when zero', wccRunMultiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero),
  rs('explore completion sets visibility and clears currentWork', wccRunExploreCompletionSetsVisibilityAndClearsCurrentWork),
  rs('explore completion reveals every tile in canonical full-id bucket', wccRunExploreCompletionRevealsEveryTileInCanonicalFullIdBucket),
  rs('build_road completion increases road level', wccRunBuildRoadCompletionIncreasesRoadLevel),
  rs('build_road completion propagates transport level to adjacent capital tile (no downgrade)', wccRunBuildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade),
  rs('build_road completion propagates transport level to adjacent port tile and upgrades it', wccRunBuildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt),
  rs('build_port completion sets port and road level 4 when topology has sea', wccRunBuildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea),
  rs('build_fort completion increases province fortLevel', wccRunBuildFortCompletionIncreasesProvinceFortLevel),
  rs('build_rail completion leaves road when tile has no road', wccRunBuildRailCompletionLeavesRoadWhenTileHasNoRoad),
  rs('build_rail completion sets road level to 4 when valid', wccRunBuildRailCompletionSetsRoadLevelTo4WhenValid),
  rs('routes kWorkTargetBuildRail through handler map entry', wccRunRoutesKWorkTargetBuildRailThroughHandlerMapEntry),
  rs('build_rail completion no-ops when rejectionReasonForBuildRailOrder applies', wccRunBuildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies),
  rs('upgrade_town threads getProvinces/replaceProvinces through the CompletedWorkContext record', wccRunUpgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord),
  rs('explore invokes the applyExploreCompletion closure with the unit region via the CompletedWorkContext record', wccRunExploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord),
  // dart format on
];
