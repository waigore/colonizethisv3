// Pins Map tile hover readout Widgetbook stories (Refs #4406).
import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/catalog.dart';

import 'widgetbook_in_game_shell_chrome_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('fully visible owned land story mounts readout', (tester) async {
    await pumpWidgetbookStory(
      tester,
      mapTileHoverReadoutDirectories,
      folder: 'Map tile hover readout',
      useCase: 'Fully visible owned land',
    );
    expect(find.byKey(kMapTileHoverReadoutKey), findsOneWidget);
    expect(find.text('Place: Wessex'), findsOneWidget);
    expect(find.text('Owner: England'), findsOneWidget);
    expect(find.text('Sight: Fully visible'), findsOneWidget);
  });

  testWidgets('warp sea story includes passage line', (tester) async {
    await pumpWidgetbookStory(
      tester,
      mapTileHoverReadoutDirectories,
      folder: 'Map tile hover readout',
      useCase: 'Warp sea',
    );
    expect(
      find.text('This water is the passage to the other world'),
      findsOneWidget,
    );
  });

  testWidgets('320 dp story mounts without overflow', (tester) async {
    await pumpWidgetbookStory(
      tester,
      mapTileHoverReadoutDirectories,
      folder: 'Map tile hover readout',
      useCase: '320 dp narrow',
    );
    expect(tester.takeException(), isNull);
    expect(find.byKey(kMapTileHoverReadoutKey), findsOneWidget);
  });
}
