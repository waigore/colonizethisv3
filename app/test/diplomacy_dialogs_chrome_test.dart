import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/diplomacy/diplomacy_dialogs.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'diplomacy_dialogs_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  group('Dark editorial-monocle chrome (#2863 S6)', () {
    testWidgets(
      'title resolves to EditorialMonoclePalette.accent with letterSpacing == fontSize * 0.05',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        final titleFinder = find.byKey(const Key('grantOrSubsidyDialogTitle'));
        expect(titleFinder, findsOneWidget);

        final Text title = tester.widget<Text>(titleFinder);
        expect(title.style?.color, EditorialMonoclePalette.accent);
        expect(title.style?.fontSize, isNotNull);
        final double size = title.style!.fontSize!;
        expect(title.style?.letterSpacing, closeTo(size * 0.05, 1e-6));
      },
    );

    testWidgets(
      'title color does NOT fall back to ambient textTheme.titleMedium.color (regression guard)',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        final titleFinder = find.byKey(const Key('grantOrSubsidyDialogTitle'));
        final BuildContext context = tester.element(titleFinder);
        final Color? defaultColor = Theme.of(
          context,
        ).textTheme.titleMedium?.color;
        final Text title = tester.widget<Text>(titleFinder);
        expect(title.style?.color, isNot(equals(defaultColor)));
        expect(title.style?.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets('treasury row resolves to EditorialMonoclePalette.muted', (
      tester,
    ) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

      final treasury = tester.widget<Text>(
        find.byKey(const Key('grantOrSubsidyDialogTreasury')),
      );
      expect(treasury.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets(
      'thin divider is a 1 dp Container painted in EditorialMonoclePalette.border',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        final dividerFinder = find.byKey(
          const Key('grantOrSubsidyDialogThinDivider'),
        );
        expect(dividerFinder, findsOneWidget);

        final Container container = tester.widget<Container>(dividerFinder);
        expect(container.constraints?.maxHeight, 1);
        expect(container.constraints?.minHeight, 1);

        final BoxDecoration decoration = container.decoration as BoxDecoration;
        expect(decoration.color, EditorialMonoclePalette.border);
      },
    );

    testWidgets(
      'amount resolves to EditorialMonoclePalette.fg with letterSpacing == fontSize * 0.04',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        final amount = tester.widget<Text>(
          find.byKey(const Key('grantOrSubsidyDialogAmount')),
        );
        expect(amount.style?.color, EditorialMonoclePalette.fg);
        expect(amount.style?.fontSize, isNotNull);
        final double size = amount.style!.fontSize!;
        expect(amount.style?.letterSpacing, closeTo(size * 0.04, 1e-6));
      },
    );

    testWidgets(
      'warning text resolves to EditorialMonoclePalette.danger and italic when below minimum',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 500);

        final warningFinder = find.byKey(
          const Key('grantOrSubsidyDialogWarning'),
        );
        expect(warningFinder, findsOneWidget);

        final Text warning = tester.widget<Text>(warningFinder);
        expect(warning.style?.color, EditorialMonoclePalette.danger);
        expect(warning.style?.fontStyle, FontStyle.italic);
      },
    );

    testWidgets(
      'warning is absent when treasury is above the minimum step (positive negation)',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);
        expect(
          find.byKey(const Key('grantOrSubsidyDialogWarning')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'no Material AlertDialog / ListTile / Card descendant leaks into the chrome',
      (tester) async {
        await pumpGrantOrSubsidyDialog(tester, humanTreasury: 5000);

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(ListTile), findsNothing);
        expect(find.byType(Card), findsNothing);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Subsidy percent mode (Refs #3753 R3 / S15)
  // SPEC: SPEC/ui/grant-or-subsidy-dialog.md § Subsidy mode.
  // Subsidy is a treasury-independent percentage (5–20, step 5); the dialog
  // must render `%` (never `£`) and keep Submit enabled regardless of treasury.
  // ---------------------------------------------------------------------------
  group('Subsidy percent mode (Refs #3753 R3)', () {
    testWidgets(
      'renders percent amount and a percent step line with no £ currency copy',
      (tester) async {
        await pumpGrantOrSubsidyDialog(
          tester,
          humanTreasury: 0,
          isSubsidy: true,
        );

        expect(find.text('Set subsidy'), findsOneWidget);

        final amount = tester.widget<Text>(
          find.byKey(const Key('grantOrSubsidyDialogAmount')),
        );
        expect(amount.data, '$kSubsidyPercentDefault%');

        final treasury = tester.widget<Text>(
          find.byKey(const Key('grantOrSubsidyDialogTreasury')),
        );
        expect(treasury.data, contains('%'));
        expect(treasury.data, isNot(contains('£')));

        // No £ currency glyph anywhere in subsidy mode.
        expect(find.textContaining('£'), findsNothing);
      },
    );

    testWidgets('Submit is enabled even when treasury is zero', (tester) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 0, isSubsidy: true);

      final submit = find.widgetWithText(CtNinePatchButton, 'Submit');
      expect(tester.widget<CtNinePatchButton>(submit).enabled, isTrue);
      // Treasury-independent: the below-minimum warning must not render.
      expect(
        find.byKey(const Key('grantOrSubsidyDialogWarning')),
        findsNothing,
      );
    });

    testWidgets('plus steps by 5% and clamps at the 20% maximum', (
      tester,
    ) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 0, isSubsidy: true);

      await tester.tap(find.byKey(const Key('diplo_amount_plus')));
      await tester.pump();
      expect(find.text('10%'), findsOneWidget);

      // Tap well past the ceiling; amount must clamp at kSubsidyPercentMax.
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byKey(const Key('diplo_amount_plus')));
        await tester.pump();
      }
      expect(find.text('$kSubsidyPercentMax%'), findsOneWidget);
    });

    testWidgets('minus clamps at the 5% minimum', (tester) async {
      await pumpGrantOrSubsidyDialog(tester, humanTreasury: 0, isSubsidy: true);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('diplo_amount_minus')));
        await tester.pump();
      }
      expect(find.text('$kSubsidyPercentMin%'), findsOneWidget);
    });

    testWidgets('Submit emits a valid subsidy percent', (tester) async {
      final base = buildDiplomacyScreenTestGame();
      final humanPlayerId = base.players.first.id;
      final targetFactionId = base.players.length >= 2
          ? base.players[1].id
          : (base.minorNations.isNotEmpty ? base.minorNations.first.id : 'm1');

      final bus = AppEventBus.create();
      GrantOrSubsidySubmittedEvent? submitted;
      final sub = bus.on<GrantOrSubsidySubmittedEvent>().listen((e) {
        submitted = e;
      });
      addTearDown(sub.cancel);

      await tester.pumpWidget(
        buildAppShell(
          // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
          child: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                child: const Text('Open'),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => GrantOrSubsidyDialog(
                      game: base,
                      humanPlayerId: humanPlayerId,
                      targetFactionId: targetFactionId,
                      isSubsidy: true,
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

      await tester.tap(find.byKey(const Key('diplo_amount_plus')));
      await tester.pump();

      await tester.tap(find.widgetWithText(CtNinePatchButton, 'Submit'));
      await tester.pumpAndSettle();

      expect(submitted, isNotNull);
      expect(submitted!.isSubsidy, isTrue);
      expect(submitted!.amount, 10);
      expect(isValidSubsidyPercent(submitted!.amount), isTrue);
    });
  });
}
