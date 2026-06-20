// SPEC/ui/next-turn-confirmation.md — dark-theme styling for the DLG60001
// confirmation dialog (universal #2867 dialog pattern).

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/next_turn_confirmation_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_dialog_shell.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Widget hostApp() {
    return MaterialApp(
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (ctx) => Center(
            child: TextButton(
              onPressed: () {
                showNextTurnConfirmationDialog(ctx, currentTurn: 7);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(hostApp());
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
    'Given the dialog is shown When the user taps Yes Then it returns true',
    (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showNextTurnConfirmationDialog(
                      ctx,
                      currentTurn: 3,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    },
  );

  testWidgets(
    'Given the dialog is shown When the user taps No Then it returns false',
    (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: TextButton(
                  onPressed: () async {
                    result = await showNextTurnConfirmationDialog(
                      ctx,
                      currentTurn: 3,
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    },
  );
}
