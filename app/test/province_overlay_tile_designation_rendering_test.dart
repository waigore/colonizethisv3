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
    'ProvinceSeaZoneDetailOverlay Tile designation rendering (Refs #3617)',
    () {
      testWidgets('capital line renders between Terrain and Resource in fg '
          '(AC capital designation line)', (WidgetTester tester) async {
        final game = provinceOverlayWithFirstPlayerCapitalTile(
          provinceOverlayDesignationDemoGame,
          tileKey,
        );
        final expected = l10n.provinceOverlay_tileCapitalOf(
          provinceOverlayProvinceDisplayName(game, provinceId),
          game.players.first.displayName,
        );

        await pumpProvinceOverlayDesignation(
          tester,
          game: game,
          provinceId: provinceId,
          tileKey: tileKey,
        );

        final finder = find.text(expected);
        expect(finder, findsOneWidget);
        final Text row = tester.widget<Text>(finder);
        expect(row.style?.color, EditorialMonoclePalette.fg);

        final order = provinceOverlayTileTextDataInOrder(tester);
        final terrainIdx = order.indexWhere((d) => d.startsWith('Terrain: '));
        final designationIdx = order.indexOf(expected);
        final resourceIdx = order.indexWhere((d) => d.startsWith('Resource: '));
        expect(terrainIdx, greaterThanOrEqualTo(0));
        expect(resourceIdx, greaterThan(terrainIdx));
        expect(designationIdx, greaterThan(terrainIdx));
        expect(designationIdx, lessThan(resourceIdx));
      });

      for (final c
          in <
            ({
              String name,
              Game Function() game,
              void Function(WidgetTester, Game) assertUi,
            })
          >[
            (
              name:
                  'town line renders for the province town tile '
                  '(AC town designation line)',
              game: () {
                var g = provinceOverlayWithoutMatchingCapitals(
                  provinceOverlayDesignationDemoGame,
                );
                return provinceOverlayWithProvinceTownTile(g, provinceId, tileKey);
              },
              assertUi: (tester, g) {
                final expected = l10n.provinceOverlay_tileTownOf(
                  provinceOverlayProvinceDisplayName(g, provinceId),
                );
                final finder = find.text(expected);
                expect(finder, findsOneWidget);
                expect(
                  tester.widget<Text>(finder).style?.color,
                  EditorialMonoclePalette.fg,
                );
              },
            ),
            (
              name:
                  'ordinary land tile renders no designation line '
                  '(AC no designation)',
              game: () {
                var g = provinceOverlayWithoutMatchingCapitals(
                  provinceOverlayDesignationDemoGame,
                );
                return provinceOverlayWithProvinceTownTile(
                  g,
                  provinceId,
                  'oldWorld|__sentinel_town__|8881|8882',
                );
              },
              assertUi: (tester, _) {
                expect(find.textContaining('the capital of'), findsNothing);
                expect(find.textContaining('The town of'), findsNothing);
              },
            ),
          ]) {
        testWidgets(c.name, (WidgetTester tester) async {
          final game = c.game();
          await pumpProvinceOverlayDesignation(
            tester,
            game: game,
            provinceId: provinceId,
            tileKey: tileKey,
          );
          c.assertUi(tester, game);
        });
      }

      testWidgets('unrevealed selected tile renders no designation line '
          '(AC suppressed for unrevealed)', (WidgetTester tester) async {
        final game = provinceOverlayWithFirstPlayerCapitalTile(
          provinceOverlayDesignationDemoGame,
          tileKey,
        );
        final parts = tileKey.split('|');
        final tx = int.parse(parts[parts.length - 2]);
        final ty = int.parse(parts.last);
        final region = provinceOverlayRegionWith(
          visibilityForCell: (c) =>
              c.x == tx && c.y == ty ? TileVisibility.unrevealed : c.visibility,
        );

        await pumpProvinceOverlayDesignation(
          tester,
          game: game,
          provinceId: provinceId,
          tileKey: tileKey,
          region: region,
        );

        expect(find.textContaining('the capital of'), findsNothing);
        expect(find.text('Terrain: ???'), findsOneWidget);
      });
    },
  );
}
