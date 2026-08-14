// Pump/inspect helpers for CtNinePatchButton dark-chrome tests (Refs #4352).

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../app_shell_harness.dart';

Future<void> pumpNinePatchButton(
  WidgetTester tester, {
  required VoidCallback? onPressed,
  bool enabled = true,
  bool dangerVariant = false,
  bool mutedVariant = false,
  double? disabledOpacityOverride,
  LinearGradient? gradient,
  LinearGradient? pressedGradient,
  Widget child = const Text('Confirm'),
}) async {
  await pumpAppShell(
    tester,
    settle: true,
    child: Scaffold(
      body: Center(
        child: SizedBox(
          width: 200,
          child: CtNinePatchButton(
            onPressed: onPressed,
            enabled: enabled,
            dangerVariant: dangerVariant,
            mutedVariant: mutedVariant,
            disabledOpacityOverride: disabledOpacityOverride,
            gradient: gradient,
            pressedGradient: pressedGradient,
            child: child,
          ),
        ),
      ),
    ),
  );
}

DecoratedBox findNinePatchButtonSurfaceDecoratedBox(WidgetTester tester) {
  final Finder boxes = find.descendant(
    of: find.byType(CtNinePatchButton),
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is DecoratedBox &&
          (widget.decoration is BoxDecoration) &&
          (widget.decoration as BoxDecoration).gradient != null,
    ),
  );
  expect(boxes, findsAtLeastNWidgets(1));
  return tester.widget<DecoratedBox>(boxes.first);
}

BoxDecoration ninePatchButtonSurfaceDecoration(WidgetTester tester) =>
    findNinePatchButtonSurfaceDecoratedBox(tester).decoration as BoxDecoration;

TextSpan ninePatchButtonLabelSpan(WidgetTester tester, String label) {
  final RichText rich = tester.widget<RichText>(
    find.descendant(of: find.text(label), matching: find.byType(RichText)),
  );
  return rich.text as TextSpan;
}

Finder ninePatchButtonOpacityFinder(double opacity) => find.descendant(
  of: find.byType(CtNinePatchButton),
  matching: find.byWidgetPredicate(
    (Widget w) => w is Opacity && w.opacity == opacity,
  ),
);

void expectNinePatchGradientColors(
  WidgetTester tester,
  List<Color> colors, {
  String? reason,
}) {
  final LinearGradient gradient =
      ninePatchButtonSurfaceDecoration(tester).gradient! as LinearGradient;
  expect(gradient.colors, colors, reason: reason);
}

void expectNinePatchBorderColor(
  WidgetTester tester,
  Color color, {
  String? reason,
}) {
  final Border border =
      ninePatchButtonSurfaceDecoration(tester).border! as Border;
  expect(border.top.color, color, reason: reason);
}

void expectNinePatchLabelColor(
  WidgetTester tester,
  String label,
  Color color, {
  String? reason,
}) {
  expect(
    ninePatchButtonLabelSpan(tester, label).style?.color,
    color,
    reason: reason,
  );
}

Future<TestGesture> hoverOverNinePatchButton(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: const Offset(1, 1));
  await tester.pumpAndSettle();
  await gesture.moveTo(tester.getCenter(find.byType(CtNinePatchButton)));
  await tester.pump();
  await tester.pump(CtNinePatchButton.animationDuration);
  await tester.pumpAndSettle();
  return gesture;
}

Future<TestGesture> holdNinePatchButtonPress(WidgetTester tester) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(find.byType(CtNinePatchButton)),
  );
  await tester.pump();
  await tester.pump(CtNinePatchButton.animationDuration);
  await tester.pumpAndSettle();
  return gesture;
}
