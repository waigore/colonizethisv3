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

void main() {
  suppressLogsForTests();

  final l10n = lookupAppLocalizations(const Locale('en'));
  final provinceId = sampleProvinceIdForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;

  group('provinceOverlayTileDesignationLine (Refs #3617 — logic)', () {
    for (final c
        in <
          ({
            String name,
            Game Function() game,
            String? Function(Game) want,
            Matcher? also,
          })
        >[
          (
            name: 'capital tile yields the localized capital line (AC capital)',
            game: () => provinceOverlayWithFirstPlayerCapitalTile(
              provinceOverlayDesignationDemoGame,
              tileKey,
            ),
            want: (g) => l10n.provinceOverlay_tileCapitalOf(
              provinceOverlayProvinceDisplayName(g, provinceId),
              g.players.first.displayName,
            ),
            also: null,
          ),
          (
            name:
                'capital takes priority when the tile is also the province town '
                '(AC capital-only when both apply)',
            game: () {
              var g = provinceOverlayWithFirstPlayerCapitalTile(
                provinceOverlayDesignationDemoGame,
                tileKey,
              );
              return provinceOverlayWithProvinceTownTile(g, provinceId, tileKey);
            },
            want: (g) => l10n.provinceOverlay_tileCapitalOf(
              provinceOverlayProvinceDisplayName(g, provinceId),
              g.players.first.displayName,
            ),
            also: isNot(contains('The town of')),
          ),
          (
            name:
                'town tile (not a capital) yields the localized town line (AC town)',
            game: () {
              var g = provinceOverlayWithoutMatchingCapitals(
                provinceOverlayDesignationDemoGame,
              );
              return provinceOverlayWithProvinceTownTile(g, provinceId, tileKey);
            },
            want: (g) => l10n.provinceOverlay_tileTownOf(
              provinceOverlayProvinceDisplayName(g, provinceId),
            ),
            also: null,
          ),
          (
            name:
                'ordinary land tile (neither town nor capital) yields null '
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
            want: (_) => null,
            also: null,
          ),
        ]) {
      test(c.name, () {
        final game = c.game();
        final line = provinceOverlayTileDesignationLine(
          l10n: l10n,
          game: game,
          provinceId: provinceId,
          selectedTileKey: tileKey,
        );
        expect(line, c.want(game));
        if (c.also != null && line != null) {
          expect(line, c.also);
        }
      });
    }

    test('minor-nation capital tile resolves the minor display name', () {
      final base = provinceOverlayDesignationDemoGame;
      if (base.minorNations.isEmpty) {
        return;
      }
      final cleared = provinceOverlayWithoutMatchingCapitals(base);
      final cap = provinceOverlayCapitalTileFromKey(tileKey);
      final minors = <MinorNation>[
        cleared.minorNations.first.copyWith(capitalTile: cap),
        ...cleared.minorNations.skip(1),
      ];
      final game = cleared.copyWith(minorNations: minors);
      final provinceName = provinceOverlayProvinceDisplayName(game, provinceId);
      final expectedName =
          game.minorNations.first.displayName ?? game.minorNations.first.id;

      final line = provinceOverlayTileDesignationLine(
        l10n: l10n,
        game: game,
        provinceId: provinceId,
        selectedTileKey: tileKey,
      );

      expect(
        line,
        l10n.provinceOverlay_tileCapitalOf(provinceName, expectedName),
      );
    });
  });

}
