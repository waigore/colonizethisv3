// Tests for TrainCiviliansDialog. SPEC/ui/train-civilians-dialog.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/units/civilian/civilian_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_civilians_dialog.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late String humanPlayerId;

  setUpAll(() {
    game = buildTrainPanelTestGame();
    humanPlayerId = game.players.firstWhere((p) => p.isHuman).id;
  });

  Player getPlayer(String pid) => game.players.firstWhere((p) => p.id == pid);

  String humanCapitalId() {
    final player = getPlayer(humanPlayerId);
    return (player.capitalProvinceId ?? player.capitalTile?.provinceId)!;
  }

  Game gameWithPlayer(Player Function(Player base) update) {
    final player = getPlayer(humanPlayerId);
    return game.copyWith(
      players: [
        update(player),
        ...game.players.where((p) => p.id != humanPlayerId),
      ],
    );
  }

  Game gameWithResources({
    required int treasury,
    required int paper,
    String? techUnlocked,
    Map<String, bool>? techUnlockedMap,
    bool replaceStockpile = false,
  }) {
    return gameWithPlayer((player) {
      final capital =
          player.capitalProvinceId ?? player.capitalTile?.provinceId;
      final paperStock = Stockpile(quantities: {'paper': paper});
      return player.copyWith(
        treasury: treasury,
        stockpile: replaceStockpile
            ? const Stockpile().merge(paperStock)
            : player.stockpile.merge(paperStock),
        techUnlocked:
            techUnlockedMap ??
            (techUnlocked != null ? {techUnlocked: true} : null),
        capitalProvinceId: capital,
      );
    });
  }

  Orders builderOrders(int count) {
    final capital = humanCapitalId();
    return Orders(
      buildUnitOrdersByPlayerId: {
        humanPlayerId: [
          for (var i = 0; i < count; i++)
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary: false,
              spawnProvinceId: capital,
            ),
        ],
      },
    );
  }

  /// Affordance-feedback fixtures replace stockpile (paper-only), matching #3601.
  Game gameWithCapital({required int treasury, required int paper}) =>
      gameWithResources(
        treasury: treasury,
        paper: paper,
        replaceStockpile: true,
      );

  Game gameWithNoTech({int? treasury}) => gameWithPlayer(
    (player) => player.copyWith(
      treasury: treasury ?? player.treasury,
      techUnlocked: <String, bool>{},
      capitalProvinceId:
          player.capitalProvinceId ?? player.capitalTile?.provinceId,
    ),
  );

  Future<void> pumpDialog(
    WidgetTester tester, {
    required Game game,
    Orders currentOrders = const Orders(),
    AppEventBus? bus,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: TrainCiviliansDialog(
            game: game,
            humanPlayerId: humanPlayerId,
            currentOrders: currentOrders,
            bus: bus ?? AppEventBus.create(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapStepper(
    WidgetTester tester,
    String glyph, {
    int index = 0,
  }) async {
    final finder = find.text(glyph).at(index);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// AppEventHandlerScope host so Train opens [TrainCiviliansDialog] via bus.
  Widget civilianPanelWithAppHandler(Game panelGame) {
    return buildAppShell(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(panelGame)),
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
      navigatorKey: appNavigatorKey,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: Scaffold(
        body: Consumer(
          builder: (context, ref, _) {
            return CivilianUnitsPanel(
              game: panelGame,
              humanPlayerId: humanPlayerId,
              bus: ref.watch(appEventBusProvider),
            );
          },
        ),
      ),
    );
  }

  Future<void> pumpCivilianPanel(WidgetTester tester, [Game? panelGame]) async {
    await tester.pumpWidget(civilianPanelWithAppHandler(panelGame ?? game));
    await tester.pumpAndSettle();
  }

  group('TrainCiviliansDialog', () {
    // Table-registered chrome pins (isolated testWidgets per case — Refs #4021).
    for (final case_
        in <
          ({
            String name,
            Game Function() game,
            Orders Function() orders,
            void Function(WidgetTester tester) expectUi,
          })
        >[
          (
            name: 'Dialog shows title Train Civilians',
            game: () => game,
            orders: () => const Orders(),
            expectUi: (tester) =>
                expect(find.text('Train Civilians'), findsOneWidget),
          ),
          (
            name: 'Resource bar shows Treasury and Paper',
            game: () => game,
            orders: () => const Orders(),
            expectUi: (tester) {
              expect(find.textContaining('Treasury:'), findsOneWidget);
              expect(find.textContaining('Paper:'), findsOneWidget);
            },
          ),
          (
            name: 'Treasury renders with £ + comma grouping (£5,000), not 5k',
            game: () => gameWithResources(treasury: 5000, paper: 12),
            orders: () => const Orders(),
            expectUi: (tester) {
              expect(find.textContaining('£5,000'), findsOneWidget);
              expect(find.textContaining('5k'), findsNothing);
            },
          ),
          (
            name:
                'Unlocked cost line reads "£1,000 + 2 paper" (lowercase paper)',
            game: () => gameWithResources(treasury: 10000, paper: 100),
            orders: () => const Orders(),
            expectUi: (tester) =>
                expect(find.textContaining('£1,000 + 2 paper'), findsWidgets),
          ),
          (
            name:
                'Both-resource deficit reads "Treasury low, Paper low" (comma-join)',
            game: () => gameWithCapital(treasury: 1500, paper: 3),
            orders: () => builderOrders(2),
            expectUi: (tester) {
              expect(find.text('Treasury low, Paper low'), findsOneWidget);
              expect(find.textContaining(' and '), findsNothing);
            },
          ),
          (
            name: 'All 6 civilian unit types are listed',
            game: () => game,
            orders: () => const Orders(),
            expectUi: (tester) {
              for (final econ in CivilianEconomyCatalog.all) {
                final bare = find.text(econ.id);
                final locked = find.text('\u{1F512} ${econ.id}');
                expect(
                  bare.evaluate().isNotEmpty || locked.evaluate().isNotEmpty,
                  isTrue,
                  reason:
                      '${econ.id} row should render (bare or 🔒-prefixed if locked)',
                );
              }
            },
          ),
          (
            name: 'Stepper starts at 0 for each unit type',
            game: () => game,
            orders: () => const Orders(),
            expectUi: (tester) {
              expect(find.text('0'), findsWidgets);
              expect(
                find.text('+'),
                findsNWidgets(CivilianEconomyCatalog.all.length),
              );
              expect(
                find.text('−'),
                findsNWidgets(CivilianEconomyCatalog.all.length),
              );
            },
          ),
          (
            name:
                'Steppers reflect existing train-at-capital civilian build orders',
            game: () => gameWithResources(treasury: 10000, paper: 100),
            orders: () => builderOrders(2),
            expectUi: (tester) => expect(find.text('2'), findsWidgets),
          ),
          (
            name: 'Locked units show 🔒 name prefix and tech requirement',
            game: () => gameWithNoTech(),
            orders: () => const Orders(),
            expectUi: (tester) {
              expect(find.textContaining('\u{1F512}'), findsWidgets);
              expect(find.textContaining('Requires:'), findsNWidgets(2));
            },
          ),
        ]) {
      testWidgets('AC: ${case_.name}', (WidgetTester tester) async {
        await pumpDialog(
          tester,
          game: case_.game(),
          currentOrders: case_.orders(),
        );
        case_.expectUi(tester);
      });
    }

    testWidgets('AC: stepper interactions', (WidgetTester tester) async {
      final rich = gameWithResources(treasury: 10000, paper: 100);
      await pumpDialog(tester, game: rich);
      await tapStepper(tester, '+');
      expect(find.text('1'), findsWidgets);
      await tapStepper(tester, '−');
      expect(find.text('1'), findsNothing);

      await pumpDialog(tester, game: game);
      await tapStepper(tester, '−');
      expect(find.text('0'), findsWidgets);

      // Builder costs 1000 treasury + 2 paper; 1500 treasury allows 1 not 2.
      await pumpDialog(
        tester,
        game: gameWithResources(treasury: 1500, paper: 10),
      );
      final builderIndex = CivilianEconomyCatalog.all.indexWhere(
        (e) => e.id == kUnitTypeBuilder,
      );
      await tapStepper(tester, '+', index: builderIndex);
      expect(find.text('1'), findsWidgets);
      await tapStepper(tester, '+', index: builderIndex);
      expect(find.text('1'), findsWidgets);

      await pumpDialog(tester, game: gameWithNoTech());
      final merchantIndex = CivilianEconomyCatalog.all.indexWhere(
        (e) => e.id == kUnitTypeMerchant,
      );
      await tapStepper(tester, '+', index: merchantIndex);
      expect(find.text('0'), findsWidgets);

      await pumpDialog(tester, game: rich);
      await tapStepper(tester, '+');
      await tapStepper(tester, '+', index: 1);
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
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
          buildAppShell(
            child: Scaffold(
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

        await tapStepper(tester, '+');
        await tapStepper(tester, '+');
        expect(find.text('2'), findsWidgets);

        // The train dialogs have no × button per #3568 chrome parity; dismiss
        // via route pop (scrim tap / system back). Orders are still applied on
        // close by the host PopScope.
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
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
      await pumpCivilianPanel(tester);
      expect(find.text('Train'), findsOneWidget);
    });

    testWidgets(
      'AC: Train button opens TrainCiviliansDialog via app event bus',
      (WidgetTester tester) async {
        await pumpCivilianPanel(tester);
        await tester.tap(find.text('Train'));
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(TrainCiviliansDialog), findsOneWidget);
        expect(find.text('Train Civilians'), findsOneWidget);
      },
    );
  });

  // Issue #3601 R1–R3: dynamic remaining/total resource display, red
  // insufficient-cost item styling, and red disabled `[+]` button styling.
  group('TrainCiviliansDialog affordance feedback (#3601)', () {
    List<InlineSpan> costLineSpans(WidgetTester tester, String plainText) {
      final text = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (t) => t.textSpan?.toPlainText() == plainText,
            orElse: () => throw StateError('cost line "$plainText" not found'),
          );
      return (text.textSpan! as TextSpan).children!;
    }

    Iterable<CtNinePatchButton> plusButtons(WidgetTester tester) {
      return tester.widgetList<CtNinePatchButton>(
        find.byWidgetPredicate(
          (w) =>
              w is CtNinePatchButton &&
              w.child is Text &&
              (w.child as Text).data == '+',
        ),
      );
    }

    testWidgets('AC: resource bar remaining/total and Reset restore', (
      WidgetTester tester,
    ) async {
      await pumpDialog(
        tester,
        game: gameWithCapital(treasury: 5000, paper: 12),
        currentOrders: builderOrders(2),
      );
      expect(find.textContaining('£3,000 / £5,000'), findsOneWidget);
      expect(find.textContaining('8 / 12'), findsOneWidget);

      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.textContaining('£5,000 / £5,000'), findsOneWidget);
      expect(find.textContaining('12 / 12'), findsOneWidget);
    });

    testWidgets('AC: cost-line danger segments follow affordability', (
      WidgetTester tester,
    ) async {
      await pumpDialog(
        tester,
        game: gameWithCapital(treasury: 1500, paper: 5),
        currentOrders: builderOrders(1),
      );
      final deficient = costLineSpans(tester, '£1,000 + 2 paper');
      expect(
        (deficient.first as TextSpan).style?.color,
        EditorialMonoclePalette.danger,
      );
      expect(
        (deficient.last as TextSpan).style?.color,
        isNot(EditorialMonoclePalette.danger),
      );

      await pumpDialog(
        tester,
        game: gameWithCapital(treasury: 10000, paper: 100),
      );
      for (final span in costLineSpans(tester, '£1,000 + 2 paper')) {
        expect(
          (span as TextSpan).style?.color,
          isNot(EditorialMonoclePalette.danger),
        );
      }
    });

    testWidgets('AC: [+] danger variant tracks unaffordable vs locked rows', (
      WidgetTester tester,
    ) async {
      await pumpDialog(
        tester,
        game: gameWithCapital(treasury: 1500, paper: 5),
        currentOrders: builderOrders(1),
      );
      expect(plusButtons(tester).any((b) => b.dangerVariant), isTrue);

      await pumpDialog(
        tester,
        game: gameWithCapital(treasury: 100000, paper: 1000),
      );
      expect(plusButtons(tester).every((b) => !b.dangerVariant), isTrue);

      await pumpDialog(tester, game: gameWithNoTech(treasury: 0));
      final lockedCount = CivilianEconomyCatalog.all
          .where((e) => unlockingTechByCivilianId[e.id] != null)
          .length;
      expect(lockedCount, greaterThan(0));
      expect(
        plusButtons(tester).where((b) => b.dangerVariant).length,
        CivilianEconomyCatalog.all.length - lockedCount,
      );
    });
  });
}
