/// Explicit logic surface consumed by `colonizethis_ai`.
///
/// This library intentionally avoids exporting the full logic barrel so AI can
/// depend on narrow contracts only (see `colonizethis-logic-ai-decoupling.mdc`).
///
/// SPEC: SPEC/program/logic-package-barrel-contracts.md (Refs #3393 Phase 3 —
/// AI API narrowing). Enforced by repo-lint rule `repo.ai_api_narrow_surface`.
///
/// Narrowing rules:
/// - Sibling-domain symbols are re-exported through the domain **barrel**
///   (`package:colonizethis_<domain>/colonizethis_<domain>.dart`) whenever that
///   barrel already publishes the owning file — never through a deep `src/` path.
/// - As of #4508 (orders wave 9), all `colonizethis_orders` symbols consumed
///   here are barrel-published; no deep `src/` exports remain on this file.
library;

// colonizethis_world (barrel-level re-exports).
export 'package:colonizethis_world/colonizethis_world.dart'
    show
        PlayerView,
        ProvinceOwnerCache,
        TurnTraceAiSection,
        VisibilityLevel,
        WorldStateUnitLookup,
        allProvinces,
        allUnitsFromWorld,
        applyArmySplit,
        buildPlayerView,
        homeArmyIdFor,
        isAiControlled,
        kRegionNewWorld,
        kRegionOldWorld,
        neighborProvinceIdsInRegion,
        reachableNonOwnedProvinceDistancesViaSeas,
        reachableNonOwnedProvinceIdsViaSeas,
        regimentTypeCountsForPlayer,
        shipTypeCountsForPlayer,
        unitsByIdFromWorld;

// colonizethis_orders (barrel-level re-exports).
export 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        IncrementalCandidateValidator,
        applyArmyMoveOrderForPlayer,
        armyMoveCandidateDestinationProvinceIds,
        feedstockBootstrapBuildImprovementCastIronWaived,
        feedstockBootstrapBuildImprovementEffectiveCost,
        feedstockBootstrapBuildImprovementLumberWaived,
        feedstockExtractionResourceIdsForPlayer,
        filterArmyMoveOrdersByDiplomacy,
        filterMoveOrdersByDiplomacy,
        getProvinceOwnerMap,
        peerLockRecoverySellerNeededProducibleImprovementInputs,
        regimentBuildInputFeedstockExtractionResourceIds,
        regimentBuildInputFeedstockImprovementInputCost,
        selfLockRecoverySellerNeededProducibleImprovementInputs,
        sellerImprovementInputFeedstockExtractionResourceIds,
        supplierImprovementInputFeedstockExtractionResourceIds;

// colonizethis_economy (barrel-level re-exports).
export 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        ExtractionTotals,
        boycottedColonySellableCommodityIds,
        canAffordRecruitWorker,
        cargoHoldsForHomeFleet,
        carryForwardBidNotionalByPlayer,
        computeExtractionTotalsForTradeForecast,
        effectiveLabourForWorkers,
        MilitaryNavyFoodCounts,
        effectiveMarketPriceForCommodityId,
        kWorldMarketBaselineBidTypeCap,
        pendingRichesTreasuryDelta,
        tradeCargoCapacityForGreatPower,
        worldMarketBidTypeCap;

// colonizethis_diplomacy (barrel-level re-exports).
export 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show
        DiplomacyFactionMembership,
        favouredTradingPartner,
        getOverture,
        getRelation,
        greatPowerPowerScore,
        hasEmbassyOverture,
        joinEmpireCostForMinorOrTribe,
        knownDiplomaticTargetFactionIds,
        oldWorldProvinceCountOwnedBy,
        provinceCountOwnedBy,
        relationDecayPerTurn,
        relationScoreMinFriendly,
        relationScoreNeutral,
        shipCountForFaction,
        tradeDealRelationBoostBase,
        tradeDealRelationBoostEmbassyBonus,
        tradeDealRelationBoostPerSubsidyPercent;

// colonizethis_turn (barrel-level re-exports).
export 'package:colonizethis_turn/colonizethis_turn.dart'
    show pendingTreasuryCostsForTurn;

// colonizethis_logic local constants. `src/constants.dart` is owned by this thin
// logic package itself (not a sibling domain package), so there is no domain
// barrel to route through; this remains a package-local relative export.
export 'src/constants.dart'
    show
        GamePlayerLookup,
        kMineralResourceIds,
        kWorkTargetBuildImprovement,
        kWorkTargetCounterSpy,
        kWorkTargetPurchaseLand;
