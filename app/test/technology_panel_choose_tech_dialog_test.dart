// Choose-tech dialog visual + behavior ACs for TechnologyPanel.
//
// Refs #2864 — S4 Choose-tech dialog migration to CtDialogShell.
// SPEC/ui/technology-panel.md § Choose-tech dialog.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_dialog_shell.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/features/game/widgets/technology_panel_orders.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player basePlayer;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    basePlayer = game.players.first;
  });

  Widget host(Game g, Player p, {Orders orders = const Orders()}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TechnologyPanel(
            game: g,
            player: p,
            currentOrders: orders,
            onOrdersChanged: (_) {},
          ),
        ),
      ),
    );
  }

  Future<void> openChooseTechDialog(WidgetTester tester) async {
    // SPEC/ui/technology-panel.md § Slots tab — section ordering
    // (Refs #2864 S0/S6) places the Researched Techs grid above the
    // Research Slots block. Variants with many researched techs push
    // the first "Choose tech" button off the default 800×600 test
    // viewport, so ensureVisible scrolls it back into the hit region
    // before tapping.
    final chooseTech = find.text('Choose tech').first;
    await tester.ensureVisible(chooseTech);
    await tester.pumpAndSettle();
    await tester.tap(chooseTech);
    await tester.pumpAndSettle();
  }

  group('Choose-tech dialog mounts CtDialogShell, not Material chrome', () {
    testWidgets(
      'positive: Choose-tech mounts ChooseTechDialog inside CtDialogShell',
      (WidgetTester tester) async {
        await tester.pumpWidget(host(game, basePlayer));
        await tester.pumpAndSettle();
        await openChooseTechDialog(tester);

        expect(find.byType(ChooseTechDialog), findsOneWidget);
        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Choose Tech \u2014 Slot 1'), findsOneWidget);
      },
    );

    testWidgets(
      'negative: Choose-tech route does not mount AlertDialog/ListTile/ListView/Material Divider',
      (WidgetTester tester) async {
        await tester.pumpWidget(host(game, basePlayer));
        await tester.pumpAndSettle();
        await openChooseTechDialog(tester);

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(ListTile), findsNothing);
        expect(find.byType(ListView), findsNothing);
        expect(find.byType(BottomSheet), findsNothing);
      },
    );
  });

  group('Choose-tech dialog scrim resolves to dialogScrim token', () {
    testWidgets(
      'positive: route barrierColor is exactly EditorialMonoclePalette.dialogScrim',
      (WidgetTester tester) async {
        await tester.pumpWidget(host(game, basePlayer));
        await tester.pumpAndSettle();
        await openChooseTechDialog(tester);

        // The active modal route exposes its barrierColor; the spec
        // pins it to the canonical scrim token.
        final BuildContext dialogContext = tester.element(
          find.byType(ChooseTechDialog),
        );
        final ModalRoute<dynamic>? route = ModalRoute.of(dialogContext);
        expect(route, isNotNull);
        expect(route!.barrierColor, EditorialMonoclePalette.dialogScrim);
      },
    );
  });

  group('Choose-tech dialog title row format', () {
    testWidgets(
      'positive: title shows slot index in 1-based form (Slot N for slotIndex N - 1)',
      (WidgetTester tester) async {
        await tester.pumpWidget(host(game, basePlayer));
        await tester.pumpAndSettle();
        // Tap second slot's Choose tech to test slot 2 title.
        final chooseButtons = find.text('Choose tech');
        expect(chooseButtons, findsAtLeastNWidgets(2));
        await tester.tap(chooseButtons.at(1));
        await tester.pumpAndSettle();

        expect(find.text('Choose Tech \u2014 Slot 2'), findsOneWidget);
      },
    );
  });

  group('Choose-tech dialog empty state', () {
    testWidgets(
      'positive: when no choosable techs, dialog shows empty-state line and Close button',
      (WidgetTester tester) async {
        // Player has every tech unlocked → researchableTechIds is empty
        // → the dialog renders the empty-state message.
        final fullyUnlocked = basePlayer.copyWith(
          techUnlocked: {for (final id in techCatalog.keys) id: true},
        );
        final localGame = game.copyWith(
          players: [fullyUnlocked, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, fullyUnlocked));
        await tester.pumpAndSettle();
        await openChooseTechDialog(tester);

        expect(find.byType(ChooseTechDialog), findsOneWidget);
        expect(find.text('No techs available to research'), findsOneWidget);
        // Footer Close button still rendered.
        expect(
          find.descendant(
            of: find.byType(ChooseTechDialog),
            matching: find.byType(CtNinePatchButton),
          ),
          findsOneWidget,
        );
        expect(find.text('Close'), findsOneWidget);
      },
    );
  });

  group('Choose-tech dialog Close button', () {
    testWidgets(
      'positive: tapping Close pops the dialog without mutating orders',
      (WidgetTester tester) async {
        Orders? captured;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TechnologyPanel(
                  game: game,
                  player: basePlayer,
                  currentOrders: const Orders(),
                  onOrdersChanged: (next) => captured = next,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openChooseTechDialog(tester);

        expect(find.byType(ChooseTechDialog), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(ChooseTechDialog), findsNothing);
        expect(
          captured,
          isNull,
          reason: 'Close must not call onOrdersChanged',
        );
      },
    );

    testWidgets(
      'negative: tapping Close on empty-state variant still pops without orders mutation',
      (WidgetTester tester) async {
        Orders? captured;
        final fullyUnlocked = basePlayer.copyWith(
          techUnlocked: {for (final id in techCatalog.keys) id: true},
        );
        final localGame = game.copyWith(
          players: [fullyUnlocked, ...game.players.skip(1)],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: TechnologyPanel(
                  game: localGame,
                  player: fullyUnlocked,
                  currentOrders: const Orders(),
                  onOrdersChanged: (next) => captured = next,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await openChooseTechDialog(tester);

        expect(find.text('No techs available to research'), findsOneWidget);
        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();

        expect(find.byType(ChooseTechDialog), findsNothing);
        expect(captured, isNull);
      },
    );
  });
}
