// Widget test pin for Production Panel labour cost/upkeep Widgetbook use cases.
// SPEC/ui/production-panel.md § Widgetbook (Refs #4432).

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
    'Labour cost gist',
    'Labour locked tier',
    'Labour cost gist (mobile)',
  ];

  group(
    'Production Panel labour cost gist Widgetbook stories (Refs #4432)',
    () {
      for (final useCaseName in labourStories) {
        testWidgets('$useCaseName is wired into productionPanelDirectories', (
          WidgetTester tester,
        ) async {
          final useCase = findWidgetbookUseCase(
            productionPanelDirectories,
            folderName: folderName,
            useCaseName: useCaseName,
          );
          expect(useCase.builder, isNotNull);
        });
      }

      testWidgets('Labour cost gist builder pumps and shows fabric cost gist', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          productionPanelDirectories,
          folderName: folderName,
          useCaseName: 'Labour cost gist',
        );
        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 900),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('production_labour_cost_peasants'),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(find.textContaining('(unlocked)'), findsNothing);
      });

      testWidgets('Labour locked tier pumps Requires: without raw tech ids', (
        WidgetTester tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          productionPanelDirectories,
          folderName: folderName,
          useCaseName: 'Labour locked tier',
        );
        await pumpWidgetbookUseCaseAtSize(
          tester,
          useCase,
          size: const Size(800, 900),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('production_labour_requires_apprentices'),
            skipOffstage: false,
          ),
          findsOneWidget,
        );
        expect(find.textContaining('apprentice_workers'), findsNothing);
      });
    },
  );
}
