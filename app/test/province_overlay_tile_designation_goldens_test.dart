// Pins the Tile-section town / capital designation line for
// ProvinceSeaZoneDetailOverlay (Refs #3617).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Province overlay content `Tile` — Tile town / capital designation, and
// the matching § Acceptance criteria (Tile town designation line, Tile
// capital designation line, Tile ordinary land tile — no designation, Tile
// designation suppressed for sea / unrevealed, Tile designation uses
// localized keys).

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show sampleProvinceIdForOverlay, sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'province_overlay_tile_designation_test_support.dart';
  group('ProvinceSeaZoneDetailOverlay Tile designation goldens (Refs #3617)', () {
    for (final c
        in <
          ({
            String name,
            String key,
            String golden,
            Game Function() game,
            String Function(Game) expectedText,
          })
        >[
          (
            name:
                'capital designation line golden (AC capital designation line)',
            key: 'province_overlay_tile_capital_designation_golden',
            golden: 'goldens/province_overlay_tile_capital_designation.png',
            game: () => provinceOverlayWithFirstPlayerCapitalTile(
              provinceOverlayDesignationDemoGame,
              tileKey,
            ),
            expectedText: (g) => l10n.provinceOverlay_tileCapitalOf(
              provinceOverlayProvinceDisplayName(g, provinceId),
              g.players.first.displayName,
            ),
          ),
          (
            name: 'town designation line golden (AC town designation line)',
            key: 'province_overlay_tile_town_designation_golden',
            golden: 'goldens/province_overlay_tile_town_designation.png',
            game: () {
              var g = provinceOverlayWithoutMatchingCapitals(
                provinceOverlayDesignationDemoGame,
              );
              return provinceOverlayWithProvinceTownTile(g, provinceId, tileKey);
            },
            expectedText: (g) => l10n.provinceOverlay_tileTownOf(
              provinceOverlayProvinceDisplayName(g, provinceId),
            ),
          ),
        ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(600, 1000));
        final boundaryKey = ValueKey<String>(c.key);
        final game = c.game();

        await tester.pumpWidget(
          provinceOverlayDesignationGoldenHost(
            game: game,
            region: provinceOverlayDesignationDemoRegion,
            displayId: provinceId,
            selectedTileKey: tileKey,
            boundaryKey: boundaryKey,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(c.expectedText(game)), findsOneWidget);

        await expectLater(find.byKey(boundaryKey), matchesGoldenFile(c.golden));
      });
    }
  });
}
