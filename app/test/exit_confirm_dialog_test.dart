import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/exit_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the in-game shell exit-to-main-menu confirmation dialog.
///
/// SPEC: `SPEC/ui/in-game-shell-narrow.md` § Android back confirm. The
/// dialog must (a) wash the underlying canvas with the canonical
/// `--dialog-scrim` token, (b) render the title in `--accent`, (c) render
/// the body in `--fg`, (d) render the destructive `Exit` action's label in
/// `--danger`, and (e) use only `CtNinePatchButton` actions (no Material
/// `ElevatedButton`/`TextButton`/`OutlinedButton`).
void main() {
  suppressLogsForTests();

  Future<void> showDialogUnderTest(WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open-dialog'),
                onPressed: () => showExitToMainMenuConfirmDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the SPEC title and body literals', (
    WidgetTester tester,
  ) async {
    await showDialogUnderTest(tester);
    expect(find.text('Exit game?'), findsOneWidget);
    expect(
      find.text('Your current progress will be lost if not saved.'),
      findsOneWidget,
    );
  });

  testWidgets('uses CtNinePatchButton actions only (no Material buttons)', (
    WidgetTester tester,
  ) async {
    await showDialogUnderTest(tester);
    expect(find.byType(CtNinePatchButton), findsNWidgets(2));
    // The opener button in the host is an ElevatedButton; the dialog's own
    // tree must have no Material action buttons. Scope the negative checks
    // to the dialog body.
    expect(
      find.descendant(
        of: find.byType(ExitConfirmDialog),
        matching: find.byType(ElevatedButton),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ExitConfirmDialog),
        matching: find.byType(TextButton),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(ExitConfirmDialog),
        matching: find.byType(OutlinedButton),
      ),
      findsNothing,
    );
  });

  testWidgets('Exit label resolves to EditorialMonoclePalette.danger', (
    WidgetTester tester,
  ) async {
    await showDialogUnderTest(tester);
    final Text exitText = tester.widget<Text>(find.text('Exit'));
    expect(
      exitText.style?.color,
      EditorialMonoclePalette.danger,
      reason:
          'Exit is the destructive action and must render its label in '
          '--danger so the destructive intent is visually distinct from '
          'Cancel (which keeps the default brass label color).',
    );
  });

  testWidgets('Cancel label keeps the default brass styling (no danger)', (
    WidgetTester tester,
  ) async {
    await showDialogUnderTest(tester);
    final Text cancelText = tester.widget<Text>(find.text('Cancel'));
    expect(
      cancelText.style?.color,
      isNot(EditorialMonoclePalette.danger),
      reason:
          'Cancel is the non-destructive action and must not adopt --danger.',
    );
  });

  testWidgets('Title renders in --accent and body in --fg', (
    WidgetTester tester,
  ) async {
    await showDialogUnderTest(tester);
    final Text titleText = tester.widget<Text>(find.text('Exit game?'));
    expect(titleText.style?.color, EditorialMonoclePalette.accent);

    final Text bodyText = tester.widget<Text>(
      find.text('Your current progress will be lost if not saved.'),
    );
    expect(bodyText.style?.color, EditorialMonoclePalette.fg);
  });

  testWidgets('barrierColor on showDialog matches the canonical scrim', (
    WidgetTester tester,
  ) async {
    await showDialogUnderTest(tester);
    // ModalBarrier widgets wrap the dialog with the barrier color. Pin the
    // dim barrier's color to the canonical dialogScrim token.
    final Iterable<ModalBarrier> dimBarriers = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .where((b) => b.color != null);
    expect(
      dimBarriers
          .where((b) => b.color == EditorialMonoclePalette.dialogScrim),
      isNotEmpty,
      reason:
          'showDialog barrierColor must resolve to the canonical '
          '--dialog-scrim token; literal Colors.black54 is a regression.',
    );
  });

  testWidgets('Cancel taps return false', (WidgetTester tester) async {
    bool? result;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open-dialog'),
                onPressed: () async {
                  result = await showExitToMainMenuConfirmDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('Exit taps return true', (WidgetTester tester) async {
    bool? result;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open-dialog'),
                onPressed: () async {
                  result = await showExitToMainMenuConfirmDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('Barrier tap dismisses dialog without forcing exit', (
    WidgetTester tester,
  ) async {
    bool? result;
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open-dialog'),
                onPressed: () async {
                  result = await showExitToMainMenuConfirmDialog(context);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-dialog')));
    await tester.pumpAndSettle();
    // Tap on the dim barrier (top-left of the screen) to dismiss.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(
      result,
      isFalse,
      reason:
          'Barrier-dismissed dialog must resolve to false so the player '
          'stays on the in-game shell.',
    );
  });
}
