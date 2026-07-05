import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgetbook.dart';

void main() {
  suppressLogsForTests();

  testWidgets('Widgetbook catalog app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const CtWidgetbookApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
