import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpLabel(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(8), child: child)),
      ),
    );
    await tester.pump();
  }

  group('CtSectionLabel visual contract (R9)', () {
    testWidgets('renders text as upper-case with --muted color', (tester) async {
      await pumpLabel(tester, const CtSectionLabel('Production'));
      final Text text = tester.widget<Text>(find.byType(Text));
      expect(text.data, 'PRODUCTION');
      expect(text.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets('applies small-caps font feature for canonical small-caps glyphs', (
      tester,
    ) async {
      await pumpLabel(tester, const CtSectionLabel('Resources'));
      final Text text = tester.widget<Text>(find.byType(Text));
      final List<FontFeature> features =
          text.style?.fontFeatures ?? const <FontFeature>[];
      expect(
        features.any((f) => f.feature == 'smcp'),
        isTrue,
        reason: 'must enable OpenType small-caps via FontFeature.enable(smcp)',
      );
    });

    testWidgets('has a 1px accent-dim bottom border under the text', (
      tester,
    ) async {
      await pumpLabel(tester, const CtSectionLabel('Border test'));
      final DecoratedBox decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CtSectionLabel),
          matching: find.byType(DecoratedBox),
        ),
      );
      final BoxDecoration deco = decorated.decoration as BoxDecoration;
      final Border? border = deco.border as Border?;
      expect(border, isNotNull);
      expect(border!.bottom.color, EditorialMonoclePalette.accentDim);
      expect(border.bottom.width, 1.0);
      expect(border.top.style, BorderStyle.none);
      expect(border.left.style, BorderStyle.none);
      expect(border.right.style, BorderStyle.none);
    });

    testWidgets('respects optional outer padding prop', (tester) async {
      await pumpLabel(
        tester,
        const CtSectionLabel(
          'Diplomacy',
          padding: EdgeInsets.only(left: 12),
        ),
      );
      final Padding outer = tester
          .widgetList<Padding>(
            find.descendant(
              of: find.byType(CtSectionLabel),
              matching: find.byType(Padding),
            ),
          )
          .first;
      expect(outer.padding, const EdgeInsets.only(left: 12));
    });

    testWidgets('empty text still renders without exception (negative path)', (
      tester,
    ) async {
      await pumpLabel(tester, const CtSectionLabel(''));
      expect(tester.takeException(), isNull);
      expect(find.text(''), findsOneWidget);
    });
  });
}
