import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'train_military_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  final harness = TrainMilitaryDialogTestHarness();

  setUpAll(() async {
    await harness.ensureHandlerHive();
  });

  tearDownAll(() async {
    await harness.closeHandlerHive();
  });

  testWidgets('dialog shows existing military orders in steppers on open', (
    WidgetTester tester,
  ) async {
    final richGame = harness.gameWithMilitaryResources();
    final player = richGame.players.firstWhere(
      (p) => p.id == harness.humanPlayerId,
    );
    final capital = player.capitalProvinceId ?? player.capitalTile?.provinceId;
    expect(capital, isNotNull, reason: 'debug game requires capital');

    final firstRegiment = RegimentEconomyCatalog.all.first.id;
    final orders = Orders(
      buildUnitOrdersByPlayerId: {
        harness.humanPlayerId: [
          BuildUnitOrder(
            unitType: firstRegiment,
            isMilitary: true,
            spawnProvinceId: capital!,
          ),
          BuildUnitOrder(
            unitType: firstRegiment,
            isMilitary: true,
            spawnProvinceId: capital,
          ),
        ],
      },
    );

    await tester.pumpWidget(
      harness.buildDialog(panelGame: richGame, currentOrders: orders),
    );
    await tester.pumpAndSettle();

    expect(find.text('2'), findsWidgets);
  });

  testWidgets('AC: treasury renders with £ + comma grouping (£10,000)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness.buildDialog(panelGame: harness.gameWithMilitaryResources()),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('£10,000'), findsOneWidget);
  });

  testWidgets('AC: regiment rows show roster display names not type ids', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      harness.buildDialog(panelGame: harness.gameWithMilitaryResources()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peasant Levies'), findsWidgets);
    expect(find.text('peasant_levies'), findsNothing);
  });

  testWidgets('dialog submits military orders when closed', (
    WidgetTester tester,
  ) async {
    List<BuildUnitOrder>? capturedOrders;
    final richGame = harness.gameWithMilitaryResources();
    final bus = AppEventBus.create();
    final sub = bus.on<TrainMilitaryBuildOrdersCommittedEvent>().listen((e) {
      capturedOrders = e.orders;
    });
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: ctx,
                  builder: (_) => TrainMilitaryDialog(
                    game: richGame,
                    humanPlayerId: harness.humanPlayerId,
                    currentOrders: const Orders(),
                    bus: bus,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final firstPlus = find.text('+').first;
    await tester.ensureVisible(firstPlus);
    await tester.tap(firstPlus);
    await tester.pumpAndSettle();
    await tester.tap(firstPlus);
    await tester.pumpAndSettle();

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    expect(capturedOrders, isNotNull);
    expect(capturedOrders!.length, 2);
    expect(capturedOrders!.every((o) => o.isMilitary), isTrue);
  });

  testWidgets('military panel train opens train military dialog via bus', (
    WidgetTester tester,
  ) async {
    final richGame = harness.gameWithMilitaryResources();
    await tester.pumpWidget(
      harness.handlerShell(
        panelGame: richGame,
        body: Consumer(
          builder: (context, ref, _) {
            return MilitaryUnitsPanel(
              game: richGame,
              humanPlayerId: harness.humanPlayerId,
              bus: ref.watch(appEventBusProvider),
              topology: const MapTopology(),
              draftOrders: ref.watch(currentOrdersProvider),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainMilitaryDialog), findsOneWidget);
    expect(find.text('Train Military'), findsOneWidget);
  });
}
