// Compact applyBuildAndWorkOrders work-completion assertions (Refs #3949 wave 3).

import 'work_completion_expectation_shorthand.dart';
import 'work_application_fixtures.dart';
import 'orders_application_test_support.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_data/colonizethis_data.dart';

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
      final next = wccApply(wccBuilderImprovementAtLevel(0));
        wccExpectImprovement(next, 1);
        wccExpectUnitIdleCleared(next);
    case WorkCompletionTarget
        .buildImprovementCompletionSetsEnvyMirrorHintForHumanOnExtractionTile:
      final next = wccApply(
          wccGame(
            turnNumber: 2,
            units: [wccBuilderImprovement()],
            tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 0),
            resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
          ),
        );
        wccExpectEnvyHint(next, 'gathering', 2);
    case WorkCompletionTarget
        .buildImprovementCompletionAddsEnvyEvidenceWhenAiMirrorsHumanGatheringHint:
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
    case WorkCompletionTarget
        .buildImprovementCompletionRaisesStoredLevelFrom3To4GlobalMax:
      final next = wccApply(
          wccGame(
            units: [wccBuilderImprovement()],
            tileState: TileMapState().setImprovement(WorkAppIds.tileKey, 3),
            resourceByTileKey: const {WorkAppIds.tileKey: 'grain'},
          ),
        );
        wccExpectImprovement(next, 4);
    case WorkCompletionTarget
        .buildImprovementCompletionDoesNotReApplyExtractionTechCap1291:
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
    case WorkCompletionTarget
        .workCancelledWhenProvinceContainingTargetTileIsConquered376:
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
    case WorkCompletionTarget
        .multiTurnWorkDecrementsRemainingTurnsAndCompletesOnlyWhenZero:
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
    case WorkCompletionTarget
        .exploreCompletionSetsVisibilityAndClearsCurrentWork:
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
    case WorkCompletionTarget
        .exploreCompletionRevealsEveryTileInCanonicalFullIdBucket:
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
    case WorkCompletionTarget.buildRoadCompletionIncreasesRoadLevel:
      final next = wccApply(
          wccEngineerCompletionGame(
            workTarget: kWorkTargetBuildRoad,
            tileState: TileMapState().setRoadLevel(WorkAppIds.tileKey, 0),
          ),
          tileMapByRegion: const {},
        );
        wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
    case WorkCompletionTarget
        .buildRoadCompletionPropagatesTransportLevelToAdjacentCapitalTileNoDowngrade:
      const capitalTileKey = WorkAppIds.originTileKey;
        final next = wccApply(
          wccBuildRoadCapitalAdjacentGame(),
          tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
        );
        wccExpectRoadLevel(next, WorkAppIds.tileKey, 1);
        wccExpectRoadLevel(next, capitalTileKey, 2);
    case WorkCompletionTarget
        .buildRoadCompletionPropagatesTransportLevelToAdjacentPortTileAndUpgradesIt:
      const portTileKey = WorkAppIds.originTileKey;
        final next = wccApply(
          wccBuildRoadPortAdjacentGame(),
          tileMapByRegion: {WorkAppIds.ow: workAppSimpleTileMap()},
        );
        wccExpectRoadLevel(next, WorkAppIds.tileKey, 2);
        wccExpectRoadLevel(next, portTileKey, 2);
    case WorkCompletionTarget
        .buildPortCompletionSetsPortAndRoadLevel4WhenTopologyHasSea:
      final next = wccApply(
          wccEngineerCompletionGame(workTarget: kWorkTargetBuildPort),
          topology: wccPortSeaTopology(),
        );
        wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
        wccExpectPortRegisteredForProvince(next);
    case WorkCompletionTarget.buildFortCompletionIncreasesProvinceFortLevel:
      final next = wccApply(
          wccEngineerCompletionGame(
            workTarget: kWorkTargetBuildFort,
            provinces: [workAppOwnedProvince(fortLevel: 0)],
          ),
        );
        wccExpectFortLevel(next, 1);
    case WorkCompletionTarget.buildRailCompletionLeavesRoadWhenTileHasNoRoad:
      final next = wccApply(
          wccRailGame(roadLevel: 0, players: wccSteamPlayers()),
          tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
        );
        wccExpectRoadLevel(next, WorkAppIds.tileKey, 0);
    case WorkCompletionTarget.buildRailCompletionSetsRoadLevelTo4WhenValid:
      final next = wccApply(
          wccRailGame(roadLevel: 1, players: wccSteamPlayers()),
          tileMapByRegion: {WorkAppIds.ow: workAppRailMap()},
        );
        wccExpectRoadLevel(next, WorkAppIds.tileKey, 4);
    case WorkCompletionTarget.routesKWorkTargetBuildRailThroughHandlerMapEntry:
      wccExpectRailDispatchSetsRoadLevel(
          roadLevel: 1,
          players: wccSteamPlayers(),
          expectedLevel: 4,
        );
    case WorkCompletionTarget
        .buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies:
      wccExpectRailDispatchSetsRoadLevel(
          roadLevel: 0,
          players: [workAppPlayer()],
          expectedLevel: 0,
        );
    case WorkCompletionTarget
        .upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord:
      wccExpectUpgradeTownProvinceLevel();
    case WorkCompletionTarget
        .exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord:
      wccExpectExploreDispatchCapturesRegion();
  }
}
