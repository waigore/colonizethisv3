// SPEC/ui/next-turn-confirmation.md — dark-theme styling for the DLG60001
// confirmation dialog (universal #2867 dialog pattern).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/overlays/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Widget hostApp({
    required Future<void> Function(BuildContext) onOpen,
  }) {
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    return buildAppShell(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      child: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: TextButton(
              onPressed: () => onOpen(ctx),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      hostApp(
        onOpen: (ctx) async {
          await showNextTurnConfirmationDialog(ctx, currentTurn: 7);
        },
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Given the dialog is shown When built Then it hosts CtDialogShell '
    '(no Material AlertDialog)',
    (WidgetTester tester) async {
      await openDialog(tester);

      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'Given the dialog is shown When built Then title text resolves to accent',
    (WidgetTester tester) async {
      await openDialog(tester);

      final titleFinder = find.text('End turn?');
      expect(titleFinder, findsOneWidget);
      expect(
        tester.widget<Text>(titleFinder).style?.color,
        equals(EditorialMonoclePalette.accent),
      );
    },
  );

  testWidgets(
    'Given the dialog is shown When built Then body text resolves to fg',
    (WidgetTester tester) async {
      await openDialog(tester);

      final bodyFinder = find.textContaining('Turn 7 will end');
      expect(bodyFinder, findsOneWidget);
      expect(
        tester.widget<Text>(bodyFinder).style?.color,
        equals(EditorialMonoclePalette.fg),
      );
    },
  );

  testWidgets(
    'Given the dialog is shown When built Then both actions use '
    'CtNinePatchButton (no Material TextButton / ElevatedButton in the dialog)',
    (WidgetTester tester) async {
      await openDialog(tester);

      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsNWidgets(2));
      // The host page's "open" trigger is a TextButton; constrain the search
      // to the open dialog (descendants of CtDialogShell).
      expect(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(ElevatedButton),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Given the dialog is shown When the user taps Yes Then it returns confirmed',
    (WidgetTester tester) async {
      NextTurnConfirmationResult? result;
      await tester.pumpWidget(
        hostApp(
          onOpen: (ctx) async {
            result = await showNextTurnConfirmationDialog(
              ctx,
              currentTurn: 3,
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(result?.confirmed, isTrue);
    },
  );

  testWidgets(
    'Given the dialog is shown When the user taps No Then it returns not confirmed',
    (WidgetTester tester) async {
      NextTurnConfirmationResult? result;
      await tester.pumpWidget(
        hostApp(
          onOpen: (ctx) async {
            result = await showNextTurnConfirmationDialog(
              ctx,
              currentTurn: 3,
            );
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(result?.confirmed, isFalse);
    },
  );

  testWidgets(
    'Given idle workers would reduce labour When DLG60001 builds Then no labour '
    'readiness copy is shown (Refs #4237 non-goals)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        hostApp(
          onOpen: (ctx) async {
            await showNextTurnConfirmationDialog(ctx, currentTurn: 7);
          },
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Labour this turn:'), findsNothing);
      expect(find.text('Labour details'), findsNothing);
      expect(
        find.text('Some workers are not working — food is short.'),
        findsNothing,
      );
    },
  );
}
