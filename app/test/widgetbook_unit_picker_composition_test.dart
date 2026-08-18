// Catalog pin: DLG20002 / DLG31003 picker folders stay registered (Refs #4385).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_test_harness.dart';

void main() {
  suppressLogsForTests();

  test(
    'Naval Mission Fleet Picker Dialog folder includes Default + Narrow',
    () {
      findWidgetbookUseCase(
        navalMissionDialogDirectories,
        folderName: 'Naval Mission Fleet Picker Dialog',
        useCaseName: 'Default — two fleets',
      );
      findWidgetbookUseCase(
        navalMissionDialogDirectories,
        folderName: 'Naval Mission Fleet Picker Dialog',
        useCaseName: 'Narrow — two fleets',
      );
    },
  );

  test(
    'Naval Mission Target Dialog folder includes capital-port extra line',
    () {
      findWidgetbookUseCase(
        navalMissionDialogDirectories,
        folderName: 'Naval Mission Target Dialog',
        useCaseName: 'Blockade — capital port extra line',
      );
    },
  );

  test('Overlay Army Move Picker Dialog folder includes Default + Narrow', () {
    findWidgetbookUseCase(
      navalMissionDialogDirectories,
      folderName: 'Overlay Army Move Picker Dialog',
      useCaseName: 'Default — two armies',
    );
    findWidgetbookUseCase(
      navalMissionDialogDirectories,
      folderName: 'Overlay Army Move Picker Dialog',
      useCaseName: 'Narrow — two armies',
    );
  });
}
