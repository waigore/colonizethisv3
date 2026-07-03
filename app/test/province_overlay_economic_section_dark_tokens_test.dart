// Pins the dark editorial-monocle Economic section body tokens for
// ProvinceSeaZoneDetailOverlay (S6 — Economic body).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Economic section body tokens
// (Refs #2865 S6).
//
// Material defaults (`Theme.of(context).colorScheme.onSurface`, the dark
// Material `Colors.white` fallback, or a bare `Text(...)` with `style: null`
// that falls through to `DefaultTextStyle`) MUST NOT colour the
// improved- or improvable-resource row labels. All colours resolve from
// `EditorialMonoclePalette` tokens so the dark theme owns this surface.

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

import 'support/province_overlay_test_harness.dart';

const _regionId = 'oldWorld';
const _localProvinceId = 'pEconDarkTokens';
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
    id: 'economic_dark_tokens_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _fullProvinceId,
            regionId: _regionId,
            ownerId: _humanPlayerId,
            displayName: 'EconDarkTokens',
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

/// Finds the `Expanded(child: Text(...))` row label whose data contains the
/// localized improved-tile suffix (`with ...`) and the `grain` resource id.
/// The label string is `"{terrain}/grain with {impBase}"` per
/// `app/lib/l10n/arb/app_en.arb` `province_economic_resourceRow` +
/// `province_economic_withImprovement`. The match deliberately excludes the
/// `(improvable)` suffix so the test never confuses the two row variants.
Finder _improvedRowLabelFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains('grain') &&
        (w.data ?? '').contains('with ') &&
        !(w.data ?? '').contains('(improvable)'),
  );
}

/// Finds the `Expanded(child: Text(...))` row label whose data carries the
/// localized improvable-tile suffix `(improvable)` and the `grain` resource
/// id. The label string is `"{terrain}/grain (improvable)"` per
/// `app/lib/l10n/arb/app_en.arb` `province_economic_resourceRow` +
/// `province_economic_improvableSuffix`.
Finder _improvableRowLabelFinder() {
  return find.byWidgetPredicate(
    (w) => w is Text && (w.data ?? '').contains('grain') && (w.data ?? '').contains('(improvable)'),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Economic section '
    'body (SPEC § Dark-theme Economic section body tokens)',
    () {
      testWidgets(
        'improved-resource row label resolves to EditorialMonoclePalette.fg',
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
            buildProvinceOverlayDarkThemeShell(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              humanPlayerId: _humanPlayerId,
              playerView: _omniscientViewForTiles([tk]),
              shellWidth: 800,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _improvedRowLabelFinder();
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason:
                'Test setup: with improvementByTile[$tk] = 2 the Economic '
                'section must render the "{terrain}/grain with {impBase}" '
                'row label per province_economic_resourceRow + '
                'province_economic_withImprovement (app_en.arb).',
          );
          final Text label = tester.widget<Text>(finder.first);
          expect(
            label.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Improved-resource row label must resolve TextStyle.color '
                'to EditorialMonoclePalette.fg per SPEC § Dark-theme '
                'Economic section body tokens (S6 — Economic body).',
          );
        },
      );

      testWidgets(
        'improvable-resource row label resolves to '
        'EditorialMonoclePalette.muted',
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
            buildProvinceOverlayDarkThemeShell(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              humanPlayerId: _humanPlayerId,
              playerView: _omniscientViewForTiles([tk]),
              shellWidth: 800,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _improvableRowLabelFinder();
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason:
                'Test setup: with no improvement set, the Economic section '
                'must render the "{terrain}/grain (improvable)" row label '
                'per province_economic_resourceRow + '
                'province_economic_improvableSuffix (app_en.arb).',
          );
          final Text label = tester.widget<Text>(finder.first);
          expect(
            label.style?.color,
            EditorialMonoclePalette.muted,
            reason:
                'Improvable-resource row label must resolve '
                'TextStyle.color to EditorialMonoclePalette.muted per SPEC '
                '§ Dark-theme Economic section body tokens (S6 — Economic '
                'body).',
          );
        },
      );

      testWidgets(
        'negative: improved-resource row label does not fall back to bare '
        'Material defaults',
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
            buildProvinceOverlayDarkThemeShell(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              humanPlayerId: _humanPlayerId,
              playerView: _omniscientViewForTiles([tk]),
              shellWidth: 800,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _improvedRowLabelFinder();
          final Text label = tester.widget<Text>(finder.first);
          // The contract: the improved-resource row label must declare its
          // own `TextStyle.color`. A bare `Text(...)` with `style: null`
          // resolves the `color` getter to `null` (the property is unset;
          // rendering then falls through to the ambient `DefaultTextStyle`).
          // Asserting `style?.color != null` catches any future regression
          // that drops the explicit `EditorialMonoclePalette.fg` colour
          // back to `null`.
          expect(
            label.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard: improved-row label '
                'must declare its own TextStyle.color rather than relying '
                'on DefaultTextStyle fall-through (so the contract survives '
                'a change in ambient bodyMedium colour).',
          );
          expect(
            label.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: improved-row label '
                'must not resolve to the dark Material `Colors.white` '
                'fallback before the editorialMonocle overlay.',
          );
          expect(
            label.style?.color,
            equals(EditorialMonoclePalette.fg),
            reason:
                'Material defaults regression guard: improved-row label '
                'must resolve to EditorialMonoclePalette.fg (the single '
                'source).',
          );
        },
      );

      testWidgets(
        'negative: improvable-resource row label is not '
        'Theme.colorScheme.onSurface and is not the dark Material default',
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
            buildProvinceOverlayDarkThemeShell(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              humanPlayerId: _humanPlayerId,
              playerView: _omniscientViewForTiles([tk]),
              shellWidth: 800,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _improvableRowLabelFinder();
          final Text label = tester.widget<Text>(finder.first);
          final BuildContext context = tester.element(finder.first);
          final Color onSurface = Theme.of(context).colorScheme.onSurface;
          expect(
            label.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard: improvable-row label '
                'must declare its own TextStyle.color rather than relying '
                'on DefaultTextStyle fall-through.',
          );
          expect(
            label.style?.color,
            isNot(equals(onSurface)),
            reason:
                'Material defaults regression guard: improvable-row label '
                'must not resolve to Theme.of(context).colorScheme.onSurface; '
                'use EditorialMonoclePalette.muted instead.',
          );
          expect(
            label.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: improvable-row label '
                'must not resolve to the dark Material `Colors.white` '
                'fallback.',
          );
          expect(
            label.style?.color,
            equals(EditorialMonoclePalette.muted),
            reason:
                'Material defaults regression guard: improvable-row label '
                'must resolve to EditorialMonoclePalette.muted (the single '
                'source).',
          );
        },
      );
    },
  );
}
