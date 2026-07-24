// Smoke tests for shared golden-capture harness (Refs #3952).

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_capture_harness.dart';

void main() {
  suppressLogsForTests();

  testWidgets('pumpGoldenHost mounts child under editorial-monocle boundary', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('golden_harness_smoke');
    const childKey = ValueKey<String>('golden_harness_smoke_child');
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(200, 100),
      child: const SizedBox(
        key: childKey,
        width: 80,
        height: 40,
        child: ColoredBox(color: Colors.red),
      ),
    );

    expect(find.byKey(boundaryKey), findsOneWidget);
    final ThemeData theme = Theme.of(tester.element(find.byKey(childKey)));
    expect(theme.colorScheme, AppThemes.editorialMonocle.colorScheme);
  });

  testWidgets('pumpForGolden bounded flush completes without settle', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('golden_harness_bounded');
    configureGoldenView(tester, physicalSize: const Size(120, 80));
    await tester.pumpWidget(
      wrapGoldenBoundary(
        boundaryKey: boundaryKey,
        child: const Text('bounded'),
      ),
    );
    await pumpForGolden(tester, settle: false);
    expect(find.text('bounded'), findsOneWidget);
  });
}
