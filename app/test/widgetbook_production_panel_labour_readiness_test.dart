// Widget test pin for Production Panel labour-readiness Widgetbook use cases.
// SPEC/ui/production-panel.md § Widgetbook (Refs #4237).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:widgetbook_host/catalogs/catalog.dart';
import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  const folderName = 'Production Panel';
  const labourStories = <String>[
    'Labour food shortfall',
    'Labour luxury shortfall',
    'Labour zero',
    'Labour food shortfall (mobile)',
  ];

  group('Production Panel labour readiness Widgetbook stories (Refs #4237)', () {
    for (final useCaseName in labourStories) {
      testWidgets(
        '$useCaseName is wired into productionPanelDirectories',
        (WidgetTester tester) async {
          final useCase = findWidgetbookUseCase(
            productionPanelDirectories,
            folderName: folderName,
            useCaseName: useCaseName,
          );
          expect(useCase.builder, isNotNull);
        },
      );
    }

    testWidgets(
      'Labour food shortfall builder pumps and shows food reason',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          productionPanelDirectories,
          folderName: folderName,
          useCaseName: 'Labour food shortfall',
        );
        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 600),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Some workers are not working — food is short.'),
          findsOneWidget,
        );
        expect(find.text('Labour details'), findsOneWidget);
      },
    );

    testWidgets(
      'Labour food shortfall (mobile) pumps at 360 × 640 dp',
      (WidgetTester tester) async {
        final useCase = findWidgetbookUseCase(
          productionPanelDirectories,
          folderName: folderName,
          useCaseName: 'Labour food shortfall (mobile)',
        );
        await pumpWidgetbookUseCaseAtSize(tester, useCase);
        await tester.pumpAndSettle();

        expect(
          find.text('Some workers are not working — food is short.'),
          findsOneWidget,
        );
      },
    );
  });
}
