import 'package:colonizethis_test/test.dart';
import 'package:riverpod/riverpod.dart';

import 'package:colonizethis_logic/src/di/logic_providers.dart';
import 'package:colonizethis_world/src/event_bus/game_event_bus.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_api_impl.dart';

void main() {
  group('logic_providers', () {
    test('orderSuggestionApiProvider exposes DefaultOrderSuggestionAPI', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(orderSuggestionApiProvider),
        const DefaultOrderSuggestionAPI(),
      );
    });

    test('gameEventBusProvider exposes DefaultGameEventBus', () {
      final container = ProviderContainer();
      final bus = container.read(gameEventBusProvider);
      addTearDown(() {
        (bus as DefaultGameEventBus).dispose();
        container.dispose();
      });

      expect(bus, isA<DefaultGameEventBus>());
    });

    test('gameEventBusProvider reuses the same bus instance', () {
      final container = ProviderContainer();
      final first = container.read(gameEventBusProvider);
      addTearDown(() {
        (first as DefaultGameEventBus).dispose();
        container.dispose();
      });

      final second = container.read(gameEventBusProvider);
      expect(identical(first, second), isTrue);
    });

    test('gameEventBusProvider can be overridden for tests', () {
      final custom = DefaultGameEventBus();
      final container = ProviderContainer(
        overrides: [
          gameEventBusProvider.overrideWithValue(custom),
        ],
      );
      addTearDown(() {
        container.dispose();
        custom.dispose();
      });

      expect(container.read(gameEventBusProvider), same(custom));
    });
  });
}
