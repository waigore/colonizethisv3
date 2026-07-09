// Compact applyBuildAndWorkOrders worker-pool phase assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'worker_pool_phase_fixtures.dart';
import 'worker_pool_phase_expectation_shorthand.dart';

/// Pins for [workerPoolPhaseScenarios] rows.
enum WorkerPoolPhaseTarget {
  acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric,
  acceptedApprenticeTrainConsumesPeasantPaperAndTreasury,
  recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction,
  acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage,
  acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail,
  masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage,
  laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics,
  middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior,
  perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin,
}

void runWorkerPoolPhaseExpectation(WorkerPoolPhaseTarget target) {
  switch (target) {
    case WorkerPoolPhaseTarget
        .acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric:
      wppExpectRecruitPeasantFromFabric();
    case WorkerPoolPhaseTarget
        .acceptedApprenticeTrainConsumesPeasantPaperAndTreasury:
      wppExpectApprenticeTrain(
        paper: 5,
        peasants: 3,
        treasury: 500,
        expectedPeasants: 2,
        expectedPaper: 3,
        expectedTreasury: 300,
      );
    case WorkerPoolPhaseTarget
        .recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction:
      wppExpectApprenticeTrainSkippedWhenUnaffordable(
        paper: 5,
        peasants: 3,
        treasury: 100,
      );
    case WorkerPoolPhaseTarget
        .acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage:
        wppExpectJourneymanTrain(
          paper: 8,
          peasants: 2,
          treasury: 700,
          expectedPeasants: 1,
          expectedPaper: 3,
          expectedTreasury: 200,
          peasantsReason: 'one peasant consumed',
          journeymenReason: 'one journeyman added',
          stockReasons: {
            CommodityCatalog.paper.id: '5 paper deducted per SPEC § Recruiting cost table',
          },
          treasuryReason: '500 ducats deducted per SPEC § Recruiting cost table',
        );
    case WorkerPoolPhaseTarget
        .acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail:
        wppExpectMasterTrain(
          paper: 12,
          peasants: 1,
          treasury: 1200,
          expectedPeasants: 0,
          expectedPaper: 2,
          expectedTreasury: 200,
          peasantsReason: 'one peasant consumed',
          mastersReason: 'one master added',
          stockReasons: {
            CommodityCatalog.paper.id: '10 paper deducted per SPEC § Recruiting cost table',
          },
          treasuryReason: '1000 ducats deducted per SPEC § Recruiting cost table',
        );
    case WorkerPoolPhaseTarget
        .masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage:
        wppExpectMasterTrainSkipped(
          paper: 12,
          peasants: 1,
          treasury: 1200,
          techUnlocked: const {kTechIdMasterArtisans: true},
        );
    case WorkerPoolPhaseTarget
        .laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics:
        wppExpectSequentialTiers(
          stock: {
            CommodityCatalog.fabric.id: 2,
            CommodityCatalog.paper.id: 2,
          },
          peasants: 0,
          treasury: 200,
          tiers: [WorkerTier.peasant, WorkerTier.apprentice],
          expectedPeasants: 0,
          expectedApprentices: 1,
          expectedStock: {
            CommodityCatalog.fabric.id: 0,
            CommodityCatalog.paper.id: 0,
          },
          expectedTreasury: 0,
          peasantsReason:
              'recruited peasant immediately consumed by the apprentice train',
          apprenticesReason: 'one apprentice added',
          stockReasons: {
            CommodityCatalog.fabric.id: 'peasant recruit consumed 2 fabric',
            CommodityCatalog.paper.id: 'apprentice train consumed 2 paper',
          },
          treasuryReason: 'apprentice train consumed 200 ducats',
        );
    case WorkerPoolPhaseTarget
        .middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior:
        wppExpectSequentialTiers(
          stock: {
            CommodityCatalog.fabric.id: 4,
            CommodityCatalog.paper.id: 4,
          },
          peasants: 1,
          treasury: 400,
          tiers: [WorkerTier.apprentice, WorkerTier.apprentice, WorkerTier.peasant],
          expectedPeasants: 1,
          expectedApprentices: 1,
          expectedStock: {
            CommodityCatalog.paper.id: 2,
            CommodityCatalog.fabric.id: 2,
          },
          expectedTreasury: 200,
          peasantsReason:
              'apprentice consumed initial peasant; peasant recruit added 1',
          apprenticesReason: 'only the first apprentice train fired; second skipped',
          stockReasons: {
            CommodityCatalog.paper.id: 'one apprentice consumed 2 paper; second order did not',
            CommodityCatalog.fabric.id: 'trailing peasant recruit still consumed 2 fabric',
          },
          treasuryReason: 'only one apprentice train deducted treasury',
        );
    case WorkerPoolPhaseTarget
        .perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin:
        final apprenticePlayer = wppPlayer(
          stockpile: wppStock({CommodityCatalog.paper.id: 4}),
          workerPool: const WorkerPool(peasants: 2),
          treasury: 300,
          techUnlocked: wppApprenticeTech,
        );
        final game = wppEmptyWorldGame(
          players: [
            apprenticePlayer,
            wppPlayer(
              id: WppIds.player2,
              displayName: 'B',
              isHuman: false,
              stockpile: wppStock({CommodityCatalog.paper.id: 4}),
              workerPool: const WorkerPool(peasants: 2),
              treasury: 300,
              techUnlocked: wppApprenticeTech,
            ),
          ],
        );
        final orders = Orders(
          recruitWorkerOrdersByPlayerId: {
            WppIds.player1: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
            WppIds.player2: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
          },
        );
        final result = wppApply(game, orders);
        for (final playerId in [WppIds.player1, WppIds.player2]) {
          final p = result.players.firstWhere((p) => p.id == playerId);
          wppExpect(
            p,
            peasants: 1,
            apprentices: 1,
            stock: {CommodityCatalog.paper.id: 2},
            treasury: 100,
          );
        }
  }
}
