// Pump/find helpers for economic-section dark-token pins (Refs #4305, #2865 S6).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_dark_token_scenarios.dart';
import 'province_overlay_test_harness.dart';

const kEconDarkTokensRegionId = 'oldWorld';
const kEconDarkTokensLocalProvinceId = 'pEconDarkTokens';
const kEconDarkTokensHumanPlayerId = 'gp1';

String get kEconDarkTokensFullProvinceId =>
    '$kEconDarkTokensRegionId|$kEconDarkTokensLocalProvinceId';

String econDarkTokenTileKey(int x, int y) => overlayDarkTokenTileKey(
      regionId: kEconDarkTokensRegionId,
      localProvinceId: kEconDarkTokensLocalProvinceId,
      x: x,
      y: y,
    );

Finder econDarkImprovedRowLabelFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains('Grain') &&
        (w.data ?? '').contains('with ') &&
        !(w.data ?? '').contains('(improvable)'),
  );
}

Finder econDarkImprovableRowLabelFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains('Grain') &&
        (w.data ?? '').contains('(improvable)'),
  );
}

Future<void> pumpEconDarkTokenOverlay(
  WidgetTester tester, {
  required String tileKey,
  required Map<String, int> improvementByTile,
}) async {
  final game = gameWithGrainTilesForOverlay(
    gameId: 'economic_dark_tokens_test',
    regionId: kEconDarkTokensRegionId,
    fullProvinceId: kEconDarkTokensFullProvinceId,
    displayName: 'EconDarkTokens',
    humanPlayerId: kEconDarkTokensHumanPlayerId,
    tileKeys: [tileKey],
    improvementByTile: improvementByTile,
    provinceOwnerId: kEconDarkTokensHumanPlayerId,
  );
  final region = regionMapWithLandCells(
    regionId: kEconDarkTokensRegionId,
    localProvinceId: kEconDarkTokensLocalProvinceId,
    coords: [(x: 0, y: 0)],
    width: 1,
    height: 1,
    greatPowerFactionIds: const {kEconDarkTokensHumanPlayerId},
    resourceId: 'grain',
  );

  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      region: region,
      displayId: kEconDarkTokensFullProvinceId,
      selectedTileKey: tileKey,
      humanPlayerId: kEconDarkTokensHumanPlayerId,
      playerView: omniscientPlayerViewForTiles(
        humanPlayerId: kEconDarkTokensHumanPlayerId,
        keys: [tileKey],
      ),
      shellWidth: 800,
    ),
  );
  await tester.pumpAndSettle();
}
