// Widgetbook pin for Production labour-limited affordance focus. Refs #4780.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Tap affordance focuses Labour Controls is registered in Production Panel',
    () {
      findWidgetbookUseCase(
        productionPanelDirectories,
        folderName: 'Production Panel',
        useCaseName: 'Tap affordance focuses Labour Controls',
      );
      findWidgetbookUseCase(
        productionPanelDirectories,
        folderName: 'Production Panel',
        useCaseName: 'Tap affordance focuses Labour Controls (mobile)',
      );
    },
  );
}
