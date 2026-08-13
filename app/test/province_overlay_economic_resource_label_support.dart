// Economic ResourceLabelInline dark-token scenario helpers (Refs #4352).

import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_dark_token_scenarios.dart';
import 'province_overlay_test_harness.dart';

const economicResourceLabelRegionId = 'oldWorld';
const economicResourceLabelLocalProvinceId = 'pEconResLabelTest';
const economicResourceLabelHumanPlayerId = 'gp1';

String economicResourceLabelFullProvinceId() =>
    '$economicResourceLabelRegionId|$economicResourceLabelLocalProvinceId';

String economicResourceLabelTileKey(int x, int y) => overlayDarkTokenTileKey(
      regionId: economicResourceLabelRegionId,
      localProvinceId: economicResourceLabelLocalProvinceId,
      x: x,
      y: y,
    );

List<ResourceLabelInline> economicResourceLabelWidgets(WidgetTester tester) {
  return tester
      .widgetList<ResourceLabelInline>(find.byType(ResourceLabelInline))
      .toList(growable: false);
}

Future<void> pumpEconomicResourceLabelOverlay(
  WidgetTester tester, {
  required Map<String, int> improvementByTile,
}) async {
  final tk = economicResourceLabelTileKey(0, 0);
  final game = gameWithGrainTilesForOverlay(
    gameId: 'economic_res_label_dark_token_test',
    regionId: economicResourceLabelRegionId,
    fullProvinceId: economicResourceLabelFullProvinceId(),
    displayName: 'EconResLabelTest',
    humanPlayerId: economicResourceLabelHumanPlayerId,
    tileKeys: [tk],
    improvementByTile: improvementByTile,
    provinceOwnerId: economicResourceLabelHumanPlayerId,
  );
  final region = regionMapWithLandCells(
    regionId: economicResourceLabelRegionId,
    localProvinceId: economicResourceLabelLocalProvinceId,
    coords: [(x: 0, y: 0)],
    width: 1,
    height: 1,
    greatPowerFactionIds: const {economicResourceLabelHumanPlayerId},
    resourceId: 'grain',
  );

  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      region: region,
      displayId: economicResourceLabelFullProvinceId(),
      selectedTileKey: '$economicResourceLabelRegionId|other|9|9',
      humanPlayerId: economicResourceLabelHumanPlayerId,
      playerView: omniscientPlayerViewForTiles(
        humanPlayerId: economicResourceLabelHumanPlayerId,
        keys: [tk],
      ),
      shellWidth: 800,
    ),
  );
  await tester.pumpAndSettle();
}

void expectEconomicGrainLabelColor(
  WidgetTester tester,
  Color expected,
) {
  final all = economicResourceLabelWidgets(tester);
  expect(all, hasLength(1));
  expect(all.single.labelStyle?.color, expected);
}

void expectEconomicGrainTextColor(WidgetTester tester, Color expected) {
  final grain = tester.widgetList<Text>(
    find.byWidgetPredicate(
      (Widget w) =>
          w is Text && w.data == 'Grain' && w.style?.color == expected,
    ),
  );
  expect(grain, hasLength(1));
}
