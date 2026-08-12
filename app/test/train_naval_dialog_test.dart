import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/features/game/widgets/units/naval/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_naval_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'train_naval_dialog_test_support.dart';

void main() {
  suppressLogsForTests();

  late TrainNavalDialogTestHarness harness;

  setUpAll(() {
    harness = TrainNavalDialogTestHarness();
  });

  testWidgets('dialog shows existing naval orders in steppers on open', (
    WidgetTester tester,
  ) async {
    final richGame = harness.gameWithNavalResources();
    final capital = harness.capitalOf(richGame);
    final firstShip = ShipEconomyCatalog.all.first.shipTypeId;
    await harness.pumpDialog(
      tester,
      panelGame: richGame,
      currentOrders: Orders(
        buildUnitOrdersByPlayerId: {
          harness.humanPlayerId: [
            BuildUnitOrder(
              unitType: firstShip,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
            BuildUnitOrder(
              unitType: firstShip,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
          ],
        },
      ),
    );

    expect(find.text('2'), findsWidgets);
  });

  testWidgets('AC: treasury renders with £ + comma grouping (£50,000)', (
    WidgetTester tester,
  ) async {
    await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
    expect(find.textContaining('£50,000'), findsOneWidget);
  });

  testWidgets('AC: ship rows show roster display names not type ids', (
    WidgetTester tester,
  ) async {
    await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
    expect(find.text('Carrack'), findsWidgets);
    expect(find.text(kTechIdShipOfTheLine), findsNothing);
    expect(find.text('Ship of the Line'), findsWidgets);
  });

  group('Train Naval role and capability gist (#4300)', () {
    testWidgets('AC: Carrack row shows Merchant and cargo holds', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
      expect(
        find.text(
          'Merchant · +${NavalStatsCatalog.carrack.cargoHold} cargo holds',
        ),
        findsWidgets,
      );
    });

    testWidgets('AC: Sloop row shows Warship and fast interceptor gist', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
      expect(find.text('Warship · Fast interceptor'), findsWidgets);
      expect(find.textContaining('+0 cargo holds'), findsNothing);
    });

    testWidgets('AC: Ship of the Line row shows battle ship gist', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
      expect(find.text('Warship · Battle ship'), findsWidgets);
    });

    testWidgets('AC: locked row keeps muted role/capability with Requires tech', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(
        tester,
        panelGame: harness.gameWithPlayer(
          (player) => player.copyWith(
            treasury: 1000000,
            techUnlocked: const <String, bool>{},
          ),
        ),
      );
      expect(find.textContaining('Requires:'), findsWidgets);
      expect(find.text('Warship · Fast interceptor'), findsWidgets);
    });

    testWidgets('AC (negative): default row omits full combat stat dump', (
      WidgetTester tester,
    ) async {
      await harness.pumpDialog(tester, panelGame: harness.gameWithNavalResources());
      expect(find.textContaining('FRP'), findsNothing);
      expect(find.textContaining('RNG'), findsNothing);
      expect(find.text('Details'), findsNothing);
    });
  });

  testWidgets('AC: dialog submits naval orders (isMilitary false) when closed', (
    WidgetTester tester,
  ) async {
    List<BuildUnitOrder>? capturedOrders;
    final richGame = harness.gameWithNavalResources();
    final bus = AppEventBus.create();
    final sub = bus.on<TrainNavalBuildOrdersCommittedEvent>().listen((e) {
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
                  builder: (_) => TrainNavalDialog(
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

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    expect(capturedOrders, isNotNull);
    expect(capturedOrders!.length, 1);
    expect(capturedOrders!.every((o) => !o.isMilitary), isTrue);
    expect(
      capturedOrders!.every((o) => o.spawnProvinceId == harness.capitalOf(richGame)),
      isTrue,
    );
    expect(
      ShipEconomyCatalog.byId.containsKey(capturedOrders!.first.unitType),
      isTrue,
    );
  });

  testWidgets('naval panel train opens train naval dialog via bus', (
    WidgetTester tester,
  ) async {
    final richGame = harness.gameWithNavalResources();
    await tester.pumpWidget(
      harness.handlerShell(
        panelGame: richGame,
        body: Consumer(
          builder: (context, ref, _) {
            return NavalUnitsPanel(
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

    expect(find.byType(TrainNavalDialog), findsOneWidget);
    expect(find.text('Train Naval'), findsOneWidget);
  });

  testWidgets(
    'AC: naval merge keeps existing civilian train orders untouched',
    (WidgetTester tester) async {
      final richGame = harness.gameWithNavalResources();
      final capital = harness.capitalOf(richGame);
      final civilianType = CivilianEconomyCatalog.all.first.id;
      final initialOrders = Orders(
        buildUnitOrdersByPlayerId: {
          harness.humanPlayerId: [
            BuildUnitOrder(
              unitType: civilianType,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
          ],
        },
      );

      late AppEventBus bus;
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        harness.handlerShell(
          panelGame: richGame,
          orders: initialOrders,
          body: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              bus = ref.watch(appEventBusProvider);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstShip = ShipEconomyCatalog.all.first.shipTypeId;
      bus.emit(
        TrainNavalBuildOrdersCommittedEvent(
          orders: [
            BuildUnitOrder(
              unitType: firstShip,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final merged =
          capturedRef
              .read(currentOrdersProvider)
              .buildUnitOrdersByPlayerId[harness.humanPlayerId] ??
          const <BuildUnitOrder>[];
      expect(
        merged.where((o) => o.unitType == civilianType).length,
        1,
        reason: 'existing civilian build order must be preserved',
      );
      expect(
        merged.where((o) => o.unitType == firstShip).length,
        1,
        reason: 'naval order from dialog must be merged in',
      );
    },
  );
}
