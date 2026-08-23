// Shared `showDialog` / [AlertDialog] launcher for widget-test pins
// (#4598 Slice B). Replaces private `_wrap` + `_pumpDialog` clones in
// `e2e_radio_list_tiles_in_alert_dialogs_test.dart`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e_widget_pump_harness.dart';

const String kE2eAlertDialogOpenLabel = 'open';

/// Pumps [outsideDialog] plus an [ElevatedButton] that opens an [AlertDialog]
/// whose content is [dialogChildren], then taps the opener and settles.
Future<void> pumpE2eAlertDialog(
  WidgetTester tester, {
  required List<Widget> dialogChildren,
  List<Widget> outsideDialog = const <Widget>[],
  String openLabel = kE2eAlertDialogOpenLabel,
}) async {
  await pumpE2eScaffold(
    tester,
    Column(
      children: [
        ...outsideDialog,
        Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) =>
                      AlertDialog(content: Column(children: dialogChildren)),
                );
              },
              child: Text(openLabel),
            );
          },
        ),
      ],
    ),
  );
  await tester.tap(find.text(openLabel));
  await tester.pumpAndSettle();
  expect(
    find.byType(AlertDialog),
    findsOneWidget,
    reason:
        'Test harness sanity: the AlertDialog must be mounted before '
        'asserting against the dialog-scoped finder.',
  );
}
