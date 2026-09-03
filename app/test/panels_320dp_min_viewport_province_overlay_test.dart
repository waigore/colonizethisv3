// Pin the 320 dp minimum-viewport contract for
// ProvinceSeaZoneDetailOverlay — sibling to
// `panels_320dp_min_viewport_test.dart`.
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 (Minimum-viewport pin).
// Refs #2870 S10.
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'panels_320dp_min_viewport_test_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — ProvinceSeaZoneDetailOverlay '
      '@ 320 dp (Refs #2870 S10)', () {
    // Constructed lazily inside each test so the demo-data getters resolve
    // against the running test binding (matches game_map_narrow_detail_
    // overlay_test.dart).
    Widget buildOverlay({double? heightPx}) {
      final overlay = ProvinceSeaZoneDetailOverlay(
        game: demoGameForOverlay,
        region: demoRegionForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        humanPlayerId: demoGameForOverlay.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
      );
      // Mirrors GameMapNarrowDetailOverlaySlot's bottom-anchored
      // `SizedBox(height: viewport.height * 0.33)` host so the overlay
      // sees the same ~33 vh ceiling it would in the running game per
      // SPEC/ui/in-game-shell-narrow.md § Province/sea zone detail overlay.
      if (heightPx != null) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(height: heightPx, child: overlay),
        );
      }
      return overlay;
    }

    testWidgets(
      'AC (positive) ProvinceSeaZoneDetailOverlay @ 320×640 hosted in '
      'bottom-anchored ~33 vh slot: no RenderFlex overflow exception, '
      'Province header + Tile tab label render',
      (WidgetTester tester) async {
        await pumpPanelsNarrow(
          tester,
          buildOverlay(heightPx: kPanelsMinViewport.height * 0.33),
          size: kPanelsMinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7 + § 4 (Province / sea '
              'detail narrow row): ProvinceSeaZoneDetailOverlay must not '
              'emit a RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp) when hosted inside the bottom-anchored ~33 vh '
              'slot used by GameMapNarrowDetailOverlaySlot. The narrow '
              'CtTabStrip body (Tile / Political / Economic / Military / '
              'Civilian / Naval) must lay out within the 320 dp column '
              'without horizontal overflow.',
        );
        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
        expect(find.text('Province'), findsOneWidget);
        // Narrow body renders a CtTabStrip with six tabs; the first
        // ("Tile") is selected by default per SPEC § Tabs.
        expect(find.text('Tile'), findsOneWidget);
      },
    );

    testWidgets(
      'Negative control: ProvinceSeaZoneDetailOverlay @ 1024×768 (wide '
      'side-panel host) pumps without exception',
      (WidgetTester tester) async {
        // Wide layout: side-panel host gives the overlay full available
        // height; no bottom-sheet 33 vh clamp.
        await pumpPanelsNarrow(
          tester,
          buildOverlay(),
          size: kPanelsWideRegressionViewport,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
        expect(find.text('Province'), findsOneWidget);
      },
    );
  });
}
