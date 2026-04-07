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
}
