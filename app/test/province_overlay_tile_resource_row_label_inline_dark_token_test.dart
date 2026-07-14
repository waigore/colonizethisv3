// Pins the dark editorial-monocle Tile section Resource row commodity-id
// label token via ResourceLabelInline. Positive + Material-default guards
// share one pump (Refs #4021 densify).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Tile section body tokens.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';

import 'support/editorial_monocle_dark_token_assertions.dart';
import 'support/province_overlay_dark_token_scenarios.dart';
import 'support/province_overlay_test_harness.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pTileResLabelTest';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => overlayDarkTokenTileKey(
  regionId: _regionId,
  localProvinceId: _localProvinceId,
  x: x,
  y: y,
);

List<ResourceLabelInline> _tilePinnedLabels(WidgetTester tester) {
  return tester
      .widgetList<ResourceLabelInline>(find.byType(ResourceLabelInline))
      .where((w) => w.labelStyle?.color == EditorialMonoclePalette.fg)
      .toList(growable: false);
}

Future<void> _pumpGrainTileOverlay(WidgetTester tester) async {
  final tk = _tileKey(0, 0);
  final game = gameWithGrainTilesForOverlay(
    gameId: 'tile_res_label_token_test',
    regionId: _regionId,
    fullProvinceId: _fullProvinceId,
    displayName: 'TileResLabelTest',
    humanPlayerId: 'gp1',
    tileKeys: [tk],
  );
  final region = regionMapWithLandCells(
    regionId: _regionId,
    localProvinceId: _localProvinceId,
    coords: [(x: 0, y: 0)],
    width: 1,
    height: 1,
    greatPowerFactionIds: const {'gp1'},
    resourceId: 'grain',
  );
  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      region: region,
      displayId: _fullProvinceId,
      selectedTileKey: tk,
      humanPlayerId: 'gp1',
      playerView: omniscientPlayerViewForTiles(
        humanPlayerId: 'gp1',
        keys: [tk],
      ),
      shellWidth: 800,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile section '
    'Resource row — ResourceLabelInline commodity-id label '
    '(SPEC § Dark-theme Tile section body tokens)',
    () {
      testWidgets(
        'commodity-id label resolves to fg (with Material-default guards)',
        (WidgetTester tester) async {
          await _pumpGrainTileOverlay(tester);

          final tilePinned = _tilePinnedLabels(tester);
          expect(
            tilePinned,
            hasLength(1),
            reason:
                'Exactly one fg ResourceLabelInline.labelStyle (Tile pin); '
                'Economic improvable row uses muted.',
          );
          expectFgSingleSource(
            tilePinned.single.labelStyle?.color,
            'Tile ResourceLabelInline.labelStyle',
          );

          final fgGrain = tester.widgetList<Text>(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is Text &&
                  w.data == 'Grain' &&
                  w.style?.color == EditorialMonoclePalette.fg,
            ),
          );
          expect(
            fgGrain,
            hasLength(1),
            reason: 'Exactly one "Grain" Text must carry style.color == fg.',
          );
          expectFgSingleSource(
            fgGrain.single.style?.color,
            'Tile commodity-id Text',
          );
        },
      );

      testWidgets(
        'ResourceLabelInline default labelStyle == null preserves '
        'unmigrated consumer behaviour',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: AppThemes.editorialMonocle,
              home: const Scaffold(
                body: ResourceLabelInline(commodityId: 'grain'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final widget = tester.widget<ResourceLabelInline>(
            find.byType(ResourceLabelInline),
          );
          expect(widget.labelStyle, isNull);
          final text = tester.widget<Text>(
            find.byWidgetPredicate(
              (Widget w) => w is Text && w.data == 'Grain',
            ),
          );
          expect(text.style, isNull);
        },
      );
    },
  );
}
