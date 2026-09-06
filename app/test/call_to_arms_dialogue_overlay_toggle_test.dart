// CtToggleSwitch pins for CallToArmsDialogueOverlay (Refs #2867 R24).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_toggle_switch.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'call_to_arms_dialogue_overlay_dark_chrome_harness.dart';

void main() {
  suppressLogsForTests();

  group('CallToArmsDialogueOverlay R24 CtToggleSwitch (#2867 R24)', () {
    testWidgets(
      'each row exposes Join + Refuse CtToggleSwitch controls and accent label',
      (WidgetTester tester) async {
        await pumpCallToArmsOverlay(tester);

        expect(callToArmsJoinToggle(0), findsOneWidget);
        expect(callToArmsRefuseToggle(0), findsOneWidget);

        final CtToggleSwitch join =
            tester.widget<CtToggleSwitch>(callToArmsJoinToggle(0));
        final CtToggleSwitch refuse =
            tester.widget<CtToggleSwitch>(callToArmsRefuseToggle(0));
        expect(join.onGlowColor, EditorialMonoclePalette.success);
        expect(refuse.onGlowColor, EditorialMonoclePalette.danger);

        final Text prompt = tester.widget<Text>(
          find.byKey(const ValueKey<String>('callToArmsPrompt')),
        );
        final InlineSpan? span = prompt.textSpan;
        expect(span, isA<TextSpan>());
        final List<InlineSpan> children =
            (span! as TextSpan).children ?? const <InlineSpan>[];
        final Iterable<TextSpan> accentSpans = children
            .whereType<TextSpan>()
            .where((s) => s.text == 'Portugal');
        expect(accentSpans, isNotEmpty);
        expect(accentSpans.first.style?.color, EditorialMonoclePalette.accent);
      },
    );

    testWidgets(
      'tapping active Join reverts row to undecided and re-disables Submit',
      (WidgetTester tester) async {
        await pumpCallToArmsOverlay(tester);

        CtNinePatchButton submitButton() => tester.widget<CtNinePatchButton>(
              find.byKey(const ValueKey<String>('callToArmsSubmitButton')),
            );
        CtToggleSwitch joinSwitch() =>
            tester.widget<CtToggleSwitch>(callToArmsJoinToggle(0));

        expect(joinSwitch().value, isFalse);
        expect(submitButton().enabled, isFalse);

        await tester.tap(callToArmsJoinToggle(0));
        await tester.pump();
        expect(joinSwitch().value, isTrue);
        expect(submitButton().enabled, isTrue);

        await tester.tap(callToArmsJoinToggle(0));
        await tester.pump();
        expect(joinSwitch().value, isFalse);
        expect(submitButton().enabled, isFalse);
      },
    );

    testWidgets('Join and Refuse are mutually exclusive within a row',
        (WidgetTester tester) async {
      await pumpCallToArmsOverlay(tester);

      await tester.tap(find.text('Join'));
      await tester.pump();
      expect(tester.widget<CtToggleSwitch>(callToArmsJoinToggle(0)).value, isTrue);
      expect(
        tester.widget<CtToggleSwitch>(callToArmsRefuseToggle(0)).value,
        isFalse,
      );

      await tester.tap(find.text('Refuse'));
      await tester.pump();
      expect(
        tester.widget<CtToggleSwitch>(callToArmsJoinToggle(0)).value,
        isFalse,
      );
      expect(
        tester.widget<CtToggleSwitch>(callToArmsRefuseToggle(0)).value,
        isTrue,
      );
    });
  });
}
