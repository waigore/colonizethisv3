// Widget goldens for MAP10001 last-turn pulse (Refs #4486).
// SPEC/ui/map-widget.md § Last-turn spatial playback.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback.dart';
import 'package:colonizethis_app/features/game/flame/map_state/last_turn_playback_chrome.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show BaseLayerDisplayMode, CtMapVisibilityMode;
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook_host/catalogs/last_turn_pulse_story.dart';

import 'ct_region_map_test_support.dart';
import 'golden_capture_harness.dart';

Future<void> _pumpPulseGolden(
  WidgetTester tester, {
  required Key boundaryKey,
}) async {
  await tester.pumpWidget(
    ctRegionMapTestHarness(
      region: lastTurnPulseStoryRegion(),
      width: 128,
      height: 64,
      cellSizePx: 64,
      visibilityMode: CtMapVisibilityMode.full,
      showPoliticalOverlay: false,
      showProvinceOverlay: false,
      showProvinceNamesLayer: false,
      baseLayerDisplayMode: BaseLayerDisplayMode.terrainAndResources,
      lastTurnPulseTileKey: 'oldWorld|p1|0|0',
      useScaffold: false,
      repaintBoundaryKey: boundaryKey,
    ),
  );
  // Bounded pumps: continuous pulse tickers never settle (kLastTurnBeatDwellMs).
  final steps = kLastTurnBeatDwellMs ~/ 50;
  for (var i = 0; i < steps && i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await warmCtRegionMapCachesForTests();
  });

  testWidgets(
    'golden: last-turn pulse on MAP10001 (bounded pumps)',
    (tester) async {
      const boundaryKey = ValueKey<String>('last_turn_pulse_map_golden');
      await _pumpPulseGolden(tester, boundaryKey: boundaryKey);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/last_turn_pulse_map.png'),
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  testWidgets('golden: last-turn Skip chrome wide', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(420, 80),
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: ColoredBox(
        color: EditorialMonoclePalette.bgDeep,
        child: LastTurnPlaybackChrome(
          caption: 'Pulse province battle resolved!',
          skipLabel: 'Skip',
          onSkip: () {},
        ),
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/last_turn_playback_chrome.png'),
    );
  });

  testWidgets('golden: last-turn Skip chrome 320 dp', (tester) async {
    final GlobalKey boundaryKey = GlobalKey();
    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(320, 80),
      settle: false,
      includeLocalizations: true,
      scaffoldBackgroundColor:
          AppThemes.editorialMonocle.scaffoldBackgroundColor,
      child: ColoredBox(
        color: EditorialMonoclePalette.bgDeep,
        child: LastTurnPlaybackChrome(
          caption: 'Pulse province battle resolved!',
          skipLabel: 'Skip',
          onSkip: () {},
        ),
      ),
    );
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/last_turn_playback_chrome_320.png'),
    );
  });
}
