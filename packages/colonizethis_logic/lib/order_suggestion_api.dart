/// Narrow export for AI composition. Includes interface + default implementation.
/// SPEC/program/dependency-injection.md.
library;

export 'src/economy/world_market/trade_order_suggester.dart'
    show TradeOrderSuggester, TradeSuggestionContext, TradeSuggestionResult;
export 'src/orders/order_suggestion_api.dart';
export 'src/orders/order_suggestion_api_impl.dart' show DefaultOrderSuggestionAPI;
export 'src/orders/order_resolution_context.dart'
    show
        OrderResolutionContext,
        buildOrderResolutionContext,
        orderResolutionContextFromView;
export 'src/orders/order_suggestion_helpers.dart'
    show knownDiplomaticTargetFactionIds;
