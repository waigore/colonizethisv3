// Widgetbook mount pin for MAP10001 last-turn pulse stories (#4486).

import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_in_game_shell_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'Map Widget folder exposes last-turn pulse variants (Refs #4486)',
    (WidgetTester tester) async {
      await expectWidgetbookStoriesMount(
        tester,
        mapWidgetDirectories,
        folder: 'Map Widget',
        useCases: const ['Last-turn pulse', 'Last-turn pulse (320 dp)'],
        widgetType: CtRegionMap,
        extra: const Duration(milliseconds: 200),
      );
    },
  );
}
