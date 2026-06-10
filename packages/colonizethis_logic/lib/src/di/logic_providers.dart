import 'package:riverpod/riverpod.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';

/// Default [OrderSuggestionAPI] for AI and tooling. Override in tests via [ProviderContainer].
final orderSuggestionApiProvider = Provider<OrderSuggestionAPI>((ref) {
  return const DefaultOrderSuggestionAPI();
});

/// Default [GameEventBus] for turn resolution event collection. Override in tests or app.
final gameEventBusProvider = Provider<GameEventBus>((ref) {
  return DefaultGameEventBus();
});
