// Log suppression first (SPEC/program/test-logging.md); then Flutter test API.
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/app.dart';

void main() {
  // Suppress logs for test run.
  suppressLogsForTests();

  testWidgets('App shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();
    expect(find.text('Colonize This'), findsOneWidget);
  });
}
