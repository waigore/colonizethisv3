import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_toggle_switch_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtToggleSwitch onGlowColor override (#2867 R22 / R24)', () {
    testWidgets(
      'on-state glow defaults to --accent when onGlowColor is omitted',
      (tester) async {
        await pumpCtToggle(
          tester,
          CtToggleSwitch(value: true, onChanged: (_) {}),
        );
        await tester.pump(const Duration(milliseconds: 200));
        final BoxDecoration deco = ctToggleKnobDecoration(tester);
        final List<BoxShadow> glow = deco.boxShadow!;
        expect(glow, hasLength(1));
        // Compare the underlying palette color ignoring alpha (the glow
        // halo applies the rest/hover alpha; the hue/luma must equal
        // --accent).
        final Color expected = EditorialMonoclePalette.accent.withValues(
          alpha: CtToggleSwitch.glowRestAlpha,
        );
        expect(glow.first.color.r, closeTo(expected.r, 1e-6));
        expect(glow.first.color.g, closeTo(expected.g, 1e-6));
        expect(glow.first.color.b, closeTo(expected.b, 1e-6));
      },
    );

    testWidgets(
      'on-state glow resolves to the supplied onGlowColor (positive: --success)',
      (tester) async {
        await pumpCtToggle(
          tester,
          CtToggleSwitch(
            value: true,
            onChanged: (_) {},
            onGlowColor: EditorialMonoclePalette.success,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        final BoxDecoration deco = ctToggleKnobDecoration(tester);
        final List<BoxShadow> glow = deco.boxShadow!;
        expect(glow, hasLength(1));
        final Color expected = EditorialMonoclePalette.success.withValues(
          alpha: CtToggleSwitch.glowRestAlpha,
        );
        expect(glow.first.color.r, closeTo(expected.r, 1e-6));
        expect(glow.first.color.g, closeTo(expected.g, 1e-6));
        expect(glow.first.color.b, closeTo(expected.b, 1e-6));
        expect(glow.first.color.a, closeTo(CtToggleSwitch.glowRestAlpha, 1e-6));
      },
    );

    testWidgets(
      'on-state glow resolves to the supplied onGlowColor (positive: --danger)',
      (tester) async {
        await pumpCtToggle(
          tester,
          CtToggleSwitch(
            value: true,
            onChanged: (_) {},
            onGlowColor: EditorialMonoclePalette.danger,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        final BoxDecoration deco = ctToggleKnobDecoration(tester);
        final List<BoxShadow> glow = deco.boxShadow!;
        expect(glow, hasLength(1));
        final Color expected = EditorialMonoclePalette.danger.withValues(
          alpha: CtToggleSwitch.glowRestAlpha,
        );
        expect(glow.first.color.r, closeTo(expected.r, 1e-6));
        expect(glow.first.color.g, closeTo(expected.g, 1e-6));
        expect(glow.first.color.b, closeTo(expected.b, 1e-6));
        expect(glow.first.color.a, closeTo(CtToggleSwitch.glowRestAlpha, 1e-6));
      },
    );

    testWidgets(
      'off-state draws no glow even when onGlowColor is set (negative)',
      (tester) async {
        await pumpCtToggle(
          tester,
          CtToggleSwitch(
            value: false,
            onChanged: (_) {},
            onGlowColor: EditorialMonoclePalette.success,
          ),
        );
        final BoxDecoration deco = ctToggleKnobDecoration(tester);
        expect(deco.boxShadow, anyOf(isNull, isEmpty));
      },
    );

    testWidgets(
      'hover on with custom onGlowColor reaches full alpha while preserving hue',
      (tester) async {
        await pumpCtToggle(
          tester,
          CtToggleSwitch(
            value: true,
            onChanged: (_) {},
            onGlowColor: EditorialMonoclePalette.success,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.byType(CtToggleSwitch)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final BoxDecoration deco = ctToggleKnobDecoration(tester);
        final List<BoxShadow> glow = deco.boxShadow!;
        expect(glow, hasLength(1));
        expect(
          glow.first.color.a,
          closeTo(CtToggleSwitch.glowHoverAlpha, 1e-6),
        );
        // Hue/luma must still equal --success even at the full hover alpha.
        final Color expected = EditorialMonoclePalette.success.withValues(
          alpha: CtToggleSwitch.glowHoverAlpha,
        );
        expect(glow.first.color.r, closeTo(expected.r, 1e-6));
        expect(glow.first.color.g, closeTo(expected.g, 1e-6));
        expect(glow.first.color.b, closeTo(expected.b, 1e-6));
      },
    );
  });

  group('CtToggleSwitch hover states (R8)', () {
    testWidgets('hover-off: knob fill brightens from --muted to --accent-dim', (
      tester,
    ) async {
      await pumpCtToggle(
        tester,
        CtToggleSwitch(value: false, onChanged: (_) {}),
      );
      await hoverCtToggleSwitch(tester);
      final BoxDecoration deco = ctToggleKnobDecoration(tester);
      expect(deco.color, EditorialMonoclePalette.accentDim);
      expect(deco.boxShadow, anyOf(isNull, isEmpty));
    });

    testWidgets(
      'hover-on: knob brightens from --accent to --accent-bright + halo '
      'reaches 100%',
      (tester) async {
        await pumpCtToggle(
          tester,
          CtToggleSwitch(value: true, onChanged: (_) {}),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await hoverCtToggleSwitch(tester);
        final BoxDecoration deco = ctToggleKnobDecoration(tester);
        expect(deco.color, EditorialMonoclePalette.accentBright);
        final List<BoxShadow> glow = deco.boxShadow!;
        expect(glow, hasLength(1));
        expect(
          glow.first.color.a,
          closeTo(CtToggleSwitch.glowHoverAlpha, 1e-6),
        );
      },
    );

    testWidgets('hover ignored while disabled (no knob colour change)', (
      tester,
    ) async {
      await pumpCtToggle(
        tester,
        const CtToggleSwitch(value: false, onChanged: null),
      );
      await hoverCtToggleSwitch(tester);
      final BoxDecoration deco = ctToggleKnobDecoration(tester);
      expect(deco.color, EditorialMonoclePalette.muted);
    });
  });
}
