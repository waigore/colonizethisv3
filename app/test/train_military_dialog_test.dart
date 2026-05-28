import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    game = getDebugInitGameResult().game;
    humanPlayerId = game.players.isNotEmpty
        ? game.players.firstWhere((p) => p.isHuman).id
        : game.players.first.id;
  });

  Player getPlayer(String pid) {
    return game.players.firstWhere((p) => p.id == pid);
  }

  Game gameWithMilitaryResources() {
    final player = getPlayer(humanPlayerId);
    final techUnlocked = Map<String, bool>.from(player.techUnlocked ?? {});
    for (final techId in unlockingTechByRegimentId.values) {
      techUnlocked[techId] = true;
    }
    return game.copyWith(
      players: [
        player.copyWith(
          treasury: 10000,
          workerPool: player.workerPool.copyWith(peasants: 20),
          techUnlocked: techUnlocked,
          stockpile: player.stockpile.merge(
            const Stockpile(
              quantities: {
                'fabric': 100,
                'castIron': 100,
                'lumber': 100,
                'horses': 100,
                'steel': 100,
                'bronze': 100,
              },
            ),
          ),
        ),
        ...game.players.where((p) => p.id != humanPlayerId),
      ],
    );
  }

  Widget buildDialog({
    required Game game,
    required String humanPlayerId,
    Orders currentOrders = const Orders(),
    AppEventBus? bus,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TrainMilitaryDialog(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          bus: bus ?? AppEventBus.create(),
        ),
      ),
    );
  }

  testWidgets('dialog shows existing military orders in steppers on open', (
    WidgetTester tester,
  ) async {
    final richGame = gameWithMilitaryResources();
    final player = richGame.players.firstWhere((p) => p.id == humanPlayerId);
    final capital = player.capitalProvinceId ?? player.capitalTile?.provinceId;
    expect(capital, isNotNull, reason: 'debug game requires capital');

    final firstRegiment = RegimentEconomyCatalog.all.first.id;
    final orders = Orders(
      buildUnitOrdersByPlayerId: {
        humanPlayerId: [
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
      buildDialog(
        game: richGame,
        humanPlayerId: humanPlayerId,
        currentOrders: orders,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2'), findsWidgets);
  });

  testWidgets('AC: regiment rows show roster display names not type ids', (
    WidgetTester tester,
  ) async {
    final richGame = gameWithMilitaryResources();
    await tester.pumpWidget(
      buildDialog(game: richGame, humanPlayerId: humanPlayerId),
    );
    await tester.pumpAndSettle();

    expect(find.text('Peasant Levies'), findsWidgets);
    expect(find.text('peasant_levies'), findsNothing);
  });

  testWidgets('dialog submits military orders when closed', (
    WidgetTester tester,
  ) async {
    List<BuildUnitOrder>? capturedOrders;
    final richGame = gameWithMilitaryResources();
    final bus = AppEventBus.create();
    final sub = bus.on<TrainMilitaryBuildOrdersCommittedEvent>().listen((e) {
      capturedOrders = e.orders;
    });
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: ctx,
                  builder: (_) => TrainMilitaryDialog(
                    game: richGame,
                    humanPlayerId: humanPlayerId,
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

    final shellScrollable = find.descendant(
      of: find.byType(CtDialogShell),
      matching: find.byType(Scrollable),
    );
    final closeButton = find.text('×');
    await tester.dragUntilVisible(
      closeButton,
      shellScrollable,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(closeButton);
    await tester.tap(closeButton);
    await tester.pumpAndSettle();

    expect(capturedOrders, isNotNull);
    expect(capturedOrders!.length, 2);
    expect(capturedOrders!.every((o) => o.isMilitary), isTrue);
  });

  testWidgets('military panel train opens train military dialog via bus', (
    WidgetTester tester,
  ) async {
    final richGame = gameWithMilitaryResources();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentGameProvider.overrideWith(() => CurrentGameNotifier(richGame)),
          currentOrdersProvider.overrideWith(
            () => CurrentOrdersNotifier(const Orders()),
          ),
          appEventBusProvider.overrideWith((ref) {
            final bus = AppEventBus.create();
            ref.onDispose(bus.dispose);
            return bus;
          }),
        ],
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return MilitaryUnitsPanel(
                    game: richGame,
                    humanPlayerId: humanPlayerId,
                    bus: ref.watch(appEventBusProvider),
                    topology: const MapTopology(),
                    draftOrders: ref.watch(currentOrdersProvider),
                  );
                },
              ),
            ),
          ),
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
