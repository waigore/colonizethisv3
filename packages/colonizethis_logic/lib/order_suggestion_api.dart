/// Narrow export for AI composition. Includes interface + default implementation.
/// SPEC/program/dependency-injection.md.
library;

export 'package:colonizethis_economy/src/economy/world_market/trade_order_suggester.dart'
    show TradeOrderSuggester, TradeSuggestionContext, TradeSuggestionResult;
export 'src/orders/order_suggestion_api.dart';
export 'src/orders/order_suggestion_api_impl.dart'
    show DefaultOrderSuggestionAPI;
export 'src/orders/order_resolution_context.dart'
    show
        OrderResolutionContext,
        buildOrderResolutionContext,
        orderResolutionContextFromView;
export 'src/orders/diplomatic_panel_actions.dart'
    show
        DiplomaticPanelAction,
        diplomaticPanelActionCandidates,
        enumerateDiplomaticPanelActionsForTarget,
        kDiplomaticPanelOvertureStages;
export 'src/diplomacy/known_diplomatic_targets.dart'
    show knownDiplomaticTargetFactionIds;
export 'src/diplomacy/gp_tribe_first_contact.dart'
    show GpTribeFirstContactResult, applyGpTribeFirstContactRelations;
