// Tests for CtTabStrip. lib/widgets/ct_tab_strip.dart.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_tab_strip.dart';

void main() {
  suppressLogsForTests();

  testWidgets('CtTabStrip builds and shows first tab label and content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: CtTabStrip(
              tabLabels: const ['A', 'B', 'C'],
              tabViews: const [
                Text('Content A'),
                Text('Content B'),
                Text('Content C'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('C'), findsOneWidget);
    expect(find.text('Content A'), findsOneWidget);
  });

  testWidgets('CtTabStrip tap switches to second tab content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: CtTabStrip(
              tabLabels: const ['First', 'Second'],
              tabViews: const [
                Text('View 1'),
                Text('View 2'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('View 1'), findsOneWidget);

    await tester.tap(find.text('Second'));
    await tester.pump();

    expect(find.text('View 2'), findsOneWidget);
  });

  testWidgets('CtTabStrip applies contentPadding', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 200,
            child: CtTabStrip(
              tabLabels: const ['X'],
              tabViews: const [Text('Padded')],
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Padded'), findsOneWidget);
  });
}
