// Pins the Tile-section town / capital designation line for
// ProvinceSeaZoneDetailOverlay (Refs #3617).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Province overlay content `Tile` — Tile town / capital designation, and
// the matching § Acceptance criteria (Tile town designation line, Tile
// capital designation line, Tile ordinary land tile — no designation, Tile
// designation suppressed for sea / unrevealed, Tile designation uses
// localized keys).
//
// When the user selects a revealed land tile, the Tile section shows a
// single contextual designation line between Terrain and Resource: the
// capital line when the tile is any faction's capital tile (highest
// priority), else the town line when the tile is the province town, else no
// line at all. All strings resolve through AppLocalizations parameterized
// keys and render in EditorialMonoclePalette.fg.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

/// Sentinel capital tile that never coincides with a real demo tile, used to
/// force every faction's capital away from the tile under test so the town /
/// ordinary branches are deterministic.
final CapitalTile _sentinelCapital = CapitalTile(
  regionId: 'oldWorld',
  provinceId: 'oldWorld|__sentinel_capital__',
  x: 9991,
  y: 9992,
);

CapitalTile _capitalTileFromKey(String tileKey) {
  final parts = tileKey.split('|');
  return CapitalTile(
    regionId: parts[0],
    provinceId: '${parts[0]}|${parts[1]}',
    x: int.parse(parts[parts.length - 2]),
    y: int.parse(parts.last),
  );
}

/// Replaces every faction's `capitalTile` with [_sentinelCapital] so no real
/// tile resolves as a capital (copyWith cannot clear a nullable field, so a
/// distinct sentinel is used instead).
Game _withoutMatchingCapitals(Game g) => g.copyWith(
  players: g.players
      .map((p) => p.copyWith(capitalTile: _sentinelCapital))
      .toList(),
  minorNations: g.minorNations
      .map((m) => m.copyWith(capitalTile: _sentinelCapital))
      .toList(),
  tribes: g.tribes
      .map((t) => t.copyWith(capitalTile: _sentinelCapital))
      .toList(),
);

/// Sets [provinceId]'s `townTileKey` (Old World) to [townTileKey].
Game _withProvinceTownTile(Game g, String provinceId, String townTileKey) {
  final ws = g.worldState;
  final provinces = ws.oldWorld.provinces
      .map((p) => p.id == provinceId ? p.copyWith(townTileKey: townTileKey) : p)
      .toList();
  return g.copyWith(
    worldState: ws.copyWith(
      oldWorld: RegionData(provinces: provinces, units: ws.oldWorld.units),
    ),
  );
}

/// Makes [g]'s first player's capital tile equal [tileKey].
Game _withFirstPlayerCapitalTile(Game g, String tileKey) {
  final cap = _capitalTileFromKey(tileKey);
  return g.copyWith(
    players: <Player>[
      g.players.first.copyWith(
        capitalTile: cap,
        capitalProvinceId: cap.provinceId,
      ),
      ...g.players.skip(1),
    ],
  );
}

String _provinceDisplayName(Game g, String provinceId) {
  for (final p in g.worldState.oldWorld.provinces) {
    if (p.id == provinceId) return p.displayName ?? provinceId;
  }
  return provinceId;
}

Widget _darkOverlay({
  required Game game,
  required RegionMapViewData region,
  required String displayId,
  String? selectedTileKey,
}) {
  final humanPlayerId = game.players.first.id;
  // Refs #3656: buildPlayerView ignores its topology argument, so an empty
  // const MapTopology() replaces the ~11s getDebugInitGameResult() map
  // generation with identical PlayerView output for these demo-data overlays.
  final playerView = buildPlayerView(
    game,
    const MapTopology(),
    humanPlayerId,
  );
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: region,
        displayId: displayId,
        selectedTileKey: selectedTileKey,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
        draftOrders: const Orders(),
      ),
    ),
  );
}

/// Golden harness host: wraps the overlay in a keyed `RepaintBoundary` at a
/// fixed size so the Tile-section designation line is pinned as a pixel
/// baseline (mirrors `diplomacy_panel_goldens_test.dart`). Uses
/// `AppThemes.editorialMonocle` for the dark-theme chrome.
Widget _goldenOverlay({
  required Game game,
  required RegionMapViewData region,
  required String displayId,
  required Key boundaryKey,
  String? selectedTileKey,
}) {
  final humanPlayerId = game.players.first.id;
  // Refs #3656: buildPlayerView ignores its topology argument, so an empty
  // const MapTopology() replaces the ~11s getDebugInitGameResult() map
  // generation with identical PlayerView output for these demo-data overlays.
  final playerView = buildPlayerView(
    game,
    const MapTopology(),
    humanPlayerId,
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: boundaryKey,
          child: SizedBox(
            width: 460,
            height: 900,
            child: ProvinceSeaZoneDetailOverlay(
              game: game,
              region: region,
              displayId: displayId,
              selectedTileKey: selectedTileKey,
              humanPlayerId: humanPlayerId,
              playerView: playerView,
              draftOrders: const Orders(),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Region clone with one cell's visibility overridden (mirrors the helper in
/// `province_overlay_obfuscated_body_dark_tokens_test.dart`).
RegionMapViewData _regionWith({
  required TileVisibility Function(CellViewData) visibilityForCell,
}) {
  final base = demoRegionForOverlay;
  final cells = base.cells
      .map(
        (c) => CellViewData(
          x: c.x,
          y: c.y,
          regionCellId: c.regionCellId,
          isSea: c.isSea,
          terrainTypeId: c.terrainTypeId,
          terrainType: c.terrainType,
          resourceId: c.resourceId,
          ownerFactionId: c.ownerFactionId,
          provinceDisplayName: c.provinceDisplayName,
          improvementLevel: c.improvementLevel,
          roadLevel: c.roadLevel,
          visibility: visibilityForCell(c),
        ),
      )
      .toList();
  return RegionMapViewData(
    regionId: base.regionId,
    width: base.width,
    height: base.height,
    cellSize: base.cellSize,
    cells: cells,
    capitalMarkers: base.capitalMarkers,
    portMarkers: base.portMarkers,
    factionColors: base.factionColors,
    greatPowerFactionIds: base.greatPowerFactionIds,
    terrainColors: base.terrainColors,
    unitMarkers: base.unitMarkers,
  );
}

List<String> _tileTextDataInOrder(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .toList(growable: false);
}

void main() {
  suppressLogsForTests();

  final l10n = lookupAppLocalizations(const Locale('en'));
  final provinceId = sampleProvinceIdForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;

  group('provinceOverlayTileDesignationLine (Refs #3617 — logic)', () {
    test('capital tile yields the localized capital line (AC capital)', () {
      final game = _withFirstPlayerCapitalTile(demoGameForOverlay, tileKey);
      final provinceName = _provinceDisplayName(game, provinceId);
      final factionName = game.players.first.displayName;

      final line = provinceOverlayTileDesignationLine(
        l10n: l10n,
        game: game,
        provinceId: provinceId,
        selectedTileKey: tileKey,
      );

      expect(
        line,
        l10n.provinceOverlay_tileCapitalOf(provinceName, factionName),
      );
      expect(line, '$provinceName, the capital of $factionName');
    });

    test('capital takes priority when the tile is also the province town '
        '(AC capital-only when both apply)', () {
      var game = _withFirstPlayerCapitalTile(demoGameForOverlay, tileKey);
      game = _withProvinceTownTile(game, provinceId, tileKey);
      final provinceName = _provinceDisplayName(game, provinceId);
      final factionName = game.players.first.displayName;

      final line = provinceOverlayTileDesignationLine(
        l10n: l10n,
        game: game,
        provinceId: provinceId,
        selectedTileKey: tileKey,
      );

      expect(
        line,
        l10n.provinceOverlay_tileCapitalOf(provinceName, factionName),
      );
      expect(line, isNot(contains('The town of')));
    });

    test(
      'town tile (not a capital) yields the localized town line (AC town)',
      () {
        var game = _withoutMatchingCapitals(demoGameForOverlay);
        game = _withProvinceTownTile(game, provinceId, tileKey);
        final provinceName = _provinceDisplayName(game, provinceId);

        final line = provinceOverlayTileDesignationLine(
          l10n: l10n,
          game: game,
          provinceId: provinceId,
          selectedTileKey: tileKey,
        );

        expect(line, l10n.provinceOverlay_tileTownOf(provinceName));
        expect(line, 'The town of $provinceName');
      },
    );

    test('ordinary land tile (neither town nor capital) yields null '
        '(AC no designation)', () {
      var game = _withoutMatchingCapitals(demoGameForOverlay);
      // Point the province town somewhere other than the tile under test.
      game = _withProvinceTownTile(
        game,
        provinceId,
        'oldWorld|__sentinel_town__|8881|8882',
      );

      final line = provinceOverlayTileDesignationLine(
        l10n: l10n,
        game: game,
        provinceId: provinceId,
        selectedTileKey: tileKey,
      );

      expect(line, isNull);
    });

    test('minor-nation capital tile resolves the minor display name', () {
      final base = demoGameForOverlay;
      if (base.minorNations.isEmpty) {
        return; // No minor in the demo fixture; nothing to assert.
      }
      // Clear any player/tribe capital that already coincides with the tile so
      // the minor-nation branch is the matching faction.
      final cleared = _withoutMatchingCapitals(base);
      final cap = _capitalTileFromKey(tileKey);
      final minors = <MinorNation>[
        cleared.minorNations.first.copyWith(capitalTile: cap),
        ...cleared.minorNations.skip(1),
      ];
      final game = cleared.copyWith(minorNations: minors);
      final provinceName = _provinceDisplayName(game, provinceId);
      final expectedName =
          game.minorNations.first.displayName ?? game.minorNations.first.id;

      final line = provinceOverlayTileDesignationLine(
        l10n: l10n,
        game: game,
        provinceId: provinceId,
        selectedTileKey: tileKey,
      );

      expect(
        line,
        l10n.provinceOverlay_tileCapitalOf(provinceName, expectedName),
      );
    });
  });

  group(
    'ProvinceSeaZoneDetailOverlay Tile designation rendering (Refs #3617)',
    () {
      testWidgets('capital line renders between Terrain and Resource in fg '
          '(AC capital designation line)', (WidgetTester tester) async {
        final game = _withFirstPlayerCapitalTile(demoGameForOverlay, tileKey);
        final provinceName = _provinceDisplayName(game, provinceId);
        final expected = l10n.provinceOverlay_tileCapitalOf(
          provinceName,
          game.players.first.displayName,
        );

        await tester.pumpWidget(
          _darkOverlay(
            game: game,
            region: demoRegionForOverlay,
            displayId: provinceId,
            selectedTileKey: tileKey,
          ),
        );
        await tester.pumpAndSettle();

        final finder = find.text(expected);
        expect(finder, findsOneWidget);
        final Text row = tester.widget<Text>(finder);
        expect(
          row.style?.color,
          EditorialMonoclePalette.fg,
          reason:
              'Designation line must resolve to EditorialMonoclePalette.fg '
              'per SPEC § Tile town / capital designation.',
        );

        // Placement: after Terrain, before Resource.
        final order = _tileTextDataInOrder(tester);
        final terrainIdx = order.indexWhere((d) => d.startsWith('Terrain: '));
        final designationIdx = order.indexOf(expected);
        final resourceIdx = order.indexWhere((d) => d.startsWith('Resource: '));
        expect(terrainIdx, greaterThanOrEqualTo(0));
        expect(resourceIdx, greaterThan(terrainIdx));
        expect(designationIdx, greaterThan(terrainIdx));
        expect(designationIdx, lessThan(resourceIdx));
      });

      testWidgets('town line renders for the province town tile '
          '(AC town designation line)', (WidgetTester tester) async {
        var game = _withoutMatchingCapitals(demoGameForOverlay);
        game = _withProvinceTownTile(game, provinceId, tileKey);
        final provinceName = _provinceDisplayName(game, provinceId);
        final expected = l10n.provinceOverlay_tileTownOf(provinceName);

        await tester.pumpWidget(
          _darkOverlay(
            game: game,
            region: demoRegionForOverlay,
            displayId: provinceId,
            selectedTileKey: tileKey,
          ),
        );
        await tester.pumpAndSettle();

        final finder = find.text(expected);
        expect(finder, findsOneWidget);
        final Text row = tester.widget<Text>(finder);
        expect(row.style?.color, EditorialMonoclePalette.fg);
      });

      testWidgets('ordinary land tile renders no designation line '
          '(AC no designation)', (WidgetTester tester) async {
        var game = _withoutMatchingCapitals(demoGameForOverlay);
        game = _withProvinceTownTile(
          game,
          provinceId,
          'oldWorld|__sentinel_town__|8881|8882',
        );

        await tester.pumpWidget(
          _darkOverlay(
            game: game,
            region: demoRegionForOverlay,
            displayId: provinceId,
            selectedTileKey: tileKey,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('the capital of'), findsNothing);
        expect(find.textContaining('The town of'), findsNothing);
      });

      testWidgets('unrevealed selected tile renders no designation line '
          '(AC suppressed for unrevealed)', (WidgetTester tester) async {
        // Force the selected tile (which we also make a capital) unrevealed so
        // the obfuscated Tile branch fires and the designation is suppressed.
        final game = _withFirstPlayerCapitalTile(demoGameForOverlay, tileKey);
        final parts = tileKey.split('|');
        final tx = int.parse(parts[parts.length - 2]);
        final ty = int.parse(parts.last);
        final region = _regionWith(
          visibilityForCell: (c) =>
              c.x == tx && c.y == ty ? TileVisibility.unrevealed : c.visibility,
        );

        await tester.pumpWidget(
          _darkOverlay(
            game: game,
            region: region,
            displayId: provinceId,
            selectedTileKey: tileKey,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('the capital of'), findsNothing);
        expect(find.text('Terrain: ???'), findsOneWidget);
      });
    },
  );

  group(
    'ProvinceSeaZoneDetailOverlay Tile designation goldens (Refs #3617)',
    () {
      testWidgets(
        'capital designation line golden (AC capital designation line)',
        (WidgetTester tester) async {
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.binding.setSurfaceSize(const Size(600, 1000));
          const boundaryKey = ValueKey<String>(
            'province_overlay_tile_capital_designation_golden',
          );

          final game = _withFirstPlayerCapitalTile(demoGameForOverlay, tileKey);
          final provinceName = _provinceDisplayName(game, provinceId);
          final expected = l10n.provinceOverlay_tileCapitalOf(
            provinceName,
            game.players.first.displayName,
          );

          await tester.pumpWidget(
            _goldenOverlay(
              game: game,
              region: demoRegionForOverlay,
              displayId: provinceId,
              selectedTileKey: tileKey,
              boundaryKey: boundaryKey,
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(expected), findsOneWidget);

          await expectLater(
            find.byKey(boundaryKey),
            matchesGoldenFile(
              'goldens/province_overlay_tile_capital_designation.png',
            ),
          );
        },
      );

      testWidgets('town designation line golden (AC town designation line)', (
        WidgetTester tester,
      ) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(600, 1000));
        const boundaryKey = ValueKey<String>(
          'province_overlay_tile_town_designation_golden',
        );

        var game = _withoutMatchingCapitals(demoGameForOverlay);
        game = _withProvinceTownTile(game, provinceId, tileKey);
        final provinceName = _provinceDisplayName(game, provinceId);
        final expected = l10n.provinceOverlay_tileTownOf(provinceName);

        await tester.pumpWidget(
          _goldenOverlay(
            game: game,
            region: demoRegionForOverlay,
            displayId: provinceId,
            selectedTileKey: tileKey,
            boundaryKey: boundaryKey,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(expected), findsOneWidget);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile(
            'goldens/province_overlay_tile_town_designation.png',
          ),
        );
      });
    },
  );
}
