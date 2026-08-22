// Widgetbook pin for Production Available → Trade. Refs #4581.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Tap Available opens Trade is registered in Production Panel catalog', () {
    findWidgetbookUseCase(
      productionPanelDirectories,
      folderName: 'Production Panel',
      useCaseName: 'Tap Available opens Trade',
    );
  });
}
