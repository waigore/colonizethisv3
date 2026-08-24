import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Future<void> pumpIconAction(WidgetTester tester, Widget child) async {
  await pumpAppShell(
    tester,
    child: Scaffold(
      body: Center(child: child),
    ),
  );
}

AnimatedContainer bodyContainer(WidgetTester tester) {
  return tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byType(CtIconAction),
      matching: find.byType(AnimatedContainer),
    ),
  );
}

Color bodyColor(WidgetTester tester) {
  final BoxDecoration deco = bodyContainer(tester).decoration! as BoxDecoration;
  return deco.color!;
}

Icon glyphIcon(WidgetTester tester) {
  return tester.widget<Icon>(
    find.descendant(
      of: find.byType(CtIconAction),
      matching: find.byType(Icon),
    ),
  );
}

