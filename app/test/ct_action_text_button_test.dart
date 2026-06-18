// Tests for CtActionTextButton — the neutral panel-header action text button
// mirroring mockup `.action-btn` in
// SPEC/ui/mockups/GAME20001-production-panel.html (Refs #2862 S10 / C11).

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

DecoratedBox _surfaceOf(WidgetTester tester) {
  final decorated = find.descendant(
    of: find.byType(CtActionTextButton),
    matching: find.byType(DecoratedBox),
  );
  expect(decorated, findsAtLeastNWidgets(1));
  return tester.widget<DecoratedBox>(decorated.first);
}

TextStyle _labelStyleOf(WidgetTester tester) {
  // Material inserts its own AnimatedDefaultTextStyle higher in the tree, so
  // resolve the one wrapping the button's own label (nearest ancestor of the
  // label Text, which `find.ancestor` returns first).
  final animated = find.ancestor(
    of: find.text('Breakdown'),
    matching: find.byType(AnimatedDefaultTextStyle),
  );
  expect(animated, findsWidgets);
  return tester.widget<AnimatedDefaultTextStyle>(animated.first).style;
}

void main() {
  suppressLogsForTests();

  group('CtActionTextButton', () {
    testWidgets('paints the mockup .action-btn gradient surface + 1px border', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CtActionTextButton(onPressed: () {}, label: 'Breakdown')),
      );
      await tester.pump();

      final decoration = _surfaceOf(tester).decoration as BoxDecoration;
      expect(decoration.gradient, CtGradients.actionButtonGradient);
      final border = decoration.border as Border;
      expect(border.top.color, EditorialMonoclePalette.border);
      expect(border.top.width, 1.0);
    });

    testWidgets('uses compact display typography (10 px Cinzel, accent-dim idle)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CtActionTextButton(onPressed: () {}, label: 'Breakdown')),
      );
      await tester.pump();

      final style = _labelStyleOf(tester);
      expect(style.fontSize, 10);
      expect(style.fontFamily, editorialMonocleDisplayFontFamily);
      expect(style.color, EditorialMonoclePalette.accentDim);
    });

    testWidgets('lifts label colour to accent-bright on pointer hover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CtActionTextButton(onPressed: () {}, label: 'Breakdown')),
      );
      await tester.pump();

      expect(_labelStyleOf(tester).color, EditorialMonoclePalette.accentDim);

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(CtActionTextButton)));
      await tester.pumpAndSettle();

      expect(_labelStyleOf(tester).color, EditorialMonoclePalette.accentBright);
    });

    testWidgets('fires onPressed when tapped while enabled', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(CtActionTextButton(onPressed: () => taps++, label: 'Breakdown')),
      );
      await tester.pump();

      await tester.tap(find.byType(CtActionTextButton));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('disabled: fades to shared disabled opacity and ignores taps', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          CtActionTextButton(
            onPressed: () => taps++,
            label: 'Breakdown',
            enabled: false,
          ),
        ),
      );
      await tester.pump();

      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(CtActionTextButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, CtNinePatchButton.disabledOpacity);

      expect(
        find.descendant(
          of: find.byType(CtActionTextButton),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byType(CtActionTextButton), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
    });

    testWidgets('exposes button semantics with the label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CtActionTextButton(onPressed: () {}, label: 'Breakdown')),
      );
      await tester.pump();

      final semantics = find.byWidgetPredicate(
        (Widget w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == 'Breakdown',
      );
      expect(semantics, findsOneWidget);
    });
  });

  // Primary header-pill variant (issue #3514 owner decision #5): gradient
  // surface from CtGradients.buttonGradient, accent-dim border lifting to
  // accent on hover, accent label lifting to accent-bright on hover, w700.
  group('CtActionTextButton (primary variant)', () {
    TextStyle primaryLabelStyle(WidgetTester tester) {
      final animated = find.ancestor(
        of: find.text('Train'),
        matching: find.byType(AnimatedDefaultTextStyle),
      );
      expect(animated, findsWidgets);
      return tester.widget<AnimatedDefaultTextStyle>(animated.first).style;
    }

    testWidgets('paints the primary buttonGradient surface + 1px accent-dim '
        'border', (WidgetTester tester) async {
      await tester.pumpWidget(
        _host(CtActionTextButton(primary: true, onPressed: () {}, label: 'Train')),
      );
      await tester.pump();

      final decoration = _surfaceOf(tester).decoration as BoxDecoration;
      expect(decoration.gradient, CtGradients.buttonGradient);
      final border = decoration.border as Border;
      expect(border.top.color, EditorialMonoclePalette.accentDim);
      expect(border.top.width, 1.0);
    });

    testWidgets('uses accent idle label foreground at weight w700', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CtActionTextButton(primary: true, onPressed: () {}, label: 'Train')),
      );
      await tester.pump();

      final style = primaryLabelStyle(tester);
      expect(style.color, EditorialMonoclePalette.accent);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.fontFamily, editorialMonocleDisplayFontFamily);
    });

    testWidgets('lifts label colour to accent-bright on pointer hover', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _host(CtActionTextButton(primary: true, onPressed: () {}, label: 'Train')),
      );
      await tester.pump();

      expect(primaryLabelStyle(tester).color, EditorialMonoclePalette.accent);

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(CtActionTextButton)));
      await tester.pumpAndSettle();

      expect(
        primaryLabelStyle(tester).color,
        EditorialMonoclePalette.accentBright,
      );
    });
  });
}
