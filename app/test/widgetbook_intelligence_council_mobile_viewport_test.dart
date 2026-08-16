// Widget test pin for Intelligence Council → Mobile viewport.
// SPEC/ui/intelligence-council.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Intelligence Council Widgetbook mobile-viewport story', () {
    testWidgets('Mobile viewport is wired under Intelligence Council', (
      WidgetTester tester,
    ) async {
      final useCase = findWidgetbookUseCase(
        intelligenceCouncilDirectories,
        folderName: 'Intelligence Council',
        useCaseName: 'Mobile viewport',
      );
      expect(useCase.builder, isNotNull);
    });

    testWidgets(
      'Mobile viewport builder pumps at 360 × 640 dp without exceptions',
      (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(360, 640));

        final useCase = findWidgetbookUseCase(
          intelligenceCouncilDirectories,
          folderName: 'Intelligence Council',
          useCaseName: 'Mobile viewport',
        );

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(360, 640)),
            child: Builder(builder: (BuildContext ctx) => useCase.builder(ctx)),
          ),
        );
        await tester.pumpAndSettle(const Duration(milliseconds: 200));

        expect(
          tester.takeException(),
          isNull,
          reason:
              'Mobile-viewport story must pump without exceptions per '
              'SPEC/ui/intelligence-council.md.',
        );
      },
    );
  });
}
