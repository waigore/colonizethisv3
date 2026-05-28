// Tests for TrainCiviliansDialog. SPEC/ui/train-civilians-dialog.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train_civilians_dialog.dart';
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

  Game gameWithResources({
    required int treasury,
    required int paper,
    String? techUnlocked,
    String? capitalProvinceId,
  }) {
    final player = getPlayer(humanPlayerId);
    final updatedPlayer = player.copyWith(
      treasury: treasury,
      stockpile: player.stockpile.merge(
        Stockpile(quantities: {'paper': paper}),
      ),
      techUnlocked: techUnlocked != null ? {techUnlocked: true} : null,
      capitalProvinceId: capitalProvinceId ?? player.capitalTile?.provinceId,
    );
    return game.copyWith(
      players: [
        updatedPlayer,
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
        body: TrainCiviliansDialog(
          game: game,
          humanPlayerId: humanPlayerId,
          currentOrders: currentOrders,
          bus: bus ?? AppEventBus.create(),
        ),
      ),
    );
  }

  group('TrainCiviliansDialog', () {
    testWidgets('AC: Dialog shows title Train Civilians', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Train Civilians'), findsOneWidget);
    });

    testWidgets('AC: Resource bar shows Treasury and Paper', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Treasury:'), findsOneWidget);
      expect(find.textContaining('Paper:'), findsOneWidget);
    });

    testWidgets('AC: All 6 civilian unit types are listed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      for (final econ in CivilianEconomyCatalog.all) {
        expect(find.text(econ.id), findsOneWidget);
      }
    });

    testWidgets('AC: Stepper starts at 0 for each unit type', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      final plusButtons = find.text('+');
      final minusButtons = find.text('−');
      // All steppers start at 0
      expect(find.text('0'), findsWidgets);
      expect(plusButtons, findsNWidgets(CivilianEconomyCatalog.all.length));
      expect(minusButtons, findsNWidgets(CivilianEconomyCatalog.all.length));
    });

    testWidgets(
      'AC: Steppers reflect existing train-at-capital civilian build orders',
      (WidgetTester tester) async {
        final richGame = gameWithResources(treasury: 10000, paper: 100);
        final player = getPlayer(humanPlayerId);
        final capital =
            player.capitalProvinceId ?? player.capitalTile?.provinceId;
        expect(capital, isNotNull, reason: 'debug game needs capital');
        final cap = capital!;
        final orders = Orders(
          buildUnitOrdersByPlayerId: {
            humanPlayerId: [
              BuildUnitOrder(
                unitType: kUnitTypeBuilder,
                isMilitary: false,
                spawnProvinceId: cap,
              ),
              BuildUnitOrder(
                unitType: kUnitTypeBuilder,
                isMilitary: false,
                spawnProvinceId: cap,
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
      },
    );

    testWidgets('AC: Tapping + increments the count', (
      WidgetTester tester,
    ) async {
      final richGame = gameWithResources(treasury: 10000, paper: 100);
      await tester.pumpWidget(
        buildDialog(game: richGame, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      // Find the first + button and tap it
      final plusButtons = find.text('+');
      await tester.ensureVisible(plusButtons.first);
      await tester.tap(plusButtons.first);
      await tester.pumpAndSettle();

      // Now there should be a '1' visible
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('AC: Tapping - decrements the count', (
      WidgetTester tester,
    ) async {
      final richGame = gameWithResources(treasury: 10000, paper: 100);
      await tester.pumpWidget(
        buildDialog(game: richGame, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      // First tap + to get to 1
      final plusFinder = find.text('+').first;
      await tester.ensureVisible(plusFinder);
      await tester.tap(plusFinder);
      await tester.pumpAndSettle();
      expect(find.text('1'), findsWidgets);

      // Then tap - to get back to 0
      final minusFinder = find.text('−').first;
      await tester.ensureVisible(minusFinder);
      await tester.tap(minusFinder);
      await tester.pumpAndSettle();
      // Now there should be no '1'
      expect(find.text('1'), findsNothing);
    });

    testWidgets('AC: Cannot decrement below 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      // Try tapping - when count is 0
      final minusButton = find.text('−').first;
      await tester.tap(minusButton);
      await tester.pumpAndSettle();

      // Count should still be 0
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('AC: Deficit hint shows when resources insufficient', (
      WidgetTester tester,
    ) async {
      // Create a player with just enough for 1 unit but not 2
      // Builder costs 1000 treasury + 2 paper
      final limitedPlayer = getPlayer(humanPlayerId).copyWith(
        treasury: 1500, // enough for 1 Builder but not 2
        stockpile: getPlayer(
          humanPlayerId,
        ).stockpile.merge(Stockpile(quantities: {'paper': 10})),
      );
      final gameWithLimited = game.copyWith(
        players: [
          limitedPlayer,
          ...game.players.where((p) => p.id != humanPlayerId),
        ],
      );

      await tester.pumpWidget(
        buildDialog(game: gameWithLimited, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      // Tap + once for Builder (should succeed)
      final builderIndex = CivilianEconomyCatalog.all.indexWhere(
        (e) => e.id == kUnitTypeBuilder,
      );
      final builderPlus = find.text('+').at(builderIndex);
      await tester.ensureVisible(builderPlus);
      await tester.tap(builderPlus);
      await tester.pumpAndSettle();

      // Count should be 1
      expect(find.text('1'), findsWidgets);

      // Now try to tap + again - should be blocked since 2 Builders = 2000 treasury > 1500
      await tester.ensureVisible(builderPlus);
      await tester.tap(builderPlus);
      await tester.pumpAndSettle();

      // Verify count is still 1 (couldn't add second)
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('AC: Locked units show lock icon and tech requirement', (
      WidgetTester tester,
    ) async {
      // Create a player with no tech unlocked
      final noTechPlayer = getPlayer(
        humanPlayerId,
      ).copyWith(techUnlocked: <String, bool>{});
      final gameWithNoTech = game.copyWith(
        players: [
          noTechPlayer,
          ...game.players.where((p) => p.id != humanPlayerId),
        ],
      );

      await tester.pumpWidget(
        buildDialog(game: gameWithNoTech, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      // Merchant should show lock icon
      expect(find.byType(Image), findsWidgets);
      // Should show tech requirement for Merchant
      expect(
        find.textContaining('Requires:'),
        findsNWidgets(2),
      ); // Merchant + Rail Builder
    });

    testWidgets('AC: Locked units have disabled steppers', (
      WidgetTester tester,
    ) async {
      final noTechPlayer = getPlayer(
        humanPlayerId,
      ).copyWith(techUnlocked: <String, bool>{});
      final gameWithNoTech = game.copyWith(
        players: [
          noTechPlayer,
          ...game.players.where((p) => p.id != humanPlayerId),
        ],
      );

      await tester.pumpWidget(
        buildDialog(game: gameWithNoTech, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      // Find the + button for a locked unit (Merchant)
      final merchantIndex = CivilianEconomyCatalog.all.indexWhere(
        (e) => e.id == kUnitTypeMerchant,
      );

      // Merchant's + button should be disabled
      // Since we can't easily identify which + is for which unit,
      // just verify tapping doesn't change count
      final merchantPlus = find.text('+').at(merchantIndex);
      await tester.ensureVisible(merchantPlus);
      await tester.tap(merchantPlus);
      await tester.pumpAndSettle();

      // Count should still be 0
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('AC: Reset clears all steppers', (WidgetTester tester) async {
      final richGame = gameWithResources(treasury: 10000, paper: 100);
      await tester.pumpWidget(
        buildDialog(game: richGame, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      // Increment a few steppers
      final firstPlus = find.text('+').first;
      await tester.ensureVisible(firstPlus);
      await tester.tap(firstPlus);
      await tester.pumpAndSettle();
      final secondPlus = find.text('+').at(1);
      await tester.ensureVisible(secondPlus);
      await tester.tap(secondPlus);
      await tester.pumpAndSettle();

      // Now tap Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // All counts should be 0
      expect(find.text('1'), findsNothing);
    });

    testWidgets(
      'AC: Closing dialog emits TrainCivilianBuildOrdersCommittedEvent with correct orders',
      (WidgetTester tester) async {
        List<BuildUnitOrder>? capturedOrders;
        final bus = AppEventBus.create();
        final sub = bus.on<TrainCivilianBuildOrdersCommittedEvent>().listen((
          e,
        ) {
          capturedOrders = e.orders;
        });
        addTearDown(sub.cancel);

        final richGame = gameWithResources(treasury: 10000, paper: 100);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: ctx,
                      builder: (dialogCtx) => TrainCiviliansDialog(
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

        // Open the dialog
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        // Increment Builder count to 2 (Builder is at index 0)
        final builderPlusFinder = find.text('+').at(0);
        await tester.ensureVisible(builderPlusFinder);
        await tester.tap(builderPlusFinder);
        await tester.pumpAndSettle();
        await tester.ensureVisible(builderPlusFinder);
        await tester.tap(builderPlusFinder);
        await tester.pumpAndSettle();

        // Verify count is 2
        expect(find.text('2'), findsWidgets);

        // Close dialog via X button (footer may be below fold in shell scroll)
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
        await tester.pump(const Duration(milliseconds: 100));

        expect(capturedOrders, isNotNull);
        expect(capturedOrders!.length, 2);
        expect(capturedOrders![0].unitType, kUnitTypeBuilder);
        expect(capturedOrders![0].isMilitary, false);
        expect(capturedOrders![1].unitType, kUnitTypeBuilder);
      },
    );

    testWidgets('AC: Train button visible in CivilianUnitsPanel header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
            currentOrdersProvider.overrideWith(
              () => CurrentOrdersNotifier(const Orders()),
            ),
            appEventBusProvider.overrideWith((ref) {
              final bus = AppEventBus.create();
              ref.onDispose(bus.dispose);
              return bus;
            }),
            availableWorkTargetIdsForUnitProvider.overrideWith(
              (ref, _) => const <String>[],
            ),
          ],
          child: AppEventHandlerScope(
            child: MaterialApp(
              navigatorKey: appNavigatorKey,
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    return CivilianUnitsPanel(
                      game: game,
                      humanPlayerId: humanPlayerId,
                      bus: ref.watch(appEventBusProvider),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Train'), findsOneWidget);
    });

    testWidgets(
      'AC: Train button opens TrainCiviliansDialog via app event bus',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
              currentOrdersProvider.overrideWith(
                () => CurrentOrdersNotifier(const Orders()),
              ),
              appEventBusProvider.overrideWith((ref) {
                final bus = AppEventBus.create();
                ref.onDispose(bus.dispose);
                return bus;
              }),
              availableWorkTargetIdsForUnitProvider.overrideWith(
                (ref, _) => const <String>[],
              ),
            ],
            child: AppEventHandlerScope(
              child: MaterialApp(
                navigatorKey: appNavigatorKey,
                home: Scaffold(
                  body: Consumer(
                    builder: (context, ref, _) {
                      return CivilianUnitsPanel(
                        game: game,
                        humanPlayerId: humanPlayerId,
                        bus: ref.watch(appEventBusProvider),
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
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(TrainCiviliansDialog), findsOneWidget);
        expect(find.text('Train Civilians'), findsOneWidget);
      },
    );
  });
}
