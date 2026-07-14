// JSON emission and structural assertions for the S7-D campaign (Refs #3997).

import 'dart:convert';

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:logger/logger.dart';

import 'diagnostic_json.dart';
import 'lock_recovery_probes.dart';
import 's7d_campaign_rollup.dart';

/// Emits the unchanged diagnostic payload after a campaign has completed.
extension Seed42S7dCampaignEmission on Seed42S7dCampaignRollup {
  void emitDiagnostic({
    required Map<String, int> gains,
    required Map<String, int> owStart,
  }) {
    // Structured JSON dump for inclusion in the S7-D diagnostic note.
    final diagnostic = <String, Object?>{
      'issue': 2847,
      'subtask': 'S7-D',
      'seed': 42,
      'turns': 100,
      'gpOwGain': gains,
      'gpOwStart': owStart,
      'gpPhaseTurnCount': {
        for (final gpId in gpIds)
          gpId: {
            for (final entry in phaseCounts[gpId]!.entries)
              entry.key.name: entry.value,
          },
      },
      'gpDeclareWarPickDistribution': declareWarPicks,
      'gpExpandPeacePickDistribution': peaceTargetPicks,
      'gpExpandEconomyArmCounts': economyArmCounts,
      'gpInvadableEmptyTurns': invadableEmptyTurns,
      'gpAtWarTurnsByPeer': atWarTurnsByPeer,
      'gpTreasuryUnderCheapestRegimentTurns': treasuryUnderCheapestTurns,
      'gpTreasuryAtOrAboveCheapestRegimentTurns':
          treasuryAtOrAboveCheapestTurns,
      'gpRegimentPeak': regimentPeak,
      'gpRegimentTurnsAtZero': regimentTurnsAtZero,
      'gpMilitaryBuildOrdersEmitted': militaryBuildOrdersEmitted,
      'gpCheapestRegimentInputsInStockpileTurns': fabricInStockpileTurns,
      'gpRebuildReadyTurns': rebuildReadyTurns,
      'gpRebuildReadyNoBuildTurns': rebuildReadyNoBuildTurns,
      'gpRebuildReadyNoBuildMissingInputTurns':
          rebuildReadyNoBuildMissingInputTurns,
      'gpRebuildReadyNoBuildInputsPresentTurns':
          rebuildReadyNoBuildInputsPresentTurns,
      'regimentInputCommodityIds': regimentInputCommodityIds.toList()..sort(),
      'gpRegimentInputBidsEmitted': regimentInputBidsEmitted,
      'gpRegimentInputDealsAsBuyer': regimentInputDealsAsBuyer,
      'improvementInputCommodityIds': improvementInputCommodityIds.toList()
        ..sort(),
      'gpImprovementInputOffersEmitted': improvementInputOffersEmitted,
      'gpImprovementInputBidsEmitted': improvementInputBidsEmitted,
      'gpImprovementInputDealsAsBuyer': improvementInputDealsAsBuyer,
      'gpImprovementInputHeldAtTurn99': improvementInputHeldAtTurn99,
      'castIronFeedstockCommodityIds': castIronFeedstockIds.toList()..sort(),
      'gpCastIronFeedstockOffersEmitted': castIronFeedstockOffersEmitted,
      'gpCastIronFeedstockBidsEmitted': castIronFeedstockBidsEmitted,
      'gpCastIronFeedstockDealsAsBuyer': castIronFeedstockDealsAsBuyer,
      'gpCastIronProductionAssignedTurns': castIronProductionAssignedTurns,
      'gpFabricProductionAssignedTurns': fabricProductionAssignedTurns,
      'gpSupplierFeedstockExtractionGateActiveTurns':
          supplierFeedstockExtractionGateActiveTurns,
      'gpSupplierActiveUnimprovedCastIronFeedstockTileTurns':
          supplierActiveUnimprovedCastIronFeedstockTileTurns,
      'gpSupplierIdleExplorerPresentTurns': supplierIdleExplorerPresentTurns,
      'gpSupplierProspectedMineralFeedstockTileTurns':
          supplierProspectedMineralFeedstockTileTurns,
      'gpSupplierIdleExplorerColocatedFeedstockTileTurns':
          supplierIdleExplorerColocatedFeedstockTileTurns,
      'gpSupplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns':
          supplierIdleExplorerColocatedMineralEligibleFeedstockTileTurns,
      'gpSupplierIdleExplorerColocatedSuggestedProspectTileTurns':
          supplierIdleExplorerColocatedSuggestedProspectTileTurns,
      'gpSupplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns':
          supplierIdleExplorerColocatedFeedstockProspectProvinceVisibleTurns,
      'gpSupplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns':
          supplierIdleExplorerColocatedFeedstockProspectBundledMoveLegTurns,
      'gpSupplierIdleExplorerColocatedFeedstockProspectValidatorTurns':
          supplierIdleExplorerColocatedFeedstockProspectValidatorTurns,
      'gpCastIronFeedstockHeldAtTurn99': castIronFeedstockHeldAtTurn99,
      'gpLumberHeldAtTurn99': lumberHeldAtTurn99,
      'gpCastIronHeldAtTurn99': castIronHeldAtTurn99,
      'fabricFeedstockCommodityIds': fabricFeedstockIds.toList()..sort(),
      'gpFeedstockExtractionGateActiveTurns':
          feedstockExtractionGateActiveTurns,
      'gpUnimprovedFeedstockTileOwnedTurns': unimprovedFeedstockTileOwnedTurns,
      'gpFeedstockGateIdleBuilderPresentTurns':
          feedstockGateIdleBuilderPresentTurns,
      'gpFeedstockGateImprovedTileOwnedTurns':
          feedstockGateImprovedTileOwnedTurns,
      'gpFeedstockGateValidBuildImprovementCandidateTurns':
          feedstockGateValidBuildImprovementCandidateTurns,
      'gpFeedstockGateImprovementCostAffordableTurns':
          feedstockGateImprovementCostAffordableTurns,
      'gpFeedstockGateImprovementLumberAffordableTurns':
          feedstockGateImprovementLumberAffordableTurns,
      'gpFeedstockGateImprovementCastIronAffordableTurns':
          feedstockGateImprovementCastIronAffordableTurns,
      'gpFeedstockAcquisitionTargetActiveTurns':
          feedstockAcquisitionTargetActiveTurns,
      'gpFeedstockAcquisitionTargetWithFieldArmyTurns':
          feedstockAcquisitionTargetWithFieldArmyTurns,
      'gpFeedstockInStockpileTurns': feedstockInStockpileTurns,
      'gpFabricRecipeFeasibleTurns': fabricRecipeFeasibleTurns,
      'gpFabricRecipeLabourFeasibleTurns': fabricRecipeLabourFeasibleTurns,
      'gpCastIronRecipeFeasibleTurns': castIronRecipeFeasibleTurns,
      'gpCastIronRecipeLabourFeasibleTurns': castIronRecipeLabourFeasibleTurns,
      'gpCastIronFeasibleOwnsFeedstockTileTurns':
          castIronFeasibleOwnsFeedstockTileTurns,
      'gpCastIronLabourFoodStarvedTurns': castIronLabourFoodStarvedTurns,
      'gpCastIronLabourPopulationBoundTurns':
          castIronLabourPopulationBoundTurns,
      'gpCastIronLabourPeasantRecruitGateTurns':
          castIronLabourPeasantRecruitGateTurns,
      'gpCastIronLabourPeasantRecruitAffordableTurns':
          castIronLabourPeasantRecruitAffordableTurns,
      'gpCastIronLabourPeasantRecruitFabricStarvedTurns':
          castIronLabourPeasantRecruitFabricStarvedTurns,
      'gpCastIronLabourPeasantRecruitMarketFabricStarvedTurns':
          castIronLabourPeasantRecruitMarketFabricStarvedTurns,
      'gpCastIronLabourPeasantRecruitMarketFabricUnofferedTurns':
          castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
      'gpCastIronLabourPeasantRecruitFabricBidEmittedTurns':
          castIronLabourPeasantRecruitFabricBidEmittedTurns,
      'gpCastIronLabourPeasantRecruitFabricBidAbsentTurns':
          castIronLabourPeasantRecruitFabricBidAbsentTurns,
      'gpCastIronLabourPeasantRecruitFabricDealAsBuyerTurns':
          castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
      'gpCastIronMarketOfferPresentTurns': castIronMarketOfferPresentTurns,
      'gpCastIronMarketOfferAbsentTurns': castIronMarketOfferAbsentTurns,
      'gpFabricMarketOfferPresentTurns': fabricMarketOfferPresentTurns,
      'gpFabricMarketOfferAbsentTurns': fabricMarketOfferAbsentTurns,
      'gpCastIronFeedstockExtractionLabourFutileTurns':
          castIronFeedstockExtractionLabourFutileTurns,
      'castIronMinLabourPerOutput': castIronMinLabourPerOutput,
      'gpTurn99Snapshot': lastSnapshotFields,
    };

    // Refs #2924 Step 0 — lock-recovery JSON (builder in support/s7d).
    final lockRecoveryDiagnostic = buildSeed42S7dLockRecoveryDiagnosticJson(
      gpIds: gpIds,
      tradeOfferCount: tradeOfferCount,
      tradeUrgentOfferCount: tradeUrgentOfferCount,
      tradeBidCount: tradeBidCount,
      dealsAsSeller: dealsAsSeller,
      dealsAsBuyer: dealsAsBuyer,
      treasuryCredited: treasuryCredited,
      treasuryDebited: treasuryDebited,
      regimentThresholdCrossingsUp: regimentThresholdCrossingsUp,
      regimentThresholdFirstReachTurn: regimentThresholdFirstReachTurn,
      treasuryUnderCheapestTurns: treasuryUnderCheapestTurns,
      treasuryAtTurn99: treasuryAtTurn99,
    );

    // Re-enable info-level logging so the structured diagnostic JSON
    // surfaces in stdout via the package logger (the simulation above
    // intentionally ran with logging off to suppress planner noise).
    // Routing through `aiLogger` keeps this test compliant with the
    // disallowed-AST `avoid_print_suppression` rule while preserving
    // greppable BEGIN/END markers for issue-comment transcription.
    CtLogger.level = Level.info;
    final log = aiLogger('s7d-diagnostic');
    log.i('S7D_DIAGNOSTIC_JSON_BEGIN');
    log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
    log.i('S7D_DIAGNOSTIC_JSON_END');
    log.i('ISSUE2924_STEP0_JSON_BEGIN');
    log.i(const JsonEncoder.withIndent('  ').convert(lockRecoveryDiagnostic));
    log.i('ISSUE2924_STEP0_JSON_END');

    // Lightweight assertion: data was actually collected. The diagnostic
    // does not pin arm-fire counts so the planner can be tuned freely
    // in S7-T without churn here. The structural invariants over the
    // per-GP counter maps are asserted by the extracted support helper
    // (kept out of this file for the non-comment line-size budget).
    assertSeed42S7dStructuralInvariants(
      gpIds: gpIds,
      phaseCounts: phaseCounts,
      rebuildReadyNoBuildTurns: rebuildReadyNoBuildTurns,
      rebuildReadyNoBuildMissingInputTurns:
          rebuildReadyNoBuildMissingInputTurns,
      rebuildReadyNoBuildInputsPresentTurns:
          rebuildReadyNoBuildInputsPresentTurns,
      feedstockExtractionGateActiveTurns: feedstockExtractionGateActiveTurns,
      feedstockGateIdleBuilderPresentTurns:
          feedstockGateIdleBuilderPresentTurns,
      feedstockGateImprovedTileOwnedTurns: feedstockGateImprovedTileOwnedTurns,
      feedstockGateValidBuildImprovementCandidateTurns:
          feedstockGateValidBuildImprovementCandidateTurns,
      feedstockGateImprovementCostAffordableTurns:
          feedstockGateImprovementCostAffordableTurns,
      feedstockGateImprovementLumberAffordableTurns:
          feedstockGateImprovementLumberAffordableTurns,
      feedstockGateImprovementCastIronAffordableTurns:
          feedstockGateImprovementCastIronAffordableTurns,
      feedstockAcquisitionTargetActiveTurns:
          feedstockAcquisitionTargetActiveTurns,
      feedstockAcquisitionTargetWithFieldArmyTurns:
          feedstockAcquisitionTargetWithFieldArmyTurns,
      castIronLabourPeasantRecruitGateTurns:
          castIronLabourPeasantRecruitGateTurns,
      castIronLabourPeasantRecruitAffordableTurns:
          castIronLabourPeasantRecruitAffordableTurns,
      castIronLabourPeasantRecruitFabricStarvedTurns:
          castIronLabourPeasantRecruitFabricStarvedTurns,
      castIronLabourPeasantRecruitMarketFabricStarvedTurns:
          castIronLabourPeasantRecruitMarketFabricStarvedTurns,
      castIronLabourPeasantRecruitMarketFabricUnofferedTurns:
          castIronLabourPeasantRecruitMarketFabricUnofferedTurns,
      castIronLabourPeasantRecruitFabricBidEmittedTurns:
          castIronLabourPeasantRecruitFabricBidEmittedTurns,
      castIronLabourPeasantRecruitFabricBidAbsentTurns:
          castIronLabourPeasantRecruitFabricBidAbsentTurns,
      castIronLabourPeasantRecruitFabricDealAsBuyerTurns:
          castIronLabourPeasantRecruitFabricDealAsBuyerTurns,
      fabricRecipeFeasibleTurns: fabricRecipeFeasibleTurns,
      fabricRecipeLabourFeasibleTurns: fabricRecipeLabourFeasibleTurns,
      castIronMarketOfferPresentTurns: castIronMarketOfferPresentTurns,
      castIronMarketOfferAbsentTurns: castIronMarketOfferAbsentTurns,
      castIronFeedstockExtractionLabourFutileTurns:
          castIronFeedstockExtractionLabourFutileTurns,
    );
  }
}
