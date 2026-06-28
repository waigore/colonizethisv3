// Pins the dark editorial-monocle Economic section commodity-id label
// tokens rendered by the shared `ResourceLabelInline` widget when mounted
// as the leading child of an Economic improved / improvable row in
// `_buildEconomicSection`.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Economic section body tokens
// (Refs #2865 S6 — extends the row-label slice by bringing the
// `ResourceLabelInline` commodity-id label rendered alongside the row
// label into scope for the Economic call site).
//
// The Economic call site MUST forward an `EditorialMonoclePalette.fg`-
// coloured `TextStyle` through `ResourceLabelInline.labelStyle` for the
// improved row and an `EditorialMonoclePalette.muted`-coloured
// `TextStyle` for the improvable row, so the rendered internal
// `Text(label ?? commodityId)` resolves to the canonical Economic body
// foreground / latent-yield muted token without `DefaultTextStyle`
// fall-through. `ResourceLabelInline.labelStyle` remains optional so
// production-panel chips and any other unmigrated call site keep their
// existing token contract until separately migrated.

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
const _localProvinceId = 'pEconResLabelTest';
const _humanPlayerId = 'gp1';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => '$_fullProvinceId|$x|$y';

RegionMapViewData _regionWithGrainCells(
  List<({int x, int y})> coords, {
  required int width,
  required int height,
}) {
  final cells = <CellViewData>[
    for (final c in coords)
      CellViewData(
        x: c.x,
        y: c.y,
        regionCellId: _localProvinceId,
        isSea: false,
        terrainTypeId: 'plains',
        resourceId: 'grain',
        visibility: TileVisibility.visible,
      ),
  ];
  return RegionMapViewData(
    regionId: _regionId,
    width: width,
    height: height,
    cellSize: 32,
    cells: cells,
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {_humanPlayerId},
    terrainColors: const {},
  );
}

Game _gameWithGrainTiles({
  required List<String> tileKeys,
  required Map<String, int> improvementByTile,
}) {
  final visibility = <String, String>{
    for (final tk in tileKeys) tk: 'fullyVisible',
  };
  final prospected = <String>{...tileKeys};
  return Game(
    id: 'economic_res_label_dark_token_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _fullProvinceId,
            regionId: _regionId,
            ownerId: _humanPlayerId,
            displayName: 'EconResLabelTest',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        _regionId: {_fullProvinceId: tileKeys},
      },
      resourceByTileKey: {for (final tk in tileKeys) tk: 'grain'},
      playerVisibilityByTile: {_humanPlayerId: visibility},
      playerProspectedTiles: {_humanPlayerId: prospected},
      tileState: TileMapState(improvementByTile: improvementByTile),
    ),
    players: const [
      Player(
        id: _humanPlayerId,
        displayName: 'Human',
        isHuman: true,
        treasury: 0,
      ),
    ],
  );
}

PlayerView _omniscientViewForTiles(Iterable<String> keys) {
  return PlayerView(
    playerId: _humanPlayerId,
    player: const Player(
      id: _humanPlayerId,
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

Widget _darkOverlay({
  required Game game,
  required RegionMapViewData region,
  required String displayId,
  required String selectedTileKey,
  required PlayerView playerView,
}) {
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: SizedBox(
        // A dummy `selectedTileKey` outside the province (no Tile-section
        // `ResourceLabelInline` is mounted) keeps the test scoped to the
        // Economic section's commodity-id labels. Use a wide width so the
        // wide-shell single-column body renders both Economic rows under
        // each test's resource bucket.
        width: 800,
        child: ProvinceSeaZoneDetailOverlay(
          game: game,
          region: region,
          displayId: displayId,
          selectedTileKey: selectedTileKey,
          humanPlayerId: _humanPlayerId,
          playerView: playerView,
        ),
      ),
    ),
  );
}

/// Selects every `ResourceLabelInline` mounted by the Economic section
/// for the rendered grain-tile rows. The Tile section's
/// `ResourceLabelInline` (when present) renders inside
/// `_buildTileResourceLabelRow` for the selected tile only; this test
/// mounts a `selectedTileKey` that does not match a province tile, so
/// the Tile section path emits its non-resource-row branch and no
/// `ResourceLabelInline` is mounted there. Every `ResourceLabelInline`
/// found in the overlay tree therefore belongs to the Economic section.
List<ResourceLabelInline> _allLabels(WidgetTester tester) {
  return tester
      .widgetList<ResourceLabelInline>(find.byType(ResourceLabelInline))
      .toList(growable: false);
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Economic section '
    '— ResourceLabelInline commodity-id label '
    '(SPEC § Dark-theme Economic section body tokens — improved / '
    'improvable commodity-id label colour)',
    () {
      testWidgets(
        'improved-row commodity-id label resolves to '
        'EditorialMonoclePalette.fg under editorialMonocle (positive AC: '
        'Economic improved-row commodity-id label colour)',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final game = _gameWithGrainTiles(
            tileKeys: [tk],
            improvementByTile: {tk: 2},
          );
          final region = _regionWithGrainCells(
            [(x: 0, y: 0)],
            width: 1,
            height: 1,
          );

          // Use a selectedTileKey that does not match any tile in the
          // region so the Tile section emits no ResourceLabelInline.
          await tester.pumpWidget(
            _darkOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: '$_regionId|other|9|9',
              playerView: _omniscientViewForTiles([tk]),
            ),
          );
          await tester.pumpAndSettle();

          final all = _allLabels(tester);
          expect(
            all,
            hasLength(1),
            reason:
                'Test setup: with one improved grain tile and no Tile-'
                'section ResourceLabelInline, exactly one ResourceLabelInline '
                'must be mounted (the Economic improved row\'s leading icon + '
                'commodity-id label).',
          );
          expect(
            all.single.labelStyle?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Economic improved-row ResourceLabelInline.labelStyle.color '
                'must resolve to EditorialMonoclePalette.fg per SPEC AC '
                '"Dark-theme Economic improved-row commodity-id label colour".',
          );

          // The internal rendered Text(label ?? commodityId) inside the
          // improved row must inherit the labelStyle color verbatim.
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
                'style.color == EditorialMonoclePalette.fg (the Economic '
                'improved-row commodity-id label inside ResourceLabelInline). '
                'Found ${fgGrain.length}. Check that the Economic improved-row '
                'call site forwards an fg-coloured TextStyle through '
                'ResourceLabelInline.labelStyle.',
          );
        },
      );

      testWidgets(
        'improvable-row commodity-id label resolves to '
        'EditorialMonoclePalette.muted under editorialMonocle (positive '
        'AC: Economic improvable-row commodity-id label colour)',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final game = _gameWithGrainTiles(
            tileKeys: [tk],
            improvementByTile: const {},
          );
          final region = _regionWithGrainCells(
            [(x: 0, y: 0)],
            width: 1,
            height: 1,
          );

          await tester.pumpWidget(
            _darkOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: '$_regionId|other|9|9',
              playerView: _omniscientViewForTiles([tk]),
            ),
          );
          await tester.pumpAndSettle();

          final all = _allLabels(tester);
          expect(
            all,
            hasLength(1),
            reason:
                'Test setup: with one improvable grain tile and no Tile-'
                'section ResourceLabelInline, exactly one ResourceLabelInline '
                'must be mounted (the Economic improvable row\'s leading icon + '
                'commodity-id label).',
          );
          expect(
            all.single.labelStyle?.color,
            EditorialMonoclePalette.muted,
            reason:
                'Economic improvable-row ResourceLabelInline.labelStyle.color '
                'must resolve to EditorialMonoclePalette.muted per SPEC AC '
                '"Dark-theme Economic improvable-row commodity-id label colour".',
          );

          // The internal rendered Text(label ?? commodityId) inside the
          // improvable row must inherit the labelStyle color verbatim.
          final mutedGrain = tester.widgetList<Text>(
            find.byWidgetPredicate(
              (Widget w) =>
                  w is Text &&
                  w.data == 'grain' &&
                  w.style?.color == EditorialMonoclePalette.muted,
            ),
          );
          expect(
            mutedGrain,
            hasLength(1),
            reason:
                'Exactly one rendered "grain" Text widget must carry '
                'style.color == EditorialMonoclePalette.muted (the Economic '
                'improvable-row commodity-id label inside ResourceLabelInline). '
                'Found ${mutedGrain.length}. Check that the Economic '
                'improvable-row call site forwards a muted-coloured TextStyle '
                'through ResourceLabelInline.labelStyle.',
          );
        },
      );

      testWidgets(
        'improved-row commodity-id label regression guard — never falls '
        'through DefaultTextStyle and never resolves to Colors.white (the '
        'bare dark Material bodyMedium fallback) under editorialMonocle '
        '(negative AC: Economic improved-row commodity-id label Material '
        'fallback regression guard)',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final game = _gameWithGrainTiles(
            tileKeys: [tk],
            improvementByTile: {tk: 2},
          );
          final region = _regionWithGrainCells(
            [(x: 0, y: 0)],
            width: 1,
            height: 1,
          );

          await tester.pumpWidget(
            _darkOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: '$_regionId|other|9|9',
              playerView: _omniscientViewForTiles([tk]),
            ),
          );
          await tester.pumpAndSettle();

          final all = _allLabels(tester);
          expect(
            all,
            isNotEmpty,
            reason:
                'Economic improved-row commodity-id label must be pinned via '
                'ResourceLabelInline.labelStyle (SPEC regression guard); no '
                'ResourceLabelInline is mounted at all in the overlay tree, '
                'which suggests the Economic section did not render the '
                'improved row.',
          );
          final style = all.single.labelStyle;
          expect(
            style,
            isNotNull,
            reason:
                'Economic improved-row ResourceLabelInline must declare a '
                'non-null labelStyle so the rendered commodity-id Text does '
                'not fall through DefaultTextStyle (SPEC AC "Dark-theme '
                'Economic body — improved-row commodity-id label Material '
                'fallback regression guard").',
          );
          expect(
            style?.color,
            isNotNull,
            reason:
                'Economic improved-row ResourceLabelInline.labelStyle.color '
                'must be non-null per SPEC regression guard.',
          );
          expect(
            style?.color,
            isNot(Colors.white),
            reason:
                'Economic improved-row commodity-id label must not regress '
                'to the dark Material bodyMedium `Colors.white` fallback (SPEC '
                'regression guard).',
          );
          expect(
            style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Economic improved-row commodity-id label must resolve to '
                'EditorialMonoclePalette.fg (SPEC regression guard positive '
                'token pin).',
          );
        },
      );

      testWidgets(
        'improvable-row commodity-id label regression guard — never falls '
        'through DefaultTextStyle, never resolves to Colors.white, and '
        'never resolves to Theme.colorScheme.onSurface (negative AC: '
        'Economic improvable-row commodity-id label Material fallback '
        'regression guard)',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final game = _gameWithGrainTiles(
            tileKeys: [tk],
            improvementByTile: const {},
          );
          final region = _regionWithGrainCells(
            [(x: 0, y: 0)],
            width: 1,
            height: 1,
          );

          await tester.pumpWidget(
            _darkOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: '$_regionId|other|9|9',
              playerView: _omniscientViewForTiles([tk]),
            ),
          );
          await tester.pumpAndSettle();

          final all = _allLabels(tester);
          expect(
            all,
            isNotEmpty,
            reason:
                'Economic improvable-row commodity-id label must be pinned '
                'via ResourceLabelInline.labelStyle (SPEC regression guard); '
                'no ResourceLabelInline is mounted at all in the overlay '
                'tree, which suggests the Economic section did not render '
                'the improvable row.',
          );
          final widget = all.single;
          final style = widget.labelStyle;
          expect(
            style,
            isNotNull,
            reason:
                'Economic improvable-row ResourceLabelInline must declare a '
                'non-null labelStyle so the rendered commodity-id Text does '
                'not fall through DefaultTextStyle (SPEC AC "Dark-theme '
                'Economic body — improvable-row commodity-id label Material '
                'fallback regression guard").',
          );
          expect(
            style?.color,
            isNotNull,
            reason:
                'Economic improvable-row ResourceLabelInline.labelStyle.color '
                'must be non-null per SPEC regression guard.',
          );
          expect(
            style?.color,
            isNot(Colors.white),
            reason:
                'Economic improvable-row commodity-id label must not regress '
                'to the dark Material bodyMedium `Colors.white` fallback (SPEC '
                'regression guard).',
          );
          // Locate any Element so we can read Theme.of(context).colorScheme.
          final BuildContext context = tester.element(
            find.byType(ResourceLabelInline).first,
          );
          final Color onSurface = Theme.of(context).colorScheme.onSurface;
          expect(
            style?.color,
            isNot(equals(onSurface)),
            reason:
                'Economic improvable-row commodity-id label must not resolve '
                'to Theme.of(context).colorScheme.onSurface (the dark Material '
                'bodyMedium proxy — distinct from EditorialMonoclePalette.muted '
                'under any non-editorialMonocle theme).',
          );
          expect(
            style?.color,
            EditorialMonoclePalette.muted,
            reason:
                'Economic improvable-row commodity-id label must resolve to '
                'EditorialMonoclePalette.muted (SPEC regression guard positive '
                'token pin).',
          );
        },
      );
    },
  );
}
