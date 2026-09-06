// Pump helpers for CtConfirmDialog widget tests (Refs #4734 Slice H).

import 'package:colonizethis_app/widgets/ct_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Widget ctConfirmDialogOpenHost({
  required Future<void> Function(BuildContext context) onOpen,
}) =>
    buildAppShell(
      child: Scaffold(
        body: Builder(
          builder: (BuildContext context) => Center(
            child: ElevatedButton(
              key: const Key('open-dialog'),
              onPressed: () => onOpen(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

Future<bool?> showCtConfirmDialogFromHost(
  WidgetTester tester, {
  String title = 'Confirm',
  String message = 'Proceed?',
  String confirmLabel = CtConfirmDialog.defaultConfirmLabel,
  String cancelLabel = CtConfirmDialog.defaultCancelLabel,
}) async {
  bool? result;
  await tester.pumpWidget(
    ctConfirmDialogOpenHost(
      onOpen: (BuildContext context) async {
        result = await showCtConfirmDialog(
          context,
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
        );
      },
    ),
  );
  await tester.tap(find.byKey(const Key('open-dialog')));
  await tester.pumpAndSettle();
  return result;
}
