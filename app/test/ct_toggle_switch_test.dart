import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpToggle(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
    await tester.pump();
  }

  BoxDecoration trackDecoration(WidgetTester tester) {
    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('ctToggleSwitchTrack')),
    );
    return container.decoration! as BoxDecoration;
  }

  BoxDecoration knobDecoration(WidgetTester tester) {
    final AnimatedContainer container = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('ctToggleSwitchKnob')),
    );
    return container.decoration! as BoxDecoration;
  }

  group('CtToggleSwitch visual contract (R8)', () {
    testWidgets('renders with the documented 24x12 track', (tester) async {
      await pumpToggle(
        tester,
        CtToggleSwitch(value: false, onChanged: (_) {}),
      );
      final Size size = tester.getSize(find.byType(CtToggleSwitch));
      expect(size.width, CtToggleSwitch.trackWidth);
      expect(size.height, CtToggleSwitch.trackHeight);
      expect(CtToggleSwitch.trackWidth, 24);
      expect(CtToggleSwitch.trackHeight, 12);
    });

    testWidgets('off state: track --surface fill + 1px --accent-dim border', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        CtToggleSwitch(value: false, onChanged: (_) {}),
      );
      final BoxDecoration deco = trackDecoration(tester);
      expect(deco.color, EditorialMonoclePalette.surface);
      final Border border = deco.border! as Border;
      expect(border.top.color, EditorialMonoclePalette.accentDim);
      expect(border.top.width, CtToggleSwitch.borderWidth);
    });

    testWidgets('off state: knob 10x10 --muted fill at 1px from track left', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        CtToggleSwitch(value: false, onChanged: (_) {}),
      );
      final BoxDecoration deco = knobDecoration(tester);
      expect(deco.color, EditorialMonoclePalette.muted);
      final Border border = deco.border! as Border;
      expect(border.top.color, EditorialMonoclePalette.accentDim);
      expect(border.top.width, CtToggleSwitch.borderWidth);
      expect(deco.boxShadow, anyOf(isNull, isEmpty));

      final AnimatedPositioned positioned = tester.widget<AnimatedPositioned>(
        find.descendant(
          of: find.byType(CtToggleSwitch),
          matching: find.byType(AnimatedPositioned),
        ),
      );
      expect(positioned.left, CtToggleSwitch.knobOffOffset);
      expect(CtToggleSwitch.knobOffOffset, 1);

      final Size knobSize = tester.getSize(
        find.byKey(const ValueKey<String>('ctToggleSwitchKnob')),
      );
      expect(knobSize.width, CtToggleSwitch.knobSize);
      expect(knobSize.height, CtToggleSwitch.knobSize);
      expect(CtToggleSwitch.knobSize, 10);
    });

    testWidgets('on state: track --surface-lite + 1px --accent border', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        CtToggleSwitch(value: true, onChanged: (_) {}),
      );
      await tester.pump(const Duration(milliseconds: 200));
      final BoxDecoration deco = trackDecoration(tester);
      expect(deco.color, EditorialMonoclePalette.surfaceLite);
      final Border border = deco.border! as Border;
      expect(border.top.color, EditorialMonoclePalette.accent);
      expect(border.top.width, CtToggleSwitch.borderWidth);
    });

    testWidgets(
      'on state: knob --accent + 1px --accent-bright border at 13px '
      'with 60% --accent halo',
      (tester) async {
        await pumpToggle(
          tester,
          CtToggleSwitch(value: true, onChanged: (_) {}),
        );
        await tester.pump(const Duration(milliseconds: 200));

        final BoxDecoration deco = knobDecoration(tester);
        expect(deco.color, EditorialMonoclePalette.accent);
        final Border border = deco.border! as Border;
        expect(border.top.color, EditorialMonoclePalette.accentBright);
        expect(border.top.width, CtToggleSwitch.borderWidth);

        final AnimatedPositioned positioned = tester.widget<AnimatedPositioned>(
          find.descendant(
            of: find.byType(CtToggleSwitch),
            matching: find.byType(AnimatedPositioned),
          ),
        );
        expect(positioned.left, CtToggleSwitch.knobOnOffset);
        expect(CtToggleSwitch.knobOnOffset, 13);

        final List<BoxShadow> glow = deco.boxShadow!;
        expect(glow, hasLength(1));
        expect(glow.first.spreadRadius, CtToggleSwitch.glowSpread);
        expect(glow.first.blurRadius, 0);
        expect(
          glow.first.color.a,
          closeTo(CtToggleSwitch.glowRestAlpha, 1e-6),
        );
      },
    );

    testWidgets('slide distance is 12 px between off and on knob positions', (
      tester,
    ) async {
      expect(CtToggleSwitch.knobTravel, 12);
      expect(
        CtToggleSwitch.knobOnOffset - CtToggleSwitch.knobOffOffset,
        12,
      );
    });

    testWidgets(
      'enabled animation duration matches the documented 120ms ease-out',
      (tester) async {
        await pumpToggle(
          tester,
          CtToggleSwitch(value: false, onChanged: (_) {}),
        );
        final AnimatedContainer container = tester.widget<AnimatedContainer>(
          find.byKey(const ValueKey<String>('ctToggleSwitchTrack')),
        );
        expect(container.duration, CtToggleSwitch.animationDuration);
        expect(container.duration, const Duration(milliseconds: 120));
        expect(container.curve, CtToggleSwitch.animationCurve);
        expect(container.curve, Curves.easeOut);
      },
    );

    testWidgets('tapping the toggle calls onChanged with the negated value', (
      tester,
    ) async {
      bool? captured;
      await pumpToggle(
        tester,
        CtToggleSwitch(
          value: false,
          onChanged: (v) => captured = v,
        ),
      );
      await tester.tap(find.byType(CtToggleSwitch));
      expect(captured, isTrue);
    });

    testWidgets('disabled (onChanged == null) renders 0.4 opacity', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        const CtToggleSwitch(value: false, onChanged: null),
      );
      final Opacity opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(CtToggleSwitch),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, CtToggleSwitch.disabledOpacity);
      expect(opacity.opacity, 0.4);
    });

    testWidgets('disabled does not render a tap detector (negative path)', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        const CtToggleSwitch(value: false, onChanged: null),
      );
      expect(
        find.descendant(
          of: find.byType(CtToggleSwitch),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(CtToggleSwitch),
          matching: find.byType(MouseRegion),
        ),
        findsNothing,
      );
    });

    testWidgets('disabled freezes animation (duration = Duration.zero)', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        const CtToggleSwitch(value: true, onChanged: null),
      );
      final AnimatedContainer track = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey<String>('ctToggleSwitchTrack')),
      );
      expect(track.duration, Duration.zero);
      final AnimatedContainer knob = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey<String>('ctToggleSwitchKnob')),
      );
      expect(knob.duration, Duration.zero);
    });

    testWidgets('enabled wraps without an Opacity (negative path)', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        CtToggleSwitch(value: false, onChanged: (_) {}),
      );
      expect(
        find.descendant(
          of: find.byType(CtToggleSwitch),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });

  group('CtToggleSwitch hover states (R8)', () {
    testWidgets('hover-off: knob fill brightens from --muted to --accent-dim', (
      tester,
    ) async {
      await pumpToggle(
        tester,
        CtToggleSwitch(value: false, onChanged: (_) {}),
      );

      final TestGesture gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      addTearDown(gesture.removePointer);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byType(CtToggleSwitch)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final BoxDecoration deco = knobDecoration(tester);
      expect(deco.color, EditorialMonoclePalette.accentDim);
      expect(deco.boxShadow, anyOf(isNull, isEmpty));
    });

    testWidgets(
      'hover-on: knob brightens from --accent to --accent-bright + halo '
      'reaches 100%',
      (tester) async {
        await pumpToggle(
          tester,
          CtToggleSwitch(value: true, onChanged: (_) {}),
        );

        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.byType(CtToggleSwitch)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final BoxDecoration deco = knobDecoration(tester);
        expect(deco.color, EditorialMonoclePalette.accentBright);
        final List<BoxShadow> glow = deco.boxShadow!;
        expect(glow, hasLength(1));
        expect(
          glow.first.color.a,
          closeTo(CtToggleSwitch.glowHoverAlpha, 1e-6),
        );
      },
    );

    testWidgets(
      'hover ignored while disabled (no knob colour change)',
      (tester) async {
        await pumpToggle(
          tester,
          const CtToggleSwitch(value: false, onChanged: null),
        );

        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.byType(CtToggleSwitch)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final BoxDecoration deco = knobDecoration(tester);
        expect(deco.color, EditorialMonoclePalette.muted);
      },
    );
  });
}
