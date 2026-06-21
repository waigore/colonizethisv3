import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/naval_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train_naval_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
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

  Game gameWithNavalResources() {
    final player = getPlayer(humanPlayerId);
    final techUnlocked = Map<String, bool>.from(player.techUnlocked ?? {});
    for (final techId in unlockingTechByShipId.values) {
      techUnlocked[techId] = true;
    }
    return game.copyWith(
      players: [
        player.copyWith(
          treasury: 50000,
          workerPool: player.workerPool.copyWith(peasants: 20),
          techUnlocked: techUnlocked,
          stockpile: player.stockpile.merge(
            const Stockpile(
              quantities: {
                'lumber': 100,
                'fabric': 100,
                'castIron': 100,
                'coal': 100,
              },
            ),
          ),
        ),
        ...game.players.where((p) => p.id != humanPlayerId),
      ],
    );
  }

  String capitalOf(Game g) {
    final player = g.players.firstWhere((p) => p.id == humanPlayerId);
    return (player.capitalProvinceId ?? player.capitalTile?.provinceId)!;
  }

  Widget buildDialog({
    required Game game,
    required String humanPlayerId,
    Orders currentOrders = const Orders(),
    AppEventBus? bus,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: TrainNavalDialog(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          bus: bus ?? AppEventBus.create(),
        ),
      ),
    );
  }

  testWidgets('dialog shows existing naval orders in steppers on open', (
    WidgetTester tester,
  ) async {
    final richGame = gameWithNavalResources();
    final capital = capitalOf(richGame);
    final firstShip = ShipEconomyCatalog.all.first.shipTypeId;
    final orders = Orders(
      buildUnitOrdersByPlayerId: {
        humanPlayerId: [
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

  testWidgets('AC: treasury renders with £ + comma grouping (£50,000)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDialog(game: gameWithNavalResources(), humanPlayerId: humanPlayerId),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('£50,000'), findsOneWidget);
  });

  testWidgets('AC: ship rows show roster display names not type ids', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildDialog(game: gameWithNavalResources(), humanPlayerId: humanPlayerId),
    );
    await tester.pumpAndSettle();

    expect(find.text('Carrack'), findsWidgets);
    expect(find.text(kTechIdShipOfTheLine), findsNothing);
    expect(find.text('Ship of the Line'), findsWidgets);
  });

  testWidgets(
    'AC: dialog submits naval orders (isMilitary false) when closed',
    (WidgetTester tester) async {
      List<BuildUnitOrder>? capturedOrders;
      final richGame = gameWithNavalResources();
      final bus = AppEventBus.create();
      final sub = bus.on<TrainNavalBuildOrdersCommittedEvent>().listen((e) {
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
                    builder: (_) => TrainNavalDialog(
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
      expect(capturedOrders!.length, 1);
      expect(capturedOrders!.every((o) => !o.isMilitary), isTrue);
      expect(
        capturedOrders!.every((o) => o.spawnProvinceId == capitalOf(richGame)),
        isTrue,
      );
      expect(
        ShipEconomyCatalog.byId.containsKey(capturedOrders!.first.unitType),
        isTrue,
      );
    },
  );

  testWidgets('naval panel train opens train naval dialog via bus', (
    WidgetTester tester,
  ) async {
    final richGame = gameWithNavalResources();
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
                  return NavalUnitsPanel(
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

    expect(find.byType(TrainNavalDialog), findsOneWidget);
    expect(find.text('Train Naval'), findsOneWidget);
  });

  testWidgets(
    'AC: naval merge keeps existing civilian train orders untouched',
    (WidgetTester tester) async {
      final richGame = gameWithNavalResources();
      final capital = capitalOf(richGame);
      final civilianType = CivilianEconomyCatalog.all.first.id;
      final initialOrders = Orders(
        buildUnitOrdersByPlayerId: {
          humanPlayerId: [
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
        ProviderScope(
          overrides: [
            currentGameProvider.overrideWith(
              () => CurrentGameNotifier(richGame),
            ),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(initialOrders),
            ),
            appEventBusProvider.overrideWith((ref) {
              final b = AppEventBus.create();
              ref.onDispose(b.dispose);
              return b;
            }),
          ],
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    capturedRef = ref;
                    bus = ref.watch(appEventBusProvider);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
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
          capturedRef.read(currentOrdersProvider).buildUnitOrdersByPlayerId[humanPlayerId] ??
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

  // Issue #3601 R1–R3 / R4: dynamic remaining/total resource display, red
  // insufficient-cost item styling, and red disabled `[+]` button styling on
  // the naval dialog.
  group('TrainNavalDialog affordance feedback (#3601)', () {
    int redCostLabels(WidgetTester tester) {
      final digits = RegExp(r'^\d+$');
      return tester.widgetList<Text>(find.byType(Text)).where((t) {
        final data = t.data;
        if (data == null || !digits.hasMatch(data)) return false;
        return t.style?.color == EditorialMonoclePalette.danger;
      }).length;
    }

    Iterable<CtNinePatchButton> plusButtons(WidgetTester tester) {
      return tester.widgetList<CtNinePatchButton>(
        find.byWidgetPredicate(
          (w) => w is CtNinePatchButton &&
              w.child is Text &&
              (w.child as Text).data == '+',
        ),
      );
    }

    Orders carrackOrders(Game g, int count) {
      final capital = capitalOf(g);
      return Orders(
        buildUnitOrdersByPlayerId: {
          humanPlayerId: [
            for (var i = 0; i < count; i++)
              BuildUnitOrder(
                unitType: ShipEconomyCatalog.carrack.shipTypeId,
                isMilitary: false,
                spawnProvinceId: capital,
              ),
          ],
        },
      );
    }

    testWidgets('AC (positive): resource bar chips show remaining / total', (
      WidgetTester tester,
    ) async {
      // Treasury 50000, peasants 20; carrack costs £8,000 + 1 peasant. Queue 1
      // → treasury 42,000 / 50,000 and peasants 19 / 20.
      final g = gameWithNavalResources();
      await tester.pumpWidget(
        buildDialog(
          game: g,
          humanPlayerId: humanPlayerId,
          currentOrders: carrackOrders(g, 1),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('£42,000 / £50,000'), findsOneWidget);
      expect(find.textContaining('19 / 20'), findsOneWidget);
    });

    testWidgets(
      'AC (positive): only the deficient commodity cost renders in danger',
      (WidgetTester tester) async {
        // Plenty of treasury/peasants/lumber/fabric/coal, but zero cast iron →
        // only ships consuming cast iron flag a red cost label.
        final base = gameWithNavalResources();
        final player = base.players.firstWhere((p) => p.id == humanPlayerId);
        final game = base.copyWith(
          players: [
            player.copyWith(
              treasury: 1000000,
              stockpile: const Stockpile(
                quantities: {
                  'lumber': 100,
                  'fabric': 100,
                  'castIron': 0,
                  'coal': 100,
                },
              ),
            ),
            ...base.players.where((p) => p.id != humanPlayerId),
          ],
        );
        await tester.pumpWidget(
          buildDialog(game: game, humanPlayerId: humanPlayerId),
        );
        await tester.pumpAndSettle();

        expect(redCostLabels(tester), greaterThan(0));
      },
    );

    testWidgets('AC (negative): fully affordable rows colour no cost labels red', (
      WidgetTester tester,
    ) async {
      final base = gameWithNavalResources();
      final player = base.players.firstWhere((p) => p.id == humanPlayerId);
      final game = base.copyWith(
        players: [
          player.copyWith(treasury: 1000000),
          ...base.players.where((p) => p.id != humanPlayerId),
        ],
      );
      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(redCostLabels(tester), 0);
    });

    testWidgets('AC (positive): disabled [+] uses danger variant when unaffordable', (
      WidgetTester tester,
    ) async {
      final base = gameWithNavalResources();
      final player = base.players.firstWhere((p) => p.id == humanPlayerId);
      final game = base.copyWith(
        players: [
          player.copyWith(treasury: 0),
          ...base.players.where((p) => p.id != humanPlayerId),
        ],
      );
      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(plusButtons(tester).any((b) => b.dangerVariant), isTrue);
    });

    testWidgets('AC (negative): tech-locked rows never use the danger [+] variant', (
      WidgetTester tester,
    ) async {
      // Abundant resources but no tech unlocked: every disabled `[+]` is
      // disabled by the lock, not by insufficiency, so none may be danger.
      // (Carrack has no unlocking tech, so it stays unlocked + affordable.)
      final base = gameWithNavalResources();
      final player = base.players.firstWhere((p) => p.id == humanPlayerId);
      final game = base.copyWith(
        players: [
          player.copyWith(
            treasury: 1000000,
            techUnlocked: const <String, bool>{},
          ),
          ...base.players.where((p) => p.id != humanPlayerId),
        ],
      );
      // At least one ship type is tech-locked in the roster.
      expect(
        ShipEconomyCatalog.all
            .where((e) => unlockingTechByShipId[e.shipTypeId] != null),
        isNotEmpty,
      );

      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(plusButtons(tester).every((b) => !b.dangerVariant), isTrue);
    });
  });
}
