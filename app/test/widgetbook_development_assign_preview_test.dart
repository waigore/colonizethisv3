// Widgetbook pins for Development Assign preview (Refs #4472).
// SPEC/ui/development-panel.md § Widgetbook.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  const folderName = 'Development Panel';

  testWidgets(
    'Assign preview enabled is wired into developmentScreenDirectories',
    (tester) async {
      final useCase = findWidgetbookUseCase(
        developmentScreenDirectories,
        folderName: folderName,
        useCaseName: 'Assign preview enabled',
      );
      expect(useCase.builder, isNotNull);
      findWidgetbookUseCase(
        developmentScreenDirectories,
        folderName: folderName,
        useCaseName: 'Assign preview enabled (mobile)',
      );
    },
  );
}
