/// Narrow export for AI composition. Includes interface + default implementation.
/// SPEC/program/dependency-injection.md.
library;

export 'package:colonizethis_economy/src/economy/world_market/trade_order_suggester.dart'
    show TradeOrderSuggester, TradeSuggestionContext, TradeSuggestionResult;
export 'package:colonizethis_orders/src/orders/order_suggestion_api.dart';
export 'package:colonizethis_orders/src/orders/order_suggestion_api_impl.dart'
    show DefaultOrderSuggestionAPI;
export 'package:colonizethis_orders/src/orders/order_resolution_context.dart'
    show
        OrderResolutionContext,
        buildOrderResolutionContext,
        orderResolutionContextFromView;
export 'package:colonizethis_orders/src/orders/diplomatic_panel_actions.dart'
    show
        DiplomaticPanelAction,
        diplomaticPanelActionCandidates,
        enumerateDiplomaticPanelActionsForTarget,
        kDiplomaticPanelOvertureStages;
export 'package:colonizethis_diplomacy/src/diplomacy/known_diplomatic_targets.dart'
    show knownDiplomaticTargetFactionIds;
export 'package:colonizethis_diplomacy/src/diplomacy/gp_tribe_first_contact.dart'
    show
        GpTribeFirstContactResult,
        applyGpTribeFirstContactRelations,
        discoveredTribeIdsForFirstContact;
