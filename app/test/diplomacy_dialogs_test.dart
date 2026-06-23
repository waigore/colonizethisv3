import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy_dialogs.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  testWidgets('GrantOrSubsidyDialog submits default valid grant amount',
      (WidgetTester tester) async {
    // Refs #3656: lightweight fixture (gp1 human treasury 5000 + gp2) replaces
    // the ~7-11s getDebugInitGameResult(); the grant dialog only reads players.
    final game = buildDiplomacyScreenTestGame();
    final humanPlayerId = game.players.first.id;
    final treasury = game.players.first.treasury;
    if (treasury < 1000) {
      return;
    }
    final targetFactionId = game.players.length >= 2
        ? game.players[1].id
        : (game.minorNations.isNotEmpty ? game.minorNations.first.id : 'm1');

    final bus = AppEventBus.create();
    GrantOrSubsidySubmittedEvent? submitted;
    final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((e) {
      submitted = e;
    });
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => GrantOrSubsidyDialog(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    targetFactionId: targetFactionId,
                    isSubsidy: false,
                    bus: bus,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Grant aid'), findsOneWidget);
    expect(find.textContaining('£'), findsWidgets);

    await tester.tap(find.widgetWithText(CtNinePatchButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!.amount, 1000);
    expect(submitted!.isSubsidy, isFalse);
    expect(find.text('Grant aid'), findsNothing);
  });

  testWidgets(
      'GrantOrSubsidyDialog submit disabled when treasury below minimum',
      (WidgetTester tester) async {
    final base = buildDiplomacyScreenTestGame();
    final humanPlayerId = base.players.first.id;
    final targetFactionId = base.players.length >= 2
        ? base.players[1].id
        : (base.minorNations.isNotEmpty ? base.minorNations.first.id : 'm1');

    final game = base.copyWith(
      players: [
        base.players.first.copyWith(treasury: 500),
        ...base.players.skip(1),
      ],
    );

    final bus = AppEventBus.create();
    var submittedCalled = false;
    final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((_) {
      submittedCalled = true;
    });
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => GrantOrSubsidyDialog(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    targetFactionId: targetFactionId,
                    isSubsidy: false,
                    bus: bus,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Grant aid'), findsOneWidget);
    final submit = find.widgetWithText(CtNinePatchButton, 'Submit');
    final button = tester.widget<CtNinePatchButton>(submit);
    expect(button.enabled, isFalse);

    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(submittedCalled, isFalse);
    expect(find.text('Grant aid'), findsOneWidget);
  });

  testWidgets('GrantOrSubsidyDialog Cancel closes dialog',
      (WidgetTester tester) async {
    final game = buildDiplomacyScreenTestGame();
    final humanPlayerId = game.players.first.id;
    final targetFactionId = game.players.length >= 2
        ? game.players[1].id
        : (game.minorNations.isNotEmpty ? game.minorNations.first.id : 'm1');

    final bus = AppEventBus.create();
    var submittedCalled = false;
    final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((_) {
      submittedCalled = true;
    });
    addTearDown(sub.cancel);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => GrantOrSubsidyDialog(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    targetFactionId: targetFactionId,
                    isSubsidy: false,
                    bus: bus,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(CtNinePatchButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(submittedCalled, isFalse);
    expect(find.text('Grant aid'), findsNothing);
  });

  // ---------------------------------------------------------------------------
  // Dark editorial-monocle chrome (#2863 S6)
  // SPEC: SPEC/ui/grant-or-subsidy-dialog.md § "Dark editorial-monocle chrome".
  // Pin the palette tokens (title --accent + 0.05em, treasury --muted, thin
  // 1 dp --border divider, amount --fg + 0.04em, warning --danger italic) and
  // the Material-chrome regression guard (no AlertDialog/ListTile/Card leak).
  // ---------------------------------------------------------------------------

  Future<Game> pumpGrantDialog(
    WidgetTester tester, {
    required int humanTreasury,
    bool isSubsidy = false,
  }) async {
    final base = buildDiplomacyScreenTestGame();
    final humanPlayerId = base.players.first.id;
    final targetFactionId = base.players.length >= 2
        ? base.players[1].id
        : (base.minorNations.isNotEmpty ? base.minorNations.first.id : 'm1');

    final game = base.copyWith(
      players: [
        base.players.first.copyWith(treasury: humanTreasury),
        ...base.players.skip(1),
      ],
    );

    final bus = AppEventBus.create();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              child: const Text('Open'),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => GrantOrSubsidyDialog(
                    game: game,
                    humanPlayerId: humanPlayerId,
                    targetFactionId: targetFactionId,
                    isSubsidy: isSubsidy,
                    bus: bus,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return game;
  }

  group('Dark editorial-monocle chrome (#2863 S6)', () {
    testWidgets(
        'title resolves to EditorialMonoclePalette.accent with letterSpacing == fontSize * 0.05',
        (tester) async {
      await pumpGrantDialog(tester, humanTreasury: 5000);

      final titleFinder = find.byKey(const Key('grantOrSubsidyDialogTitle'));
      expect(titleFinder, findsOneWidget);

      final Text title = tester.widget<Text>(titleFinder);
      expect(title.style?.color, EditorialMonoclePalette.accent);
      expect(title.style?.fontSize, isNotNull);
      final double size = title.style!.fontSize!;
      expect(title.style?.letterSpacing, closeTo(size * 0.05, 1e-6));
    });

    testWidgets(
        'title color does NOT fall back to ambient textTheme.titleMedium.color (regression guard)',
        (tester) async {
      await pumpGrantDialog(tester, humanTreasury: 5000);

      final titleFinder = find.byKey(const Key('grantOrSubsidyDialogTitle'));
      final BuildContext context = tester.element(titleFinder);
      final Color? defaultColor = Theme.of(context).textTheme.titleMedium?.color;
      final Text title = tester.widget<Text>(titleFinder);
      expect(title.style?.color, isNot(equals(defaultColor)));
      expect(title.style?.color, EditorialMonoclePalette.accent);
    });

    testWidgets('treasury row resolves to EditorialMonoclePalette.muted',
        (tester) async {
      await pumpGrantDialog(tester, humanTreasury: 5000);

      final treasury = tester.widget<Text>(
        find.byKey(const Key('grantOrSubsidyDialogTreasury')),
      );
      expect(treasury.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets(
        'thin divider is a 1 dp Container painted in EditorialMonoclePalette.border',
        (tester) async {
      await pumpGrantDialog(tester, humanTreasury: 5000);

      final dividerFinder = find.byKey(
        const Key('grantOrSubsidyDialogThinDivider'),
      );
      expect(dividerFinder, findsOneWidget);

      final Container container = tester.widget<Container>(dividerFinder);
      expect(container.constraints?.maxHeight, 1);
      expect(container.constraints?.minHeight, 1);

      final BoxDecoration decoration =
          container.decoration as BoxDecoration;
      expect(decoration.color, EditorialMonoclePalette.border);
    });

    testWidgets(
        'amount resolves to EditorialMonoclePalette.fg with letterSpacing == fontSize * 0.04',
        (tester) async {
      await pumpGrantDialog(tester, humanTreasury: 5000);

      final amount = tester.widget<Text>(
        find.byKey(const Key('grantOrSubsidyDialogAmount')),
      );
      expect(amount.style?.color, EditorialMonoclePalette.fg);
      expect(amount.style?.fontSize, isNotNull);
      final double size = amount.style!.fontSize!;
      expect(amount.style?.letterSpacing, closeTo(size * 0.04, 1e-6));
    });

    testWidgets(
        'warning text resolves to EditorialMonoclePalette.danger and italic when below minimum',
        (tester) async {
      await pumpGrantDialog(tester, humanTreasury: 500);

      final warningFinder = find.byKey(
        const Key('grantOrSubsidyDialogWarning'),
      );
      expect(warningFinder, findsOneWidget);

      final Text warning = tester.widget<Text>(warningFinder);
      expect(warning.style?.color, EditorialMonoclePalette.danger);
      expect(warning.style?.fontStyle, FontStyle.italic);
    });

    testWidgets(
        'warning is absent when treasury is above the minimum step (positive negation)',
        (tester) async {
      await pumpGrantDialog(tester, humanTreasury: 5000);
      expect(
        find.byKey(const Key('grantOrSubsidyDialogWarning')),
        findsNothing,
      );
    });

    testWidgets(
        'no Material AlertDialog / ListTile / Card descendant leaks into the chrome',
        (tester) async {
      await pumpGrantDialog(tester, humanTreasury: 5000);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(ListTile), findsNothing);
      expect(find.byType(Card), findsNothing);
    });
  });
}
