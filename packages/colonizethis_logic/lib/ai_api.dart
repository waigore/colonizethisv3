/// Explicit logic surface consumed by `colonizethis_ai`.
///
/// This library intentionally avoids exporting the full logic barrel so AI can
/// depend on narrow contracts only.
library;

export 'src/ai/ai_control.dart' show isAiControlled;
export 'src/ai/full_ai_civilian_work_selection.dart'
    show
        FullAiCivilianWorkIdle,
        FullAiCivilianWorkSelectionResult,
        feedstockBootstrapBuildImprovementCastIronWaived,
        feedstockExtractionResourceIdsForPlayer,
        kRegimentBuildInputFeedstockExtractionScoreBoost,
        regimentBuildInputFeedstockExtractionResourceIds,
        regimentBuildInputFeedstockImprovementInputCost,
        selectFullAiCivilianWorkOrders,
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
export 'src/diplomacy/diplomacy_relation_lookup.dart'
    show
        getOverture,
        getRelation,
        greatPowerPowerScore,
        joinEmpireCostForMinorOrTribe,
        oldWorldProvinceCountOwnedBy,
        provinceCountOwnedBy,
        relationScoreMinFriendly,
        shipCountForFaction;
export 'src/diplomacy/diplomacy_resolver.dart' show DiplomacyFactionMembership;
export 'src/orders/incremental_candidate_validator.dart'
    show IncrementalCandidateValidator;
export 'src/orders/order_suggestion_move_army.dart'
    show armyMoveCandidateDestinationProvinceIds;
export 'src/world/movement.dart' show neighborProvinceIdsInRegion;
export 'src/diplomacy/diplomacy_subsidies_relations_resolver.dart'
    show kWorldMarketBaselineBidTypeCap, worldMarketBidTypeCap;
export 'src/economy/economy_riches_to_treasury.dart'
    show pendingRichesTreasuryDelta;
export 'src/economy/sea_transport.dart' show cargoHoldsForHomeFleet;
export 'src/economy/trade_cargo_capacity.dart'
    show tradeCargoCapacityForGreatPower;
export 'src/economy/world_market/treasury_bid_budget.dart'
    show
        carryForwardBidNotionalByPlayer,
        effectiveMarketPriceForCommodityId;
export 'src/turn/pending_treasury_costs.dart'
    show pendingTreasuryCostsForTurn;
export 'src/economy/worker_economy.dart' show effectiveLabourForWorkers;
export 'src/orders/draft_orders_mutations.dart'
    show applyArmyMoveOrderForPlayer;
export 'src/orders/order_suggestion_helpers.dart'
    show
        filterArmyMoveOrdersByDiplomacy,
        filterMoveOrdersByDiplomacy,
        getProvinceOwnerMap,
        knownDiplomaticTargetFactionIds;
export 'src/turn/trace/turn_trace_contracts.dart' show TurnTraceAiSection;
export 'src/world/army_commands.dart' show applyArmySplit;
export 'src/world/army_ids.dart' show homeArmyIdFor;
export 'src/world/player_view.dart'
    show PlayerView, VisibilityLevel, buildPlayerView;
export 'src/world/sea_reachable_provinces.dart'
    show
        reachableNonOwnedProvinceDistancesViaSeas,
        reachableNonOwnedProvinceIdsViaSeas;
export 'src/world/province_lookup.dart' show allProvinces;
export 'src/world/unit_lookup.dart'
    show
        WorldStateUnitLookup,
        allUnitsFromWorld,
        regimentTypeCountsForPlayer,
        shipTypeCountsForPlayer,
        unitsByIdFromWorld;
