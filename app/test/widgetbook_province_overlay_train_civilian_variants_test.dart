// Widget test pin for Province Overlay Train {type} variants (Refs #4752).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();

  const folderName = 'Province Overlay';

  group('Province Overlay Train Explorer Widgetbook variants (Refs #4752)', () {
    for (final useCaseName in [
      'Standalone — Train Explorer missing-unit',
      'Standalone — Train Explorer units exist',
      'Standalone — Train Explorer Consulate omit',
      'Standalone — Train Explorer 320 dp',
    ]) {
      testWidgets('$useCaseName is wired into provinceOverlayDirectories', (
        tester,
      ) async {
        final useCase = findWidgetbookUseCase(
          provinceOverlayDirectories,
          folderName: folderName,
          useCaseName: useCaseName,
        );
        expect(useCase.builder, isNotNull);
      });
    }
  });
}
