// S7-D diagnostic JSON payload builders (Refs #2847 / #2924 / #3967).
// Split from `seed42_observer_conquest_s7d_diagnostic_test.dart`.

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_ai/src/planning/observer_goal_phase.dart'
    show ObserverGoalPhase;

/// Topical key sets for S7-D diagnostic JSON contracts (Refs #3967).
///
/// Used by thin topical diagnostic tests so feedstock / lock-recovery /
/// conquest-geography surfaces stay independently assertable without
/// re-running the 100-turn campaign.
abstract final class Seed42S7dDiagnosticJsonKeys {
  /// Conquest-geography / EXPAND-arm rollup keys.
  static const Set<String> conquestGeography = {
    'gpOwGain',
    'gpOwStart',
    'gpPhaseTurnCount',
    'gpDeclareWarPickDistribution',
    'gpExpandPeacePickDistribution',
    'gpExpandEconomyArmCounts',
    'gpInvadableEmptyTurns',
    'gpAtWarTurnsByPeer',
    'gpTurn99Snapshot',
  };

  /// Feedstock / castIron / fabric production-chain keys.
  static const Set<String> feedstock = {
    'castIronFeedstockCommodityIds',
    'fabricFeedstockCommodityIds',
    'gpFeedstockExtractionGateActiveTurns',
    'gpUnimprovedFeedstockTileOwnedTurns',
    'gpFeedstockGateIdleBuilderPresentTurns',
    'gpFeedstockGateImprovedTileOwnedTurns',
    'gpFeedstockGateValidBuildImprovementCandidateTurns',
    'gpFeedstockGateImprovementCostAffordableTurns',
    'gpFeedstockAcquisitionTargetActiveTurns',
    'gpCastIronFeedstockOffersEmitted',
    'gpCastIronProductionAssignedTurns',
    'gpFabricProductionAssignedTurns',
    'gpCastIronLabourPeasantRecruitGateTurns',
  };

  /// World-market lock-recovery Step-0 keys (issue #2924).
  static const Set<String> lockRecovery = {
    'cheapestRegimentBuildTreasuryCost',
    'gpTradeOrdersEmitted',
    'gpDealsMatched',
    'gpTreasuryCreditedByDeals',
    'gpTreasuryDebitedByDeals',
    'gpRegimentThresholdCrossingsUp',
    'gpRegimentThresholdFirstReachTurn',
    'gpTreasuryUnderCheapestRegimentTurns',
    'gpTreasuryAtTurn99',
  };
}

/// Builds the #2924 Step-0 lock-recovery diagnostic JSON block.
Map<String, Object?> buildSeed42S7dLockRecoveryDiagnosticJson({
  required List<String> gpIds,
  required Map<String, int> tradeOfferCount,
  required Map<String, int> tradeUrgentOfferCount,
  required Map<String, int> tradeBidCount,
  required Map<String, int> dealsAsSeller,
  required Map<String, int> dealsAsBuyer,
  required Map<String, int> treasuryCredited,
  required Map<String, int> treasuryDebited,
  required Map<String, int> regimentThresholdCrossingsUp,
  required Map<String, int?> regimentThresholdFirstReachTurn,
  required Map<String, int> treasuryUnderCheapestTurns,
  required Map<String, int> treasuryAtTurn99,
  int? cheapestRegimentCost,
}) {
  return <String, Object?>{
    'issue': 2924,
    'step': 'Step 0',
    'seed': 42,
    'turns': 100,
    'cheapestRegimentBuildTreasuryCost':
        cheapestRegimentCost ?? cheapestRegimentBuildTreasuryCost(),
    'gpTradeOrdersEmitted': {
      for (final gpId in gpIds)
        gpId: <String, int>{
          'offers': tradeOfferCount[gpId] ?? 0,
          'urgentOffers': tradeUrgentOfferCount[gpId] ?? 0,
          'bids': tradeBidCount[gpId] ?? 0,
        },
    },
    'gpDealsMatched': {
      for (final gpId in gpIds)
        gpId: <String, int>{
          'asSeller': dealsAsSeller[gpId] ?? 0,
          'asBuyer': dealsAsBuyer[gpId] ?? 0,
        },
    },
    'gpTreasuryCreditedByDeals': treasuryCredited,
    'gpTreasuryDebitedByDeals': treasuryDebited,
    'gpRegimentThresholdCrossingsUp': regimentThresholdCrossingsUp,
    'gpRegimentThresholdFirstReachTurn': regimentThresholdFirstReachTurn,
    'gpTreasuryUnderCheapestRegimentTurns': treasuryUnderCheapestTurns,
    'gpTreasuryAtTurn99': treasuryAtTurn99,
  };
}

/// Builds the conquest-geography subset of the S7-D diagnostic JSON.
///
/// Full campaign rollups still assemble the wider feedstock payload in the
/// diagnostic test; this helper keeps the geography contract independently
/// testable (Refs #3967 step 6).
Map<String, Object?> buildSeed42S7dConquestGeographyDiagnosticJson({
  required List<String> gpIds,
  required Map<String, int> gains,
  required Map<String, int> owStart,
  required Map<String, Map<ObserverGoalPhase, int>> phaseCounts,
  required Map<String, Map<String, int>> declareWarPicks,
  required Map<String, Map<String, int>> peaceTargetPicks,
  required Map<String, Map<String, int>> economyArmCounts,
  required Map<String, int> invadableEmptyTurns,
  required Map<String, Map<String, int>> atWarTurnsByPeer,
  required Map<String, Map<String, Object?>> lastSnapshotFields,
}) {
  return <String, Object?>{
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
    'gpTurn99Snapshot': lastSnapshotFields,
  };
}
