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
/// - The remaining deep `src/` exports are for symbols the domain barrel does
///   not (yet) publish; each is grouped and justified at the bottom of this file
///   and stays deep only until a future Phase 1 barrel-bypass slice promotes the
///   file into its domain barrel.
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
        regimentTypeCountsForPlayer,
        shipTypeCountsForPlayer,
        unitsByIdFromWorld;

// colonizethis_orders (barrel-level re-exports).
export 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        IncrementalCandidateValidator,
        applyArmyMoveOrderForPlayer,
        armyMoveCandidateDestinationProvinceIds,
        filterArmyMoveOrdersByDiplomacy,
        filterMoveOrdersByDiplomacy,
        getProvinceOwnerMap;

// colonizethis_economy (barrel-level re-exports).
export 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        canAffordRecruitWorker,
        cargoHoldsForHomeFleet,
        carryForwardBidNotionalByPlayer,
        effectiveLabourForWorkers,
        effectiveMarketPriceForCommodityId,
        kWorldMarketBaselineBidTypeCap,
        pendingRichesTreasuryDelta,
        tradeCargoCapacityForGreatPower,
        worldMarketBidTypeCap;

// colonizethis_diplomacy (barrel-level re-exports).
export 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show
        DiplomacyFactionMembership,
        getOverture,
        getRelation,
        greatPowerPowerScore,
        joinEmpireCostForMinorOrTribe,
        knownDiplomaticTargetFactionIds,
        oldWorldProvinceCountOwnedBy,
        provinceCountOwnedBy,
        relationScoreMinFriendly,
        shipCountForFaction;

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
        kWorkTargetPurchaseLand,
        kWorkTargetStealTech;

// Justified deep `src/` exports — no domain-barrel alternative (Refs #3393
// Phase 3). Each symbol below is required by `colonizethis_ai` but is not yet
// published by its domain package barrel, so a deep `src/` export is the only
// available contract surface. These stay deep until a Phase 1 barrel-bypass
// slice promotes the owning file into the domain barrel; `repo.ai_api_narrow_surface`
// permits them precisely because the barrel does not re-export these files.
export 'package:colonizethis_orders/src/orders/feedstock_bootstrap_cost.dart'
    show
        feedstockBootstrapBuildImprovementCastIronWaived,
        feedstockBootstrapBuildImprovementEffectiveCost,
        feedstockBootstrapBuildImprovementLumberWaived;
export 'package:colonizethis_orders/src/orders/feedstock_extraction_targets.dart'
    show
        feedstockExtractionResourceIdsForPlayer,
        peerLockRecoverySellerNeededProducibleImprovementInputs,
        regimentBuildInputFeedstockExtractionResourceIds,
        regimentBuildInputFeedstockImprovementInputCost,
        selfLockRecoverySellerNeededProducibleImprovementInputs,
        sellerImprovementInputFeedstockExtractionResourceIds,
        supplierImprovementInputFeedstockExtractionResourceIds;
export 'package:colonizethis_world/src/world/sea_reachable_provinces.dart'
    show
        reachableNonOwnedProvinceDistancesViaSeas,
        reachableNonOwnedProvinceIdsViaSeas;
