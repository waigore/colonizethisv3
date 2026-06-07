import 'package:riverpod/riverpod.dart';

import 'package:colonizethis_world/src/event_bus/game_event_bus.dart';
import '../orders/order_suggestion_api.dart';
import '../orders/order_suggestion_api_impl.dart';

/// Default [OrderSuggestionAPI] for AI and tooling. Override in tests via [ProviderContainer].
final orderSuggestionApiProvider = Provider<OrderSuggestionAPI>((ref) {
  return const DefaultOrderSuggestionAPI();
});

/// Default [GameEventBus] for turn resolution event collection. Override in tests or app.
final gameEventBusProvider = Provider<GameEventBus>((ref) {
  return DefaultGameEventBus();
});
