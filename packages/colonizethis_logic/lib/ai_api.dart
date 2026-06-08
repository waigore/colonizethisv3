/// Explicit logic surface consumed by `colonizethis_ai`.
///
/// This library intentionally avoids exporting the full logic barrel so AI can
/// depend on narrow contracts only.
library;

export 'package:colonizethis_world/src/world/ai_control.dart'
    show isAiControlled;
export 'src/ai/full_ai_civilian_work_ow_feedstock_localization.dart'
    show
        ColocatedFeedstockProspectIntraPassGates,
        colocatedMineralEligibleUnprospectedOldWorldFeedstockProspectIntraPassGates,
        hasIdleExplorerUnit,
        ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile,
        ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile,
        ownsProspectedOldWorldMineralFeedstockTile,
        suggestsProspectForColocatedMineralEligibleUnprospectedOldWorldFeedstockTile;
export 'src/orders/feedstock_bootstrap_cost.dart'
    show
        feedstockBootstrapBuildImprovementCastIronWaived,
        feedstockBootstrapBuildImprovementEffectiveCost,
        feedstockBootstrapBuildImprovementLumberWaived;
export 'src/ai/full_ai_civilian_work_selection.dart'
    show
        FullAiCivilianWorkIdle,
        FullAiCivilianWorkSelectionResult,
        kRegimentBuildInputFeedstockExtractionScoreBoost,
        selectFullAiCivilianWorkOrders,
        selfLockRecoverySellerStageableImprovementInputs,
        sellerFeedstockTileAcquisitionTarget,
        sellerFeedstockTileAcquisitionTargetProvinceIdsSorted,
        sellerFeedstockTileAcquisitionTargetsAmongAcquirable,
        sellerNeedsImprovementInputFeedstockTileAcquisition;
export 'src/orders/feedstock_extraction_targets.dart'
    show
        feedstockExtractionResourceIdsForPlayer,
        peerLockRecoverySellerNeededProducibleImprovementInputs,
        regimentBuildInputFeedstockExtractionResourceIds,
        regimentBuildInputFeedstockImprovementInputCost,
        selfLockRecoverySellerNeededProducibleImprovementInputs,
        sellerImprovementInputFeedstockExtractionResourceIds,
        supplierImprovementInputFeedstockExtractionResourceIds;
export 'src/ai/simple_ai_heuristics.dart' show turnSeedForPlayer;
export 'src/constants.dart'
    show
        GamePlayerLookup,
        kMineralResourceIds,
        kWorkTargetBuildImprovement,
        kWorkTargetCounterSpy,
        kWorkTargetPurchaseLand,
        kWorkTargetStealTech;
export 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_relation_lookup.dart'
    show
        getOverture,
        getRelation,
        greatPowerPowerScore,
        joinEmpireCostForMinorOrTribe,
        oldWorldProvinceCountOwnedBy,
        provinceCountOwnedBy,
        relationScoreMinFriendly,
        shipCountForFaction;
export 'package:colonizethis_diplomacy/src/diplomacy/diplomacy_resolver.dart'
    show DiplomacyFactionMembership;
export 'src/orders/incremental_candidate_validator.dart'
    show IncrementalCandidateValidator;
export 'src/orders/order_suggestion_move_army.dart'
    show armyMoveCandidateDestinationProvinceIds;
export 'package:colonizethis_world/src/world/movement.dart'
    show neighborProvinceIdsInRegion;
export 'package:colonizethis_economy/src/economy/world_market/bid_type_cap.dart'
    show kWorldMarketBaselineBidTypeCap, worldMarketBidTypeCap;
export 'package:colonizethis_economy/src/economy/economy_riches_to_treasury.dart'
    show pendingRichesTreasuryDelta;
export 'package:colonizethis_economy/src/economy/sea_transport.dart'
    show cargoHoldsForHomeFleet;
export 'package:colonizethis_economy/src/economy/trade_cargo_capacity.dart'
    show tradeCargoCapacityForGreatPower;
export 'package:colonizethis_economy/src/economy/world_market/treasury_bid_budget.dart'
    show carryForwardBidNotionalByPlayer, effectiveMarketPriceForCommodityId;
export 'src/turn/pending_treasury_costs.dart' show pendingTreasuryCostsForTurn;
export 'package:colonizethis_economy/src/economy/worker_economy.dart'
    show effectiveLabourForWorkers;
export 'package:colonizethis_economy/src/economy/worker_action_cost.dart'
    show canAffordRecruitWorker;
export 'src/orders/draft_orders_mutations.dart'
    show applyArmyMoveOrderForPlayer;
export 'package:colonizethis_diplomacy/src/diplomacy/known_diplomatic_targets.dart'
    show knownDiplomaticTargetFactionIds;
export 'src/orders/order_suggestion_helpers.dart'
    show
        filterArmyMoveOrdersByDiplomacy,
        filterMoveOrdersByDiplomacy,
        getProvinceOwnerMap;
export 'package:colonizethis_world/src/trace/turn_trace_contracts.dart'
    show TurnTraceAiSection;
export 'package:colonizethis_world/src/world/army_commands.dart'
    show applyArmySplit;
export 'package:colonizethis_world/src/world/army_ids.dart' show homeArmyIdFor;
export 'package:colonizethis_world/src/world/player_view.dart'
    show PlayerView, VisibilityLevel, buildPlayerView;
export 'package:colonizethis_world/src/world/sea_reachable_provinces.dart'
    show
        reachableNonOwnedProvinceDistancesViaSeas,
        reachableNonOwnedProvinceIdsViaSeas;
export 'package:colonizethis_world/src/world/province_lookup.dart'
    show allProvinces;
export 'package:colonizethis_world/src/world/unit_lookup.dart'
    show
        WorldStateUnitLookup,
        allUnitsFromWorld,
        regimentTypeCountsForPlayer,
        shipTypeCountsForPlayer,
        unitsByIdFromWorld;
