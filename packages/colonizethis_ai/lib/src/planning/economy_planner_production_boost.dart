import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'cast_iron_labour_gate.dart'
    show
        isCastIronLabourPeasantRecruitFabricShort,
        isCastIronLabourPopulationBoundForLockRecoverySeller;
import 'expand_phase_planner.dart' hide cheapestRegimentBuildTreasuryCost;
import 'phase_planner_dispatch.dart';
import 'phase_planner_expand_economy.dart';
import 'ai_commodity_ids.dart';
import 'economy_planner_labour.dart';
import 'planning_imports.dart';
import 'treasury_lock_recovery_seller.dart';

/// Production-boost inputs derived before labour allocation in
/// [runEconomyPlanner].
class EconomyPlannerProductionBoost {
  const EconomyPlannerProductionBoost({
    required this.militaryRebuildCrisis,
    required this.regimentBuildInputProductionBoost,
    required this.boostedBuildInputOutputs,
    required this.supplierReleaseImprovementInputs,
    required this.feedstockReserveOutputIds,
    required this.castIronLabourPeasantRecruitFabricBoost,
  });

  final bool militaryRebuildCrisis;
  final bool regimentBuildInputProductionBoost;
  final Set<String> boostedBuildInputOutputs;
  final Set<String> supplierReleaseImprovementInputs;
  final Set<String> feedstockReserveOutputIds;
  final bool castIronLabourPeasantRecruitFabricBoost;
}

/// Resolves regiment-build and improvement-input production boosts for one
/// economy-planner pass (Refs #2847 / #4310 lib headroom split).
EconomyPlannerProductionBoost resolveEconomyPlannerProductionBoost({
  required Game game,
  required String playerId,
  required Stockpile stockpile,
  required AIWorldSnapshot? snapshot,
  required PhasePlanOutcome? phasePlan,
}) {
  final militaryRebuildCrisis =
      snapshot != null &&
      isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned) &&
      snapshot.threats.atWarWith.isNotEmpty &&
      regimentCountForPlayer(game, playerId) < kStalledMinRegimentCountWhenAtWar;

  final expandEconomy = phasePlan != null
      ? expandEconomyPlanFromPhasePlan(phasePlan)
      : ExpandEconomyPlan.defaultPlan;
  final missingRegimentBuildInputs = missingCheapestRegimentBuildInputIds(
    stockpile,
  );
  final domesticImprovementInputOutputs =
      selfLockRecoverySellerNeededProducibleImprovementInputs(
        game,
        playerId,
      );
  final stageableImprovementInputs =
      selfLockRecoverySellerStageableImprovementInputs(game, playerId);
  final castIronLabourPeasantRecruitFabricBoost =
      isCastIronLabourPopulationBoundForLockRecoverySeller(
        game: game,
        playerId: playerId,
      ) &&
      isCastIronLabourPeasantRecruitFabricShort(stockpile);
  final regimentBuildInputProductionBoost =
      (expandEconomy.forceCheapestRegimentBuild &&
          regimentCountForPlayer(game, playerId) == 0 &&
          missingRegimentBuildInputs.isNotEmpty) ||
      domesticImprovementInputOutputs.isNotEmpty ||
      stageableImprovementInputs.isNotEmpty ||
      castIronLabourPeasantRecruitFabricBoost;
  final boostedBuildInputOutputs = <String>{
    ...missingRegimentBuildInputs,
    ...domesticImprovementInputOutputs,
    ...stageableImprovementInputs,
    if (castIronLabourPeasantRecruitFabricBoost) kAiCommodityIds.fabric,
  };

  final supplierReleaseImprovementInputs =
      isBelowQuotaZeroNwLockRecoverySeller(
        game,
        playerId,
        snapshot: snapshot,
      )
      ? const <String>{}
      : peerLockRecoverySellerNeededProducibleImprovementInputs(
          game,
          excludePlayerId: playerId,
        );

  final feedstockReserveOutputIds = <String>{
    ...multiInputImprovementOutputs(domesticImprovementInputOutputs),
    ...multiInputImprovementOutputs(stageableImprovementInputs),
    ...supplierReleaseImprovementInputs,
  };

  return EconomyPlannerProductionBoost(
    militaryRebuildCrisis: militaryRebuildCrisis,
    regimentBuildInputProductionBoost: regimentBuildInputProductionBoost,
    boostedBuildInputOutputs: boostedBuildInputOutputs,
    supplierReleaseImprovementInputs: supplierReleaseImprovementInputs,
    feedstockReserveOutputIds: feedstockReserveOutputIds,
    castIronLabourPeasantRecruitFabricBoost:
        castIronLabourPeasantRecruitFabricBoost,
  );
}
