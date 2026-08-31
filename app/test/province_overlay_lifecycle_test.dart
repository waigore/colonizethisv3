// Repeated mount/unmount + session-cache dispose guards for MAP20001 (Refs #4690 Slice C).

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay_chrome.dart'
    show ProvinceOverlayInteractiveReadyMarker;
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_sea_zone_overlay_detail_paths_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'ten MAP20001 mount/unmount cycles leave no stacked overlay roots (Refs #4690 AC6)',
    (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;
      final selection = firstRevealedLandOverlaySelection(
        game: game,
        region: region,
      );

      for (var cycle = 0; cycle < 10; cycle++) {
        await tester.pumpWidget(
          buildProvinceSeaZoneOverlayPathShell(
            game: game,
            region: region,
            displayId: selection.provinceId,
            humanPlayerId: game.players.first.id,
            selectedTileKey: selection.selectedTileKey,
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
        expect(find.byType(ProvinceOverlayInteractiveReadyMarker), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsNothing);
        expect(find.byType(ProvinceOverlayInteractiveReadyMarker), findsNothing);
      }
    },
  );

  testWidgets(
    'ProvinceOverlayInteractiveReadyMarker fires once per overlay mount (Refs #4690)',
    (WidgetTester tester) async {
      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;
      final selection = firstRevealedLandOverlaySelection(
        game: game,
        region: region,
      );

      await tester.pumpWidget(
        buildProvinceSeaZoneOverlayPathShell(
          game: game,
          region: region,
          displayId: selection.provinceId,
          humanPlayerId: game.players.first.id,
          selectedTileKey: selection.selectedTileKey,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(ProvinceOverlayInteractiveReadyMarker), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(find.byType(ProvinceOverlayInteractiveReadyMarker), findsNothing);
    },
  );
}
