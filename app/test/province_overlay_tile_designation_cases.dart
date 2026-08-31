// Scenario tables for province_overlay_tile_designation_test.dart (Refs #4680).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_tile_designation_test_support.dart';

typedef TileDesignationLogicCase = ({
  String name,
  Game Function() game,
  String? Function(Game) want,
  Matcher? also,
});

typedef TileDesignationRenderingCase = ({
  String name,
  Game Function() game,
  void Function(WidgetTester, Game) assertUi,
});

typedef TileDesignationGoldenCase = ({
  String name,
  String key,
  String golden,
  Game Function() game,
  String Function(Game) expectedText,
});

List<TileDesignationLogicCase> provinceOverlayTileDesignationLogicCases({
  required AppLocalizations l10n,
  required String provinceId,
  required String tileKey,
}) =>
    [
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
    ];

List<TileDesignationRenderingCase>
provinceOverlayTileDesignationRenderingCases({
  required AppLocalizations l10n,
  required String provinceId,
  required String tileKey,
}) =>
    [
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
    ];

List<TileDesignationGoldenCase> provinceOverlayTileDesignationGoldenCases({
  required AppLocalizations l10n,
  required String provinceId,
  required String tileKey,
}) =>
    [
      (
        name: 'capital designation line golden (AC capital designation line)',
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
    ];
