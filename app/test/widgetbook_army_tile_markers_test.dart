// Widgetbook mount pin for MAP10001 army stack-marker stories (#4384).

import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/army_tile_marker_story.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_in_game_shell_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'Map Widget folder exposes army stack-marker variants (Refs #4384)',
    (WidgetTester tester) async {
      await expectWidgetbookStoriesMount(
        tester,
        mapWidgetDirectories,
        folder: 'Map Widget',
        useCases: ArmyTileMarkerStoryNames.all,
        widgetType: CtRegionMap,
        extra: const Duration(milliseconds: 200),
      );
    },
  );
}
