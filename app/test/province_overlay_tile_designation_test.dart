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
//
// Shared pumps / designation tables densify residual mid-500 cases (Refs #4021).

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'support/app_shell_harness.dart';
import 'support/province_overlay_test_harness.dart';

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

/// Golden harness host: wraps the overlay in a keyed `RepaintBoundary` at a
/// fixed size so the Tile-section designation line is pinned as a pixel
/// baseline (mirrors `diplomacy_panel_goldens_test.dart`). Uses
/// [buildAppShell] for the dark-theme chrome (Refs #4035).
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
  final playerView = buildPlayerView(game, const MapTopology(), humanPlayerId);
  return buildAppShell(
    child: Scaffold(
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

Future<void> _pumpOverlay(
  WidgetTester tester, {
  required Game game,
  required String provinceId,
  required String tileKey,
  RegionMapViewData? region,
}) async {
  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      region: region ?? demoRegionForOverlay,
      displayId: provinceId,
      selectedTileKey: tileKey,
      playerView: demoOverlayPlayerView(game),
      draftOrders: const Orders(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  suppressLogsForTests();

  final l10n = lookupAppLocalizations(const Locale('en'));
  final provinceId = sampleProvinceIdForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;

  group('provinceOverlayTileDesignationLine (Refs #3617 — logic)', () {
    for (final c
        in <
          ({
            String name,
            Game Function() game,
            String? Function(Game) want,
            Matcher? also,
          })
        >[
          (
            name: 'capital tile yields the localized capital line (AC capital)',
            game: () =>
                _withFirstPlayerCapitalTile(demoGameForOverlay, tileKey),
            want: (g) => l10n.provinceOverlay_tileCapitalOf(
              _provinceDisplayName(g, provinceId),
              g.players.first.displayName,
            ),
            also: null,
          ),
          (
            name:
                'capital takes priority when the tile is also the province town '
                '(AC capital-only when both apply)',
            game: () {
              var g = _withFirstPlayerCapitalTile(demoGameForOverlay, tileKey);
              return _withProvinceTownTile(g, provinceId, tileKey);
            },
            want: (g) => l10n.provinceOverlay_tileCapitalOf(
              _provinceDisplayName(g, provinceId),
              g.players.first.displayName,
            ),
            also: isNot(contains('The town of')),
          ),
          (
            name:
                'town tile (not a capital) yields the localized town line (AC town)',
            game: () {
              var g = _withoutMatchingCapitals(demoGameForOverlay);
              return _withProvinceTownTile(g, provinceId, tileKey);
            },
            want: (g) => l10n.provinceOverlay_tileTownOf(
              _provinceDisplayName(g, provinceId),
            ),
            also: null,
          ),
          (
            name:
                'ordinary land tile (neither town nor capital) yields null '
                '(AC no designation)',
            game: () {
              var g = _withoutMatchingCapitals(demoGameForOverlay);
              return _withProvinceTownTile(
                g,
                provinceId,
                'oldWorld|__sentinel_town__|8881|8882',
              );
            },
            want: (_) => null,
            also: null,
          ),
        ]) {
      test(c.name, () {
        final game = c.game();
        final line = provinceOverlayTileDesignationLine(
          l10n: l10n,
          game: game,
          provinceId: provinceId,
          selectedTileKey: tileKey,
        );
        expect(line, c.want(game));
        if (c.also != null && line != null) {
          expect(line, c.also);
        }
      });
    }

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
        final expected = l10n.provinceOverlay_tileCapitalOf(
          _provinceDisplayName(game, provinceId),
          game.players.first.displayName,
        );

        await _pumpOverlay(
          tester,
          game: game,
          provinceId: provinceId,
          tileKey: tileKey,
        );

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

      for (final c
          in <
            ({
              String name,
              Game Function() game,
              void Function(WidgetTester, Game) assertUi,
            })
          >[
            (
              name:
                  'town line renders for the province town tile '
                  '(AC town designation line)',
              game: () {
                var g = _withoutMatchingCapitals(demoGameForOverlay);
                return _withProvinceTownTile(g, provinceId, tileKey);
              },
              assertUi: (tester, g) {
                final expected = l10n.provinceOverlay_tileTownOf(
                  _provinceDisplayName(g, provinceId),
                );
                final finder = find.text(expected);
                expect(finder, findsOneWidget);
                expect(
                  tester.widget<Text>(finder).style?.color,
                  EditorialMonoclePalette.fg,
                );
              },
            ),
            (
              name:
                  'ordinary land tile renders no designation line '
                  '(AC no designation)',
              game: () {
                var g = _withoutMatchingCapitals(demoGameForOverlay);
                return _withProvinceTownTile(
                  g,
                  provinceId,
                  'oldWorld|__sentinel_town__|8881|8882',
                );
              },
              assertUi: (tester, _) {
                expect(find.textContaining('the capital of'), findsNothing);
                expect(find.textContaining('The town of'), findsNothing);
              },
            ),
          ]) {
        testWidgets(c.name, (WidgetTester tester) async {
          final game = c.game();
          await _pumpOverlay(
            tester,
            game: game,
            provinceId: provinceId,
            tileKey: tileKey,
          );
          c.assertUi(tester, game);
        });
      }

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

        await _pumpOverlay(
          tester,
          game: game,
          provinceId: provinceId,
          tileKey: tileKey,
          region: region,
        );

        expect(find.textContaining('the capital of'), findsNothing);
        expect(find.text('Terrain: ???'), findsOneWidget);
      });
    },
  );

  group('ProvinceSeaZoneDetailOverlay Tile designation goldens (Refs #3617)', () {
    for (final c
        in <
          ({
            String name,
            String key,
            String golden,
            Game Function() game,
            String Function(Game) expectedText,
          })
        >[
          (
            name:
                'capital designation line golden (AC capital designation line)',
            key: 'province_overlay_tile_capital_designation_golden',
            golden: 'goldens/province_overlay_tile_capital_designation.png',
            game: () =>
                _withFirstPlayerCapitalTile(demoGameForOverlay, tileKey),
            expectedText: (g) => l10n.provinceOverlay_tileCapitalOf(
              _provinceDisplayName(g, provinceId),
              g.players.first.displayName,
            ),
          ),
          (
            name: 'town designation line golden (AC town designation line)',
            key: 'province_overlay_tile_town_designation_golden',
            golden: 'goldens/province_overlay_tile_town_designation.png',
            game: () {
              var g = _withoutMatchingCapitals(demoGameForOverlay);
              return _withProvinceTownTile(g, provinceId, tileKey);
            },
            expectedText: (g) => l10n.provinceOverlay_tileTownOf(
              _provinceDisplayName(g, provinceId),
            ),
          ),
        ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(600, 1000));
        final boundaryKey = ValueKey<String>(c.key);
        final game = c.game();

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

        expect(find.text(c.expectedText(game)), findsOneWidget);

        await expectLater(find.byKey(boundaryKey), matchesGoldenFile(c.golden));
      });
    }
  });
}
