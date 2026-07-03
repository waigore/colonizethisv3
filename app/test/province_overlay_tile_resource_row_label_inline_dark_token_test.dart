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
// remains optional so production-panel chips and other consumers keep
// their existing token contract until migrated by separate slices. The
// Economic section row layout was migrated to forward `labelStyle` in a
// follow-up slice (improved -> `EditorialMonoclePalette.fg`, improvable
// -> `EditorialMonoclePalette.muted`); this test isolates the Tile
// section's pin by selecting the `ResourceLabelInline` whose
// `labelStyle.color` matches `EditorialMonoclePalette.fg` and which
// renders the commodity-id label inside `_buildTileResourceLabelRow`.

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, VisibilityLevel;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';

import 'support/province_overlay_test_harness.dart';

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

/// Selects the Tile section's `ResourceLabelInline` widget by matching on
/// its `labelStyle.color` token (`EditorialMonoclePalette.fg`). The
/// Economic section row layout now also forwards `labelStyle` (improved
/// row: `EditorialMonoclePalette.fg`; improvable row:
/// `EditorialMonoclePalette.muted`). For this test the grain tile has
/// `improvementLevel == 0`, so the Economic section emits exactly one
/// improvable `ResourceLabelInline` whose `labelStyle.color` is
/// `EditorialMonoclePalette.muted`. Filtering on the `fg` token therefore
/// isolates the Tile commodity-id label under test deterministically.
/// Production-panel chips and other consumers still default to
/// `labelStyle == null` (covered by the bare-mount default-behaviour test
/// below) and are not affected by this filter.
List<ResourceLabelInline> _tilePinnedLabels(WidgetTester tester) {
  final all = tester.widgetList<ResourceLabelInline>(
    find.byType(ResourceLabelInline),
  );
  return all
      .where((w) => w.labelStyle?.color == EditorialMonoclePalette.fg)
      .toList(growable: false);
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile section '
      'Resource row — ResourceLabelInline commodity-id label '
      '(SPEC § Dark-theme Tile section body tokens — live-data body rows: '
      'Resource row commodity-id label)', () {
    testWidgets('commodity-id label resolves to EditorialMonoclePalette.fg under '
        'editorialMonocle (positive AC: Resource row commodity-id label '
        'colour)', (WidgetTester tester) async {
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
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          region: region,
          displayId: _fullProvinceId,
          selectedTileKey: tk,
          humanPlayerId: 'gp1',
          playerView: _omniscientViewForTiles([tk]),
          shellWidth: 800,
        ),
      );
      await tester.pumpAndSettle();

      final tilePinned = _tilePinnedLabels(tester);
      expect(
        tilePinned,
        hasLength(1),
        reason:
            'Expected exactly one fg-coloured ResourceLabelInline.labelStyle '
            'in the overlay tree — the Tile section\'s commodity-id label. '
            'The Economic section\'s improvable row mounts a '
            'ResourceLabelInline with labelStyle.color == '
            'EditorialMonoclePalette.muted (impLevel == 0 in this setup), so '
            'filtering on the fg token isolates the Tile pin deterministically.',
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
    });

    testWidgets('commodity-id label regression guard — never falls through '
        'DefaultTextStyle and never resolves to Colors.white (the bare '
        'dark Material bodyMedium fallback) under editorialMonocle', (
      WidgetTester tester,
    ) async {
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
      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: game,
          region: region,
          displayId: _fullProvinceId,
          selectedTileKey: tk,
          humanPlayerId: 'gp1',
          playerView: _omniscientViewForTiles([tk]),
          shellWidth: 800,
        ),
      );
      await tester.pumpAndSettle();

      final tilePinned = _tilePinnedLabels(tester);
      expect(
        tilePinned,
        isNotEmpty,
        reason:
            'Tile commodity-id label must be pinned via '
            'ResourceLabelInline.labelStyle with '
            'EditorialMonoclePalette.fg (SPEC regression guard); '
            'no fg-coloured ResourceLabelInline.labelStyle is mounted '
            'in the overlay tree, so the Tile call site is falling '
            'through to DefaultTextStyle.',
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
    });

    testWidgets('ResourceLabelInline default labelStyle == null preserves '
        'existing call-site behaviour for unmigrated consumers (negative '
        'AC: opt-in pin must not regress production-panel chips and other '
        'consumers that have not migrated to forward labelStyle)', (
      WidgetTester tester,
    ) async {
      // Mount ResourceLabelInline directly without `labelStyle` —
      // mirrors the default call-site behaviour used by consumers
      // that have not yet migrated to forward labelStyle (e.g.
      // production-panel commodity chips). The Economic section row
      // layout was migrated by a follow-up slice to forward
      // labelStyle, but the widget's default behaviour must still
      // preserve `labelStyle == null` and `Text(...)` `style: null`
      // for unmigrated consumers.
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: const Scaffold(body: ResourceLabelInline(commodityId: 'grain')),
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
            'labelStyle) must keep `labelStyle == null` so unmigrated '
            'consumers (e.g. production-panel commodity chips) '
            'preserve their token contract and resolve their '
            'commodity-id label through DefaultTextStyle (matching '
            'pre-slice behaviour).',
      );

      final text = tester.widget<Text>(
        find.byWidgetPredicate((Widget w) => w is Text && w.data == 'grain'),
      );
      expect(
        text.style,
        isNull,
        reason:
            'Default ResourceLabelInline must render its internal '
            'Text with `style: null` so the rendered colour resolves '
            'through DefaultTextStyle for unmigrated call sites '
            '(opt-in pin path must not change the default).',
      );
    });
  });
}
