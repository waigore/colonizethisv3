// Shared pump/decoration helpers for CtToggleSwitch widget tests (Refs #4352).
// SPEC: SPEC/ui/pixel-art-ui-catalog.md.

import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Future<void> pumpCtToggle(WidgetTester tester, Widget child) async {
  await pumpAppShell(
    tester,
    child: Scaffold(body: Center(child: child)),
  );
}

BoxDecoration ctToggleTrackDecoration(WidgetTester tester) {
  final AnimatedContainer container = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey<String>('ctToggleSwitchTrack')),
  );
  return container.decoration! as BoxDecoration;
}

BoxDecoration ctToggleKnobDecoration(WidgetTester tester) {
  final AnimatedContainer container = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey<String>('ctToggleSwitchKnob')),
  );
  return container.decoration! as BoxDecoration;
}

Future<void> hoverCtToggleSwitch(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: Offset.zero);
  await gesture.moveTo(tester.getCenter(find.byType(CtToggleSwitch)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}
