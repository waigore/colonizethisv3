// Pump/decoration helpers for CtDialogShell widget tests (Refs #4734 Slice H).

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Widget ctDialogShellTestHost(Widget child, {ThemeData? themeOverride}) {
  final Widget body = themeOverride == null
      ? child
      : Theme(data: themeOverride, child: child);
  return buildAppShell(child: body);
}

Future<void> pumpCtDialogShellDefault(WidgetTester tester) async {
  await tester.pumpWidget(
    ctDialogShellTestHost(
      const Scaffold(
        body: Center(
          child: CtDialogShell(
            child: Text('Body'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

BoxDecoration ctDialogShellFrameDecoration(WidgetTester tester) {
  final DecoratedBox decorated = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(CtDialogShell),
      matching: find.byType(DecoratedBox),
    ),
  );
  return decorated.decoration as BoxDecoration;
}
