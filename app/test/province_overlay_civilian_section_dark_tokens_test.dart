// Pins the dark editorial-monocle Civilian section body tokens for
// ProvinceSeaZoneDetailOverlay (S8 — Civilian body).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Civilian section body tokens
// (Refs #2865 S8).
//
// Material defaults (`Theme.of(context).colorScheme.onSurface`, the dark
// Material `Colors.white` fallback, or a bare `Text(...)` with `style: null`
// that falls through to `DefaultTextStyle`) MUST NOT colour the own- or
// foreign-civilian row labels. All colours resolve from
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

const _regionId = 'oldWorld';
const _localProvinceId = 'pCivDarkTokens';
const _humanPlayerId = 'gp1';
const _foreignPlayerId = 'gp2';
String get _fullProvinceId => '$_regionId|$_localProvinceId';

String _tileKey(int x, int y) => '$_fullProvinceId|$x|$y';

RegionMapViewData _regionWithLandCells(
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
    greatPowerFactionIds: const {_humanPlayerId, _foreignPlayerId},
    terrainColors: const {},
  );
}

Game _gameWithCivilianUnits({
  required List<String> tileKeys,
  required List<Unit> units,
}) {
  final visibility = <String, String>{
    for (final tk in tileKeys) tk: 'fullyVisible',
  };
  return Game(
    id: 'civilian_dark_tokens_test',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _fullProvinceId,
            regionId: _regionId,
            ownerId: _humanPlayerId,
            displayName: 'CivDarkTokens',
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        _regionId: {_fullProvinceId: tileKeys},
      },
      playerVisibilityByTile: {_humanPlayerId: visibility},
    ),
    players: const [
      Player(
        id: _humanPlayerId,
        displayName: 'Human',
        isHuman: true,
        treasury: 0,
      ),
      Player(
        id: _foreignPlayerId,
        displayName: 'Foreign',
        isHuman: false,
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

/// Finds the `Text(...)` row that prefixes with the literal `Explorer:`
/// emitted by `provinceOverlay_unitTarget` for the human player's own
/// idle Explorer civilian.
Finder _ownExplorerRowFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').startsWith('Explorer:') &&
        // Exclude the foreign-civilian line which embeds the owner prefix.
        !(w.data ?? '').contains('—'),
  );
}

/// Finds the `Text(...)` row emitted by `provinceOverlay_foreignUnitStatus`
/// for a visible foreign Merchant civilian (format `{owner} — {type}: {status}`).
Finder _foreignMerchantRowFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains('Merchant') &&
        (w.data ?? '').contains('—'),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Civilian section '
    'body (SPEC § Dark-theme Civilian section body tokens, S8)',
    () {
      testWidgets(
        'own civilian row label resolves to EditorialMonoclePalette.fg',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final ownUnit = Unit(
            id: 'c-own',
            type: 'Explorer',
            ownerId: _humanPlayerId,
            locationProvinceId: _fullProvinceId,
            tileKey: tk,
          );
          final game = _gameWithCivilianUnits(
            tileKeys: [tk],
            units: [ownUnit],
          );
          final region = _regionWithLandCells(
            [(x: 0, y: 0)],
            width: 1,
            height: 1,
          );

          await tester.pumpWidget(
            _darkOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              playerView: _omniscientViewForTiles([tk]),
            ),
          );
          await tester.pumpAndSettle();

          final finder = _ownExplorerRowFinder();
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason:
                'Test setup: with one own Explorer (humanPlayerId) the '
                'Civilian section must render the '
                '"Explorer: {status}" row label per '
                'provinceOverlay_unitTarget (app_en.arb).',
          );
          final Text label = tester.widget<Text>(finder.first);
          expect(
            label.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Own-civilian row label must resolve TextStyle.color to '
                'EditorialMonoclePalette.fg per SPEC § Dark-theme '
                'Civilian section body tokens (S8 — Civilian body).',
          );
        },
      );

      testWidgets(
        'foreign civilian row label resolves to '
        'EditorialMonoclePalette.muted',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final foreignUnit = Unit(
            id: 'c-foreign',
            type: 'Merchant',
            ownerId: _foreignPlayerId,
            locationProvinceId: _fullProvinceId,
            // Foreign civilian visibility requires a non-unknown tile
            // visibility on the unit's tile from the human player's view;
            // tileKey ties the unit to a tile the human can see.
            tileKey: tk,
          );
          final game = _gameWithCivilianUnits(
            tileKeys: [tk],
            units: [foreignUnit],
          );
          final region = _regionWithLandCells(
            [(x: 0, y: 0)],
            width: 1,
            height: 1,
          );

          await tester.pumpWidget(
            _darkOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              playerView: _omniscientViewForTiles([tk]),
            ),
          );
          await tester.pumpAndSettle();

          final finder = _foreignMerchantRowFinder();
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason:
                'Test setup: with one visible foreign Merchant the Civilian '
                'section must render the "{owner} — Merchant: {status}" row '
                'label per provinceOverlay_foreignUnitStatus (app_en.arb).',
          );
          final Text label = tester.widget<Text>(finder.first);
          expect(
            label.style?.color,
            EditorialMonoclePalette.muted,
            reason:
                'Foreign-civilian row label must resolve TextStyle.color '
                'to EditorialMonoclePalette.muted per SPEC § Dark-theme '
                'Civilian section body tokens (S8 — Civilian body).',
          );
        },
      );

      testWidgets(
        'negative: own civilian row label does not fall back to bare '
        'Material defaults',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final ownUnit = Unit(
            id: 'c-own',
            type: 'Explorer',
            ownerId: _humanPlayerId,
            locationProvinceId: _fullProvinceId,
            tileKey: tk,
          );
          final game = _gameWithCivilianUnits(
            tileKeys: [tk],
            units: [ownUnit],
          );
          final region = _regionWithLandCells(
            [(x: 0, y: 0)],
            width: 1,
            height: 1,
          );

          await tester.pumpWidget(
            _darkOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              playerView: _omniscientViewForTiles([tk]),
            ),
          );
          await tester.pumpAndSettle();

          final finder = _ownExplorerRowFinder();
          final Text label = tester.widget<Text>(finder.first);
          // The contract: the own-civilian row label must declare its own
          // `TextStyle.color`. A bare `Text(...)` with `style: null`
          // resolves the `color` getter to `null` (the property is unset;
          // rendering falls through to the ambient `DefaultTextStyle`).
          // Asserting `style?.color != null` catches a future regression
          // that drops the explicit `EditorialMonoclePalette.fg` colour
          // back to `null`.
          expect(
            label.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard: own-civilian row '
                'label must declare its own TextStyle.color rather than '
                'relying on DefaultTextStyle fall-through (so the contract '
                'survives a change in ambient bodyMedium colour).',
          );
          expect(
            label.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: own-civilian row '
                'label must not resolve to the dark Material `Colors.white` '
                'fallback before the editorialMonocle overlay.',
          );
          expect(
            label.style?.color,
            equals(EditorialMonoclePalette.fg),
            reason:
                'Material defaults regression guard: own-civilian row '
                'label must resolve to EditorialMonoclePalette.fg (the '
                'single source). Note: an `isNot(onSurface)` guard is '
                'intentionally omitted because under editorialMonocle the '
                'dark colorScheme.onSurface == EditorialMonoclePalette.fg, '
                'which would tautologically fail.',
          );
        },
      );

      testWidgets(
        'negative: foreign civilian row label is not '
        'Theme.colorScheme.onSurface and is not the dark Material default',
        (WidgetTester tester) async {
          final tk = _tileKey(0, 0);
          final foreignUnit = Unit(
            id: 'c-foreign',
            type: 'Merchant',
            ownerId: _foreignPlayerId,
            locationProvinceId: _fullProvinceId,
            tileKey: tk,
          );
          final game = _gameWithCivilianUnits(
            tileKeys: [tk],
            units: [foreignUnit],
          );
          final region = _regionWithLandCells(
            [(x: 0, y: 0)],
            width: 1,
            height: 1,
          );

          await tester.pumpWidget(
            _darkOverlay(
              game: game,
              region: region,
              displayId: _fullProvinceId,
              selectedTileKey: tk,
              playerView: _omniscientViewForTiles([tk]),
            ),
          );
          await tester.pumpAndSettle();

          final finder = _foreignMerchantRowFinder();
          final Text label = tester.widget<Text>(finder.first);
          final BuildContext context = tester.element(finder.first);
          final Color onSurface = Theme.of(context).colorScheme.onSurface;
          expect(
            label.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard: foreign-civilian row '
                'label must declare its own TextStyle.color rather than '
                'relying on DefaultTextStyle fall-through.',
          );
          expect(
            label.style?.color,
            isNot(equals(onSurface)),
            reason:
                'Material defaults regression guard: foreign-civilian row '
                'label must not resolve to '
                'Theme.of(context).colorScheme.onSurface; use '
                'EditorialMonoclePalette.muted instead.',
          );
          expect(
            label.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: foreign-civilian row '
                'label must not resolve to the dark Material `Colors.white` '
                'fallback.',
          );
          expect(
            label.style?.color,
            equals(EditorialMonoclePalette.muted),
            reason:
                'Material defaults regression guard: foreign-civilian row '
                'label must resolve to EditorialMonoclePalette.muted (the '
                'single source).',
          );
        },
      );
    },
  );
}
