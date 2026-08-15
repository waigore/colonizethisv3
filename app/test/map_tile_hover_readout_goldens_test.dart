// Widget goldens for MAP10001 owner/sight hover readout (#4406).
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout.dart';
import 'package:colonizethis_app/features/game/flame/controls/map_tile_hover_readout_copy.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'widget_test_pumps.dart';

Future<void> _pumpReadoutGolden(
  WidgetTester tester, {
  required GlobalKey boundaryKey,
  required MapTileHoverReadoutCopy copy,
  Size physicalSize = const Size(280, 140),
}) async {
  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: physicalSize,
    includeLocalizations: true,
    scaffoldBackgroundColor: AppThemes.editorialMonocle.scaffoldBackgroundColor,
    center: false,
    child: ColoredBox(
      color: EditorialMonoclePalette.bgDeep,
      child: MapTileHoverReadout(copy: copy),
    ),
  );
  await pumpSettleCapped(tester);
}

void main() {
  suppressLogsForTests();

  testWidgets('golden: hover readout fully visible owned', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpReadoutGolden(
      tester,
      boundaryKey: boundaryKey,
      copy: const MapTileHoverReadoutCopy(
        placeLine: 'Place: Wessex',
        identityLine: 'Owner: England',
        sightLine: 'Sight: Fully visible',
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/map_tile_hover_readout_visible_owned.png'),
    );
  });

  testWidgets('golden: hover readout fogged rival', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpReadoutGolden(
      tester,
      boundaryKey: boundaryKey,
      copy: const MapTileHoverReadoutCopy(
        placeLine: 'Place: Normandy',
        identityLine: 'Owner: France',
        sightLine: 'Sight: Fogged — terrain only',
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/map_tile_hover_readout_fogged.png'),
    );
  });

  testWidgets('golden: hover readout unrevealed', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpReadoutGolden(
      tester,
      boundaryKey: boundaryKey,
      copy: const MapTileHoverReadoutCopy(
        placeLine: 'Place: Virginia',
        identityLine: 'Owner: Spain',
        sightLine: 'Sight: Unknown — no intel yet',
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/map_tile_hover_readout_unrevealed.png'),
    );
  });

  testWidgets('golden: hover readout warp sea', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpReadoutGolden(
      tester,
      boundaryKey: boundaryKey,
      copy: const MapTileHoverReadoutCopy(
        placeLine: 'Place: Azores Passage',
        identityLine: 'Sea zone',
        sightLine: 'Sight: Fully visible',
        warpLine: 'This water is the passage to the other world',
      ),
      physicalSize: const Size(280, 180),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/map_tile_hover_readout_warp_sea.png'),
    );
  });

  testWidgets('golden: hover readout 320 dp', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await _pumpReadoutGolden(
      tester,
      boundaryKey: boundaryKey,
      copy: const MapTileHoverReadoutCopy(
        placeLine: 'Place: Wessex',
        identityLine: 'Owner: England',
        sightLine: 'Sight: Fully visible',
      ),
      physicalSize: const Size(320, 160),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/map_tile_hover_readout_320dp.png'),
    );
  });
}
