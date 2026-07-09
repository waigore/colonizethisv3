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
        final after = wccSingleUnit(next);
        expect(after.tileKey, WorkAppIds.tileKey);
        expect(after.originTileKey, isNull);
        expect(after.assignedTileKey, isNull);
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
        expect(next.lastHumanCompletedResearchCategory, 'gathering');
        expect(next.lastHumanResearchCategoryCompletionTurn, 2);
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
        final envy = next.dossierEvidenceEntries
            .where((e) => e.agendaType == 'envy')
            .toList();
        expect(envy, isNotEmpty);
        expect(envy.single.subjectId, aiId);
        expect(envy.single.scoreDelta, 1);
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
        final cancelled = wccSingleUnit(next);
        expect(cancelled.status, UnitStatus.idle);
        expect(cancelled.currentWork, isNull);
        expect(cancelled.tileKey, WorkAppIds.originTileKey);
        expect(cancelled.originTileKey, isNull);
        expect(cancelled.assignedTileKey, isNull);
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
        expect(wccSingleUnit(afterFirst).currentWork!.remainingTurns, 1);
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
        expect(
          next.worldState.portsByProvinceSeaboard.keys.any(
            (k) => k.startsWith(WorkAppIds.provinceId),
          ),
          isTrue,
        );
    case WorkCompletionTarget.buildFortCompletionIncreasesProvinceFortLevel:
      final next = wccApply(
          wccEngineerCompletionGame(
            workTarget: kWorkTargetBuildFort,
            provinces: [workAppOwnedProvince(fortLevel: 0)],
          ),
        );
        expect(next.worldState.oldWorld.provinces.single.fortLevel, 1);
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
        final (railState, railUnit, railCw) = wccDispatchRailSetup(
          roadLevel: 1,
          players: wccSteamPlayers(),
        );
        final railNext = wccDispatchCompleted(railState, railUnit, railCw);
        wccExpectRoadLevelOn(
          railNext.work.tileState,
          WorkAppIds.tileKey,
          4,
        );
    case WorkCompletionTarget
        .buildRailCompletionNoOpsWhenRejectionReasonForBuildRailOrderApplies:
        final (noopState, noopUnit, noopCw) = wccDispatchRailSetup(
          roadLevel: 0,
          players: [workAppPlayer()],
        );
        final noopNext = wccDispatchCompleted(noopState, noopUnit, noopCw);
        wccExpectRoadLevelOn(
          noopNext.work.tileState,
          WorkAppIds.tileKey,
          0,
        );
    case WorkCompletionTarget
        .upgradeTownThreadsGetProvincesReplaceProvincesThroughTheCompletedWorkContextRecord:
      final upgradeUnit =
          workAppUnit(type: kUnitTypeBuilder, status: UnitStatus.working);
        final upgradeProvince = Province(
          id: WorkAppIds.provinceId,
          regionId: WorkAppIds.ow,
          ownerId: 'p1',
          townDevelopmentLevel: 0,
        );
        final upgradeGame = wccGame(
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
        final upgradeNext =
            wccDispatchCompleted(upgradeState, upgradeU, upgradeWork);
        expect(upgradeNext.work.oldProvinces.single.townDevelopmentLevel, 1);
    case WorkCompletionTarget
        .exploreInvokesTheApplyExploreCompletionClosureWithTheUnitRegionViaTheCompletedWorkContextRecord:
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
}
