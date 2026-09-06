import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'call_to_arms_dialogue_overlay_dark_chrome_harness.dart';

/// Dark editorial-monocle chrome tests for CallToArmsDialogueOverlay per
/// `SPEC/ui/call-to-arms-dialogue-overlay.md` § Editorial-monocle chrome.
void main() {
  suppressLogsForTests();

  group('CallToArmsDialogueOverlay dark chrome (Refs #2867 R24)', () {
    testWidgets('title uses editorial-monocle accent + 0.05em letter-spacing',
        (WidgetTester tester) async {
      await pumpCallToArmsOverlay(tester);

      final BuildContext context = tester.element(find.byType(CtBrassDivider));
      final ThemeData theme = Theme.of(context);
      final double resolvedFontSize =
          theme.textTheme.titleMedium?.fontSize ?? 16.0;

      final Text titleText =
          tester.widget<Text>(find.text('Call to arms'));
      expect(titleText.style?.color, EditorialMonoclePalette.accent);
      expect(titleText.style?.fontWeight, FontWeight.w600);
      expect(
        titleText.style?.letterSpacing,
        closeTo(0.05 * resolvedFontSize, 1e-9),
      );
    });

    testWidgets('intro line uses muted color and italic style',
        (WidgetTester tester) async {
      await pumpCallToArmsOverlay(tester);

      final Text introText = tester.widget<Text>(find.text(
        'A treaty ally is at war. Join their war or refuse '
        '(the formal alliance ends, relations worsen).',
      ));
      expect(introText.style?.color, EditorialMonoclePalette.muted);
      expect(introText.style?.fontStyle, FontStyle.italic);
    });

    testWidgets('one CtBrassDivider sits between intro and call list',
        (WidgetTester tester) async {
      await pumpCallToArmsOverlay(tester);

      expect(find.byType(CtBrassDivider), findsOneWidget);

      final Finder introFinder = find.text(
        'A treaty ally is at war. Join their war or refuse '
        '(the formal alliance ends, relations worsen).',
      );
      final Finder listFinder = find.byType(ListView);
      final Finder dividerFinder = find.byType(CtBrassDivider);

      final Offset introCenter = tester.getCenter(introFinder);
      final Offset dividerCenter = tester.getCenter(dividerFinder);
      final Offset listCenter = tester.getCenter(listFinder);

      expect(dividerCenter.dy > introCenter.dy, isTrue);
      expect(listCenter.dy > dividerCenter.dy, isTrue);
    });

    testWidgets('scrim Material uses EditorialMonoclePalette.dialogScrim',
        (WidgetTester tester) async {
      await pumpCallToArmsOverlay(tester);

      final Iterable<Material> scrimMaterials = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.color == EditorialMonoclePalette.dialogScrim);
      expect(scrimMaterials, isNotEmpty);

      final Iterable<Material> blackScrim = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.color == Colors.black54);
      expect(blackScrim, isEmpty);
    });

    testWidgets(
      'Submit stays disabled until every pending call has a non-null decision',
      (WidgetTester tester) async {
        await pumpCallToArmsOverlay(tester);

        final Finder submitFinder = find.byKey(
          const ValueKey<String>('callToArmsSubmitButton'),
        );
        expect(submitFinder, findsOneWidget);

        CtNinePatchButton submitButton() =>
            tester.widget<CtNinePatchButton>(submitFinder);

        expect(submitButton().enabled, isFalse);

        await tester.tap(find.text('Join'));
        await tester.pump();
        expect(submitButton().enabled, isTrue);
      },
    );
  });
}
