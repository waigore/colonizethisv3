// Tests for CivilianUnitsPanel. SPEC/ui/civilian-units-panel.md.
// Concern split under repo.app_test_file_size (Refs #4013, #4352):
// locate icon and cancel-pending-work pins.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_circular_locate_button.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show kWorkTargetBuildImprovement;

import 'civilian_units_panel_cancel_support.dart';
import 'civilian_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerIdWithUnits;

  setUpAll(() {
    game = buildCivilianPanelTestGame();
    humanPlayerIdWithUnits = game.players.first.id;
  });

  group('CivilianUnitsPanel', () {
    testWidgets(
      'Cancel on pending row: Yes removes order; No dismisses without remove',
      (WidgetTester tester) async {
        final idleCivilian = firstIdleCivilian(game, humanPlayerIdWithUnits);
        if (idleCivilian == null) return;

        Future<RemovePendingWorkOrderRequestedEvent?> confirmPending(
          String answer,
        ) async {
          RemovePendingWorkOrderRequestedEvent? removeEvent;
          final bus = AppEventBus.create();
          bus.on<RemovePendingWorkOrderRequestedEvent>().listen((e) {
            removeEvent = e;
          });
          await tester.pumpWidget(
            buildCivilianPanel(
              bus: bus,
              game: game,
              humanPlayerId: humanPlayerIdWithUnits,
              currentOrders: pendingExploreOrders(
                humanPlayerIdWithUnits,
                idleCivilian,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await invokePendingCancel(tester, idleCivilian);
          expect(find.text('Cancel work order?'), findsOneWidget);
          await tester.tap(find.text(answer));
          await tester.pumpAndSettle();
          return removeEvent;
        }

        final removed = await confirmPending('Yes');
        expect(removed, isNotNull);
        expect(removed!.playerId, humanPlayerIdWithUnits);
        expect(removed.index, 0);

        expect(await confirmPending('No'), isNull);
      },
    );

    testWidgets(
      'pending cancel event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final idleCivilian = firstIdleCivilian(game, humanPlayerIdWithUnits);
        if (idleCivilian == null) return;

        final bus = AppEventBus.create();
        final navigatorKey = GlobalKey<NavigatorState>();
        final observedRemovals = ValueNotifier<int>(0);
        final sub = bus.on<RemovePendingWorkOrderRequestedEvent>().listen((_) {
          observedRemovals.value = observedRemovals.value + 1;
        });
        addTearDown(() async {
          await sub.cancel();
          observedRemovals.dispose();
        });

        await tester.pumpWidget(
          civilianPanelWatcherHost(
            bus: bus,
            navigatorKey: navigatorKey,
            counter: observedRemovals,
            labelPrefix: 'observed-removals',
            game: game,
            humanId: humanPlayerIdWithUnits,
            orders: pendingExploreOrders(humanPlayerIdWithUnits, idleCivilian),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-removals:0'), findsOneWidget);

        await invokePendingCancel(tester, idleCivilian);
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('observed-removals:1'), findsOneWidget);
      },
    );

    testWidgets(
      'in-progress cancel event can drive external watcher updates (cross-panel style)',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final navigatorKey = GlobalKey<NavigatorState>();
        final observedCancels = ValueNotifier<int>(0);
        final sub = bus.on<CancelInProgressCivilianWorkRequestedEvent>().listen(
          (_) {
            observedCancels.value = observedCancels.value + 1;
          },
        );
        addTearDown(() async {
          await sub.cancel();
          observedCancels.dispose();
        });

        final workingCivilians =
            [
              ...game.worldState.oldWorld.units,
              ...game.worldState.newWorld.units,
            ].where(
              (u) =>
                  u.ownerId == humanPlayerIdWithUnits &&
                  u.tileKey != null &&
                  isCivilianUnit(u) &&
                  u.currentWork != null,
            );
        if (workingCivilians.isEmpty) return;

        await tester.pumpWidget(
          civilianPanelWatcherHost(
            bus: bus,
            navigatorKey: navigatorKey,
            counter: observedCancels,
            labelPrefix: 'observed-cancels',
            game: game,
            humanId: humanPlayerIdWithUnits,
            orders: const Orders(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('observed-cancels:0'), findsOneWidget);

        final cancelButtons = find.text('Cancel');
        if (cancelButtons.evaluate().isEmpty) return;
        await tester.tap(cancelButtons.first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('observed-cancels:1'), findsOneWidget);
      },
    );
  });
}
