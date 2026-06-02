import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the generic dark editorial-monocle confirm dialog
/// (`CtConfirmDialog` + `showCtConfirmDialog`). Pins #2914 S8 — the
/// replacement of Material `AlertDialog` + `TextButton` actions in the
/// `ConfirmDialogEvent` rendering path inside `AppEventHandler`.
///
/// Visual contract anchors (per `SPEC/ui/pixel-art-ui-catalog.md`
/// § Material design ban — Ct-* counterparts):
///   * Frame: `CtDialogShell` (no Material `AlertDialog` / `Dialog`).
///   * Actions: `CtNinePatchButton` (no Material `TextButton`).
///   * Title in `--accent`, body in `--fg`.
///   * Barrier color is the canonical `EditorialMonoclePalette.dialogScrim`.
void main() {
  suppressLogsForTests();

  Future<bool?> showFromHost(
    WidgetTester tester, {
    String title = 'Confirm',
    String message = 'Proceed?',
    String confirmLabel = CtConfirmDialog.defaultConfirmLabel,
    String cancelLabel = CtConfirmDialog.defaultCancelLabel,
  }) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open-dialog'),
                onPressed: () async {
                  result = await showCtConfirmDialog(
                    context,
                    title: title,
                    message: message,
                    confirmLabel: confirmLabel,
                    cancelLabel: cancelLabel,
                  );
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
    return result;
  }

  testWidgets('renders title, message, confirm and cancel labels', (
    WidgetTester tester,
  ) async {
    await showFromHost(
      tester,
      title: 'Confirm action',
      message: 'Are you sure?',
    );
    expect(find.text('Confirm action'), findsOneWidget);
    expect(find.text('Are you sure?'), findsOneWidget);
    expect(find.text(CtConfirmDialog.defaultConfirmLabel), findsOneWidget);
    expect(find.text(CtConfirmDialog.defaultCancelLabel), findsOneWidget);
  });

  testWidgets('honors custom confirm/cancel labels', (
    WidgetTester tester,
  ) async {
    await showFromHost(
      tester,
      confirmLabel: 'Proceed',
      cancelLabel: 'Abort',
    );
    expect(find.text('Proceed'), findsOneWidget);
    expect(find.text('Abort'), findsOneWidget);
    // Default labels are not used when overrides are supplied.
    expect(find.text(CtConfirmDialog.defaultConfirmLabel), findsNothing);
    expect(find.text(CtConfirmDialog.defaultCancelLabel), findsNothing);
  });

  testWidgets('uses CtNinePatchButton actions (no Material action buttons)', (
    WidgetTester tester,
  ) async {
    await showFromHost(tester);
    expect(
      find.descendant(
        of: find.byType(CtConfirmDialog),
        matching: find.byType(CtNinePatchButton),
      ),
      findsNWidgets(2),
    );
    // The host's opener uses ElevatedButton; the dialog body must not.
    expect(
      find.descendant(
        of: find.byType(CtConfirmDialog),
        matching: find.byType(TextButton),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(CtConfirmDialog),
        matching: find.byType(ElevatedButton),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(CtConfirmDialog),
        matching: find.byType(OutlinedButton),
      ),
      findsNothing,
    );
    // No raw Material AlertDialog under the body either.
    expect(
      find.descendant(
        of: find.byType(CtConfirmDialog),
        matching: find.byType(AlertDialog),
      ),
      findsNothing,
    );
  });

  testWidgets('frames the body in a CtDialogShell', (
    WidgetTester tester,
  ) async {
    await showFromHost(tester);
    expect(
      find.descendant(
        of: find.byType(CtConfirmDialog),
        matching: find.byType(CtDialogShell),
      ),
      findsOneWidget,
    );
  });

  testWidgets('title renders in --accent and message in --fg', (
    WidgetTester tester,
  ) async {
    await showFromHost(
      tester,
      title: 'Title text',
      message: 'Body text',
    );
    final Text titleText = tester.widget<Text>(find.text('Title text'));
    expect(titleText.style?.color, EditorialMonoclePalette.accent);

    final Text bodyText = tester.widget<Text>(find.text('Body text'));
    expect(bodyText.style?.color, EditorialMonoclePalette.fg);
  });

  testWidgets('barrierColor matches the canonical dialog-scrim token', (
    WidgetTester tester,
  ) async {
    await showFromHost(tester);
    final Iterable<ModalBarrier> dimBarriers = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .where((ModalBarrier b) => b.color != null);
    expect(
      dimBarriers.where(
        (ModalBarrier b) => b.color == EditorialMonoclePalette.dialogScrim,
      ),
      isNotEmpty,
      reason:
          'showDialog barrierColor must resolve to the canonical '
          '--dialog-scrim token; literal Colors.black54 is a regression.',
    );
  });

  testWidgets('Confirm tap resolves the future to true', (
    WidgetTester tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open-dialog'),
                onPressed: () async {
                  result = await showCtConfirmDialog(
                    context,
                    title: 'Confirm',
                    message: 'Proceed?',
                  );
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
    await tester.tap(find.text(CtConfirmDialog.defaultConfirmLabel));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('Cancel tap resolves the future to false', (
    WidgetTester tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open-dialog'),
                onPressed: () async {
                  result = await showCtConfirmDialog(
                    context,
                    title: 'Confirm',
                    message: 'Proceed?',
                  );
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
    await tester.tap(find.text(CtConfirmDialog.defaultCancelLabel));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('Barrier tap dismisses dialog as cancel (false)', (
    WidgetTester tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                key: const Key('open-dialog'),
                onPressed: () async {
                  result = await showCtConfirmDialog(
                    context,
                    title: 'Confirm',
                    message: 'Proceed?',
                  );
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
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(
      result,
      isFalse,
      reason:
          'Barrier-dismissed confirm dialog must resolve to false to mirror '
          'the ConfirmDialogEvent bool contract (cancel intent).',
    );
  });
}
