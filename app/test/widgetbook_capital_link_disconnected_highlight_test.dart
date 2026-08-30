// Widgetbook mount pin for MAP10001 capital-link hatch stories (#4370).

import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_in_game_shell_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'Map Widget folder exposes capital-link hatch variants (Refs #4370)',
    (WidgetTester tester) async {
      await expectWidgetbookStoriesMount(
        tester,
        mapWidgetDirectories,
        folder: 'Map Widget',
        useCases: const [
          'Capital-link hatch — mixed connected/disconnected',
          'Capital-link hatch — highlight off',
          'Capital-link hatch — fogged disconnected',
          'Capital-link hatch — narrow (320 dp)',
        ],
        widgetType: CtRegionMap,
        extra: const Duration(milliseconds: 200),
      );
    },
  );
}
