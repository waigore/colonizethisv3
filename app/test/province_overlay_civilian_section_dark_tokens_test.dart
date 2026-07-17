// Pins dark editorial-monocle Civilian section body tokens for
// ProvinceSeaZoneDetailOverlay (S8). Positive + Material-default regression
// guards share one pump per scenario (Refs #4021 densify).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Civilian section body tokens.

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/editorial_monocle_dark_token_assertions.dart';
import 'support/province_overlay_dark_token_scenarios.dart';
import 'support/province_overlay_test_harness.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pCivDarkTokens';
const _humanPlayerId = 'gp1';
const _foreignPlayerId = 'gp2';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => overlayDarkTokenTileKey(
  regionId: _regionId,
  localProvinceId: _localProvinceId,
  x: x,
  y: y,
);

Finder _ownExplorerRowFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').startsWith('Explorer:') &&
        !(w.data ?? '').contains('—'),
  );
}

Finder _foreignMerchantRowFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains(kUnitTypeMerchant) &&
        (w.data ?? '').contains('—'),
  );
}

({Game game, RegionMapViewData region, String tk}) _ownCivilianScenario() {
  final tk = _tileKey(0, 0);
  final ownUnit = Unit(
    id: 'c-own',
    type: kUnitTypeExplorer,
    ownerId: _humanPlayerId,
    locationProvinceId: _fullProvinceId,
    tileKey: tk,
  );
  final game = gameWithCivilianUnitsForOverlay(
    gameId: 'civilian_dark_tokens_test',
    regionId: _regionId,
    fullProvinceId: _fullProvinceId,
    displayName: 'CivDarkTokens',
    humanPlayerId: _humanPlayerId,
    foreignPlayerId: _foreignPlayerId,
    tileKeys: [tk],
    units: [ownUnit],
  );
  final region = regionMapWithLandCells(
    regionId: _regionId,
    localProvinceId: _localProvinceId,
    coords: [(x: 0, y: 0)],
    width: 1,
    height: 1,
    greatPowerFactionIds: const {_humanPlayerId, _foreignPlayerId},
  );
  return (game: game, region: region, tk: tk);
}

({Game game, RegionMapViewData region, String tk}) _foreignCivilianScenario() {
  final tk = _tileKey(0, 0);
  final foreignUnit = Unit(
    id: 'c-foreign',
    type: kUnitTypeMerchant,
    ownerId: _foreignPlayerId,
    locationProvinceId: _fullProvinceId,
    tileKey: tk,
  );
  final game = gameWithCivilianUnitsForOverlay(
    gameId: 'civilian_dark_tokens_test',
    regionId: _regionId,
    fullProvinceId: _fullProvinceId,
    displayName: 'CivDarkTokens',
    humanPlayerId: _humanPlayerId,
    foreignPlayerId: _foreignPlayerId,
    tileKeys: [tk],
    units: [foreignUnit],
  );
  final region = regionMapWithLandCells(
    regionId: _regionId,
    localProvinceId: _localProvinceId,
    coords: [(x: 0, y: 0)],
    width: 1,
    height: 1,
    greatPowerFactionIds: const {_humanPlayerId, _foreignPlayerId},
  );
  return (game: game, region: region, tk: tk);
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Civilian section '
    'body (SPEC § Dark-theme Civilian section body tokens, S8)',
    () {
      testWidgets(
        'own civilian row resolves to fg (with Material-default guards)',
        (WidgetTester tester) async {
          final scenario = _ownCivilianScenario();
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: scenario.game,
              region: scenario.region,
              displayId: _fullProvinceId,
              selectedTileKey: scenario.tk,
              humanPlayerId: _humanPlayerId,
              playerView: omniscientPlayerViewForTiles(
                humanPlayerId: _humanPlayerId,
                keys: [scenario.tk],
              ),
              shellWidth: 800,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _ownExplorerRowFinder();
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason: 'Own Explorer must render Explorer: status row.',
          );
          expectFgSingleSource(
            tester.widget<Text>(finder.first).style?.color,
            'Own civilian row',
          );
        },
      );

      testWidgets(
        'foreign civilian row resolves to muted '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final scenario = _foreignCivilianScenario();
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: scenario.game,
              region: scenario.region,
              displayId: _fullProvinceId,
              selectedTileKey: scenario.tk,
              humanPlayerId: _humanPlayerId,
              playerView: omniscientPlayerViewForTiles(
                humanPlayerId: _humanPlayerId,
                keys: [scenario.tk],
              ),
              shellWidth: 800,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _foreignMerchantRowFinder();
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason: 'Foreign Merchant must render owner — Merchant row.',
          );
          final onSurface =
              Theme.of(tester.element(finder.first)).colorScheme.onSurface;
          expectMutedSingleSource(
            tester.widget<Text>(finder.first).style?.color,
            onSurface,
            'Foreign civilian row',
          );
        },
      );
    },
  );
}
