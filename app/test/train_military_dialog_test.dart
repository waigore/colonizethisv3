import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/features/game/widgets/units/military/military_units_panel.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/train/train_military_regiment_role_display.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
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
      buildAppShell(
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
        navigatorKey: appNavigatorKey,
        shellWrapper: (app) => AppEventHandlerScope(child: app),
        child: Scaffold(
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
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Train'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainMilitaryDialog), findsOneWidget);
    expect(find.text('Train Military'), findsOneWidget);
  });

  group('TrainMilitaryDialog affordance feedback (#3601)', () {
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
      final player = harness.player(harness.humanPlayerId);
      final capital =
          (player.capitalProvinceId ?? player.capitalTile?.provinceId)!;
      return Orders(
        buildUnitOrdersByPlayerId: {
          harness.humanPlayerId: [
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
        await tester.pumpWidget(
          harness.buildDialog(
            panelGame: harness.gameWithMilitaryResources(),
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
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
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
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );
        await tester.pumpWidget(harness.buildDialog(panelGame: game));
        await tester.pumpAndSettle();

        expect(redCostLabels(tester), greaterThan(0));
      },
    );

    testWidgets(
      'AC (negative): fully affordable rows colour no cost labels red',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 1000000),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );
        await tester.pumpWidget(harness.buildDialog(panelGame: game));
        await tester.pumpAndSettle();

        expect(redCostLabels(tester), 0);
      },
    );

    testWidgets(
      'AC (positive): disabled [+] uses danger variant when unaffordable',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 0),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );
        await tester.pumpWidget(harness.buildDialog(panelGame: game));
        await tester.pumpAndSettle();

        expect(plusButtons(tester).any((b) => b.dangerVariant), isTrue);
      },
    );

    testWidgets(
      'AC (negative): affordable rows never use the danger [+] variant',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 1000000),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );
        await tester.pumpWidget(harness.buildDialog(panelGame: game));
        await tester.pumpAndSettle();

        expect(plusButtons(tester).every((b) => !b.dangerVariant), isTrue);
      },
    );

    testWidgets(
      'AC (positive): multi-resource deficit hint joins clauses with ", "',
      (WidgetTester tester) async {
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(
              treasury: 0,
              workerPool: player.workerPool.copyWith(peasants: 0),
            ),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );

        await tester.pumpWidget(
          harness.buildDialog(
            panelGame: game,
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
        final base = harness.gameWithMilitaryResources();
        final player = base.players.firstWhere(
          (p) => p.id == harness.humanPlayerId,
        );
        final game = base.copyWith(
          players: [
            player.copyWith(treasury: 0),
            ...base.players.where((p) => p.id != harness.humanPlayerId),
          ],
        );

        await tester.pumpWidget(
          harness.buildDialog(
            panelGame: game,
            currentOrders: peasantLevyOrders(1),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Treasury low'), findsOneWidget);
        expect(find.textContaining('low,'), findsNothing);
        expect(find.textContaining('Peasants low'), findsNothing);
      },
    );
  });

  group('benefit vs cost row copy (#4324)', () {
    testWidgets('culverin row shows category gist and food upkeep', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(
          game: gameWithMilitaryResources(),
          humanPlayerId: humanPlayerId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Heavy artillery · Siege guns'), findsWidgets);
      expect(
        find.text(
          '${RegimentEconomyCatalog.culverin.foodUpkeep} food / turn',
        ),
        findsWidgets,
      );
    });

    testWidgets('pikemen and arquebusiers show distinct benefit lines', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(
          game: gameWithMilitaryResources(),
          humanPlayerId: humanPlayerId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Regular infantry · Melee line'), findsWidgets);
      expect(find.text('Heavy infantry · Ranged firepower'), findsWidgets);
    });

    testWidgets('locked row still shows benefit and food upkeep', (
      WidgetTester tester,
    ) async {
      final base = gameWithMilitaryResources();
      final player = base.players.firstWhere((p) => p.id == humanPlayerId);
      final lockedRegimentId = RegimentEconomyCatalog.musketeers.id;
      final lockedStats = regimentStatsById(lockedRegimentId)!;
      final lockedEconomy = RegimentEconomyCatalog.musketeers;
      final game = base.copyWith(
        players: [
          player.copyWith(techUnlocked: {}),
          ...base.players.where((p) => p.id != humanPlayerId),
        ],
      );

      await tester.pumpWidget(
        buildDialog(game: game, humanPlayerId: humanPlayerId),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          TrainMilitaryRegimentRoleDisplay.categoryRoleLine(
            lookupAppLocalizations(const Locale('en')),
            lockedStats.category,
          ),
        ),
        findsWidgets,
      );
      expect(
        find.text('${lockedEconomy.foodUpkeep} food / turn'),
        findsWidgets,
      );
      expect(find.textContaining('Requires:'), findsWidgets);
    });

    testWidgets('default rows do not dump tactical stat labels', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildDialog(
          game: gameWithMilitaryResources(),
          humanPlayerId: humanPlayerId,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('FPN'), findsNothing);
      expect(find.textContaining('FPM'), findsNothing);
      expect(find.textContaining('RNG'), findsNothing);
      expect(find.textContaining('DEF'), findsNothing);
      expect(find.textContaining('MVR'), findsNothing);
    });
  });
}
