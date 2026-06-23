import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train_military_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    game = buildTrainPanelTestGame();
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

  testWidgets('AC: treasury renders with £ + comma grouping (£10,000)', (
    WidgetTester tester,
  ) async {
    final richGame = gameWithMilitaryResources();
    await tester.pumpWidget(
      buildDialog(game: richGame, humanPlayerId: humanPlayerId),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('£10,000'), findsOneWidget);
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

    // The train dialogs have no × button per #3568 chrome parity; dismiss via
    // route pop (scrim tap / system back). Orders are still applied on close by
    // the host PopScope.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
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

  // Issue #3601 R1–R3: dynamic remaining/total resource display, red
  // insufficient-cost item styling, and red disabled `[+]` button styling.
  group('TrainMilitaryDialog affordance feedback (#3601)', () {
    /// Counts inline-cost labels (digit-only Text) that render in the danger
    /// colour. Resource-bar chips ("19 / 20") and deficit hints ("Cast Iron
    /// low") are word/slash strings and never match this digit-only filter.
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

    Orders peasantLevyOrders(int count) {
      final player = getPlayer(humanPlayerId);
      final capital =
          (player.capitalProvinceId ?? player.capitalTile?.provinceId)!;
      return Orders(
        buildUnitOrdersByPlayerId: {
          humanPlayerId: [
            for (var i = 0; i < count; i++)
              BuildUnitOrder(
                unitType: RegimentEconomyCatalog.peasantLevies.id,
                isMilitary: true,
                spawnProvinceId: capital,
              ),
          ],
        },
      );
    }

    testWidgets(
      'AC (positive): resource bar chips show remaining / total',
      (WidgetTester tester) async {
        // Treasury 10000, peasants 20; queue 1 Peasant Levies (£2,000 + 1
        // peasant) → treasury 8,000 / 10,000 and peasants 19 / 20.
        await tester.pumpWidget(
          buildDialog(
            game: gameWithMilitaryResources(),
            humanPlayerId: humanPlayerId,
            currentOrders: peasantLevyOrders(1),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('£8,000 / £10,000'), findsOneWidget);
        expect(find.textContaining('19 / 20'), findsOneWidget);
      },
    );

    testWidgets(
      'AC (positive): only the deficient commodity cost renders in danger',
      (WidgetTester tester) async {
        // Plenty of treasury/peasants/fabric, but zero cast iron → only
        // regiments consuming cast iron flag a red cost label.
        final base = gameWithMilitaryResources();
        final player = base.players.firstWhere((p) => p.id == humanPlayerId);
        // Replace (not merge) the stockpile so cast iron is genuinely 0 while
        // every other commodity stays plentiful.
        final game = base.copyWith(
          players: [
            player.copyWith(
              treasury: 1000000,
              stockpile: const Stockpile(
                quantities: {
                  'fabric': 100,
                  'castIron': 0,
                  'lumber': 100,
                  'horses': 100,
                  'steel': 100,
                  'bronze': 100,
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

    testWidgets(
      'AC (negative): fully affordable rows colour no cost labels red',
      (WidgetTester tester) async {
        final base = gameWithMilitaryResources();
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
      },
    );

    testWidgets(
      'AC (positive): disabled [+] uses danger variant when unaffordable',
      (WidgetTester tester) async {
        final base = gameWithMilitaryResources();
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
      },
    );

    testWidgets(
      'AC (negative): affordable rows never use the danger [+] variant',
      (WidgetTester tester) async {
        final base = gameWithMilitaryResources();
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

        expect(plusButtons(tester).every((b) => !b.dangerVariant), isTrue);
      },
    );

    testWidgets(
      'AC (positive): multi-resource deficit hint joins clauses with ", "',
      (WidgetTester tester) async {
        // Tech unlocked + abundant fabric, but zero treasury and zero peasants.
        // One queued Peasant Levies (£2,000 + 1 fabric + 1 peasant) makes both
        // treasury and peasants insufficient, so the hint joins two
        // `{Name} low` clauses with a comma (Refs #3568 comma-join).
        final base = gameWithMilitaryResources();
        final player = base.players.firstWhere((p) => p.id == humanPlayerId);
        final game = base.copyWith(
          players: [
            player.copyWith(
              treasury: 0,
              workerPool: player.workerPool.copyWith(peasants: 0),
            ),
            ...base.players.where((p) => p.id != humanPlayerId),
          ],
        );

        await tester.pumpWidget(
          buildDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: peasantLevyOrders(1),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Treasury low, Peasants low'), findsOneWidget);
        expect(find.textContaining(' and '), findsNothing);
      },
    );

    testWidgets(
      'AC (negative): single-resource deficit shows one "{Name} low" clause',
      (WidgetTester tester) async {
        // Zero treasury but abundant peasants/commodities → only the treasury
        // clause renders, with no comma separator.
        final base = gameWithMilitaryResources();
        final player = base.players.firstWhere((p) => p.id == humanPlayerId);
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 0),
            ...base.players.where((p) => p.id != humanPlayerId),
          ],
        );

        await tester.pumpWidget(
          buildDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: peasantLevyOrders(1),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Treasury low'), findsOneWidget);
        // No multi-clause join (no `… low, …`) and no peasants clause.
        expect(find.textContaining('low,'), findsNothing);
        expect(find.textContaining('Peasants low'), findsNothing);
      },
    );
  });
}
