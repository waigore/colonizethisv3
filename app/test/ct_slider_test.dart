import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  testWidgets('CtSlider invokes onDragStart and onDragEnd around horizontal drag', (
    WidgetTester tester,
  ) async {
    var dragStarts = 0;
    var dragEnds = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: CtSlider(
                value: 0.5,
                min: 0,
                max: 1,
                divisions: 0,
                onChanged: (_) {},
                onDragStart: () => dragStarts++,
                onDragEnd: () => dragEnds++,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byType(CtSlider),
      const Offset(80, 0),
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await tester.pump();

    expect(dragStarts, 1);
    expect(dragEnds, 1);
  });

  testWidgets(
    'AC CtSlider (Refs #2859 S7): dark surface track + round accent thumb',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: CtSlider(
                  value: 0.5,
                  min: 0,
                  max: 1,
                  divisions: 0,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      final Finder trackFinder = find.descendant(
        of: find.byType(CtSlider),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color ==
                  EditorialMonoclePalette.surface,
        ),
      );
      expect(trackFinder, findsOneWidget);

      final BoxDecoration trackDecoration =
          tester.widget<Container>(trackFinder).decoration! as BoxDecoration;
      expect(
        trackDecoration.border,
        isA<Border>().having(
          (Border b) => b.top.color,
          'accent-dim border',
          EditorialMonoclePalette.accentDim,
        ),
      );

      final Finder thumbFinder = find.descendant(
        of: find.byType(CtSlider),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle &&
              (w.decoration! as BoxDecoration).color ==
                  EditorialMonoclePalette.accent,
        ),
      );
      expect(thumbFinder, findsOneWidget);

      final BoxDecoration thumbDecoration =
          tester.widget<Container>(thumbFinder).decoration! as BoxDecoration;
      expect(
        thumbDecoration.border,
        isA<Border>().having(
          (Border b) => b.top.color,
          'accent-bright thumb border',
          EditorialMonoclePalette.accentBright,
        ),
      );
    },
  );
}
