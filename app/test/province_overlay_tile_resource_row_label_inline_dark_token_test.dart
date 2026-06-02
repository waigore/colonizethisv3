// Pins the dark editorial-monocle Tile section Resource row commodity-id
// label token: the internal `Text(label ?? commodityId)` rendered by the
// shared `ResourceLabelInline` widget when mounted as the visible-commodity
// branch of `_buildTileResourceLabelRow` (e.g. the "grain" label next to
// the commodity icon).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Tile section body tokens
// (Refs #2865 S5 — extends the prefix / no-resource fallback slice by
// bringing the previously deferred `ResourceLabelInline` commodity-id
// label into scope for the Tile call site).
//
// The Tile call site MUST forward an `EditorialMonoclePalette.fg`-coloured
// `TextStyle` through `ResourceLabelInline.labelStyle` so the rendered
// internal `Text(...)` resolves to `EditorialMonoclePalette.fg` (no
// `DefaultTextStyle` fall-through). `ResourceLabelInline.labelStyle`
// remains optional so the Economic section row layout, production-panel
// chips, and any other call site keep their existing token contract until
// migrated by separate slices.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pTileResLabelTest';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => '$_fullProvinceId|$x|$y';

RegionMapViewData _regionWithCells(List<CellViewData> cells, int w, int h) {
  return RegionMapViewData(
    regionId: _regionId,
    width: w,
    height: h,
    cellSize: 32,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {'gp1'},
    terrainColors: const {},
  );
}

Game _minimalGameWithGrainTile(String tk) {
  return Game(
    id: 'tile_res_label_token_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _fullProvinceId,
            regionId: _regionId,
            displayName: 'TileResLabelTest',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        _regionId: {
          _fullProvinceId: [tk],
        },
      },
      resourceByTileKey: {tk: 'grain'},
      playerVisibilityByTile: {
        'gp1': {tk: 'fullyVisible'},
      },
      playerProspectedTiles: {
        'gp1': {tk},
      },
    ),
    players: const [
      Player(id: 'gp1', displayName: 'Human', isHuman: true, treasury: 0),
    ],
  );
}

PlayerView _omniscientViewForTiles(Iterable<String> keys) {
  return PlayerView(
    playerId: 'gp1',
    player: const Player(
      id: 'gp1',
      displayName: 'Human',
      isHuman: true,
      treasury: 0,
    ),
    ownUnitsById: const {},
    provincesById: const {},
    visibilityByTile: {for (final k in keys) k: VisibilityLevel.fullyVisible},
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

Widget _darkOverlayWithGrainTile() {
  final tk = _tileKey(0, 0);
  final game = _minimalGameWithGrainTile(tk);
  final region = _regionWithCells(
    const [
      CellViewData(
        x: 0,
        y: 0,
        regionCellId: _localProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: 'grain',
        visibility: TileVisibility.visible,
      ),
    ],
    1,
    1,
  );
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: SizedBox(
        width: 800,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: region,
          displayId: _fullProvinceId,
          selectedTileKey: tk,
          humanPlayerId: 'gp1',
          playerView: _omniscientViewForTiles([tk]),
        ),
      ),
    ),
  );
}

/// Selects every `ResourceLabelInline` whose `labelStyle` is set (the Tile
/// section's opt-in pin path). The Economic section row layout mounts
/// `ResourceLabelInline` without forwarding `labelStyle` so its instances
/// are filtered out here, isolating the Tile commodity-id label under test.
List<ResourceLabelInline> _tilePinnedLabels(WidgetTester tester) {
  final all = tester.widgetList<ResourceLabelInline>(
    find.byType(ResourceLabelInline),
  );
  return all.where((w) => w.labelStyle != null).toList(growable: false);
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile section '
    'Resource row — ResourceLabelInline commodity-id label '
    '(SPEC § Dark-theme Tile section body tokens — live-data body rows: '
    'Resource row commodity-id label)',
    () {
      testWidgets(
        'commodity-id label resolves to EditorialMonoclePalette.fg under '
        'editorialMonocle (positive AC: Resource row commodity-id label '
        'colour)',
        (WidgetTester tester) async {
          await tester.pumpWidget(_darkOverlayWithGrainTile());
          await tester.pumpAndSettle();

          final tilePinned = _tilePinnedLabels(tester);
          expect(
            tilePinned,
            hasLength(1),
            reason:
                'Expected exactly one ResourceLabelInline with a non-null '
                'labelStyle (the Tile section\'s opt-in pin path). '
                'Economic ResourceLabelInline instances must remain '
                'unaffected so their existing token contract is '
                'preserved until separately migrated.',
          );
          expect(
            tilePinned.single.labelStyle?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Tile Resource row ResourceLabelInline.labelStyle.color '
                'must resolve to EditorialMonoclePalette.fg (SPEC AC '
                '"Dark-theme Tile live-data — Resource row commodity-id '
                'label colour").',
          );

          // The internal rendered `Text(label ?? commodityId)` must inherit
          // that style verbatim. Find the `Text` widget whose data equals
          // the commodity id ("grain") and whose own `style.color` equals
          // `fg`. There is exactly one such `Text` because the Economic
          // section row layout renders its commodity-id label without an
          // explicit fg colour (it falls through to DefaultTextStyle).
          final fgGrain = tester.widgetList<Text>(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is Text &&
                  w.data == 'grain' &&
                  w.style?.color == EditorialMonoclePalette.fg,
            ),
          );
          expect(
            fgGrain,
            hasLength(1),
            reason:
                'Exactly one rendered "grain" Text widget must carry '
                'style.color == EditorialMonoclePalette.fg (the Tile '
                'commodity-id label inside ResourceLabelInline). Found '
                '${fgGrain.length}. Check that the Tile call site still '
                'forwards _fgBodyStyle() through '
                'ResourceLabelInline.labelStyle.',
          );
        },
      );

      testWidgets(
        'commodity-id label regression guard — never falls through '
        'DefaultTextStyle and never resolves to Colors.white (the bare '
        'dark Material bodyMedium fallback) under editorialMonocle',
        (WidgetTester tester) async {
          await tester.pumpWidget(_darkOverlayWithGrainTile());
          await tester.pumpAndSettle();

          final tilePinned = _tilePinnedLabels(tester);
          expect(
            tilePinned,
            isNotEmpty,
            reason:
                'Tile commodity-id label must be pinned via '
                'ResourceLabelInline.labelStyle (SPEC regression guard); '
                'no ResourceLabelInline carries a non-null labelStyle, '
                'so the Tile call site is falling through to '
                'DefaultTextStyle.',
          );
          final style = tilePinned.single.labelStyle;
          expect(
            style,
            isNotNull,
            reason:
                'Tile ResourceLabelInline must declare a non-null '
                'labelStyle so the rendered commodity-id Text does not '
                'fall through DefaultTextStyle (SPEC AC "Dark-theme '
                'Tile live-data — Resource row commodity-id label '
                'Material fallback regression guard").',
          );
          expect(
            style?.color,
            isNotNull,
            reason:
                'Tile ResourceLabelInline.labelStyle.color must be '
                'non-null per SPEC regression guard.',
          );
          expect(
            style?.color,
            isNot(Colors.white),
            reason:
                'Tile commodity-id label must not regress to the dark '
                'Material bodyMedium `Colors.white` fallback (SPEC '
                'regression guard).',
          );
          expect(
            style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Tile commodity-id label must resolve to '
                'EditorialMonoclePalette.fg (SPEC regression guard '
                'positive token pin).',
          );
        },
      );

      testWidgets(
        'ResourceLabelInline default labelStyle == null preserves '
        'existing call-site behaviour for non-Tile consumers (negative '
        'AC: opt-in pin must not regress Economic / production-panel '
        'chips)',
        (WidgetTester tester) async {
          // Mount ResourceLabelInline directly without `labelStyle` —
          // mirrors the default call-site behaviour used by the Economic
          // section row layout and the production-panel commodity chips.
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
          expect(
            widget.labelStyle,
            isNull,
            reason:
                'Default ResourceLabelInline (without explicit '
                'labelStyle) must keep `labelStyle == null` so existing '
                'consumers (Economic improved / improvable rows, '
                'production-panel chips) preserve their token contract '
                'and resolve their commodity-id label through '
                'DefaultTextStyle (matching pre-slice behaviour).',
          );

          final text = tester.widget<Text>(
            find.byWidgetPredicate(
              (Widget w) => w is Text && w.data == 'grain',
            ),
          );
          expect(
            text.style,
            isNull,
            reason:
                'Default ResourceLabelInline must render its internal '
                'Text with `style: null` so the rendered colour resolves '
                'through DefaultTextStyle for non-Tile call sites '
                '(opt-in pin path must not change the default).',
          );
        },
      );
    },
  );
}
