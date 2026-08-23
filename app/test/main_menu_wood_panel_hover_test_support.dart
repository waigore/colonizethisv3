// CtMainMenu pixelArt wood-panel hover helpers (Refs #4606 Slice D).
// SPEC/ui/main-menu.md § Variant rendering hover ACs.

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/main_menu.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

Future<void> pumpPixelArtMainMenu(WidgetTester tester) async {
  await pumpAppShell(
    tester,
    settle: true,
    child: CtMainMenu(
      variant: MainMenuVariant.pixelArt,
      state: MainMenuState.default_,
      version: 'v1.0.0',
      onQuickStart: () {},
      onNewGame: () {},
      onLoadGame: () {},
      onSettings: () {},
      onQuit: () {},
    ),
  );
}

Finder woodPanelButtonFor(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(CtNinePatchButton),
  );
}

DecoratedBox findWoodPanelSurfaceBox(WidgetTester tester, String label) {
  final Finder boxes = find.descendant(
    of: woodPanelButtonFor(label),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient != null,
    ),
  );
  expect(
    boxes,
    findsAtLeastNWidgets(1),
    reason:
        'Wood-panel button "$label" must paint a gradient surface DecoratedBox',
  );
  return tester.widget<DecoratedBox>(boxes.first);
}

RichText findWoodPanelLabelRichText(WidgetTester tester, String label) {
  return tester.widget<RichText>(
    find.descendant(of: find.text(label), matching: find.byType(RichText)),
  );
}

CustomPainter findWoodPanelBrassPainter(WidgetTester tester, String label) {
  final Finder painters = find.descendant(
    of: woodPanelButtonFor(label),
    matching: find.byWidgetPredicate(
      (Widget w) =>
          w is CustomPaint &&
          w.painter != null &&
          w.painter.runtimeType.toString() ==
              'CtNinePatchButtonBracketsPainter',
    ),
  );
  expect(
    painters,
    findsOneWidget,
    reason:
        'Wood-panel button "$label" must paint a single brass-corner-brackets '
        'overlay (CustomPaint with CtNinePatchButtonBracketsPainter).',
  );
  final CustomPaint paint = tester.widget<CustomPaint>(painters);
  return paint.painter!;
}

Color? brassColorFromPainter(CustomPainter painter) {
  final canvas = _ColorRecordingCanvas();
  painter.paint(canvas, const Size(120, 48));
  return canvas.firstColor;
}

class _ColorRecordingCanvas implements Canvas {
  Color? firstColor;

  @override
  void drawRect(Rect rect, Paint paint) {
    firstColor ??= paint.color;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<TestGesture> addMainMenuMousePointer(WidgetTester tester) async {
  final TestGesture gesture = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
  );
  addTearDown(gesture.removePointer);
  await gesture.addPointer(location: const Offset(-1000, -1000));
  await tester.pump();
  return gesture;
}

Future<void> settleHoverColorAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(CtNinePatchButton.animationDuration);
  await tester.pump(const Duration(milliseconds: 16));
}

Future<void> settleHoverExitAnimation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(CtNinePatchButton.animationDuration);
  await tester.pumpAndSettle();
}
