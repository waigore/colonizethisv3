/// Narrow export for AI composition. Includes interface + default implementation.
/// SPEC/program/dependency-injection.md.
library;

export 'package:colonizethis_economy/colonizethis_economy.dart'
    show TradeOrderSuggester, TradeSuggestionContext, TradeSuggestionResult;
export 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DefaultOrderSuggestionAPI,
        DiplomaticPanelAction,
        OrderResolutionContext,
        OrderSuggestionAPI,
        buildOrderResolutionContext,
        diplomaticPanelActionCandidates,
        enumerateDiplomaticPanelActionsForTarget,
        kDiplomaticPanelOvertureStages,
        orderResolutionContextFromView;
export 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show
        GpTribeFirstContactResult,
        applyGpTribeFirstContactRelations,
        discoveredTribeIdsForFirstContact,
        knownDiplomaticTargetFactionIds;
