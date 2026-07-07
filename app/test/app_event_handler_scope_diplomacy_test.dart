import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScopeProbe extends ConsumerWidget {
  const _ScopeProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(currentOrdersProvider);
    return const SizedBox.shrink();
  }
}

void main() {
  suppressLogsForTests();

  setUp(() {
    AppEventBus.reset();
  });

  testWidgets(
    'AppEventHandlerScope applies diplomacy append/remove session commands',
    (tester) async {
      final bus = AppEventBus.create();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appEventBusProvider.overrideWith((ref) {
              ref.onDispose(bus.dispose);
              return bus;
            }),
          ],
          child: const AppEventHandlerScope(
            child: MaterialApp(home: Scaffold(body: _ScopeProbe())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(_ScopeProbe)),
      );

      const playerId = 'gp_human';
      const targetFactionId = 'gp_target';
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: targetFactionId,
      );

      bus.emit(
        AppendDiplomaticOrderRequestedEvent(playerId: playerId, order: order),
      );
      await tester.pumpAndSettle();

      final afterAppend = container.read(currentOrdersProvider);
      final appended = afterAppend.diplomaticOrdersByPlayerId[playerId] ?? [];
      expect(appended, hasLength(1));
      expect(appended.first.type, DiplomaticOrderType.declareWar);
      expect(appended.first.targetFactionId, targetFactionId);

      bus.emit(
        RemoveDiplomaticOrderRequestedEvent(
          playerId: playerId,
          type: DiplomaticOrderType.declareWar,
          targetFactionId: targetFactionId,
        ),
      );
      await tester.pumpAndSettle();

      final afterRemove = container.read(currentOrdersProvider);
      expect(afterRemove.diplomaticOrdersByPlayerId[playerId] ?? [], isEmpty);
    },
  );
}
