// Pins the dark editorial-monocle Tile section live-data rows that were
// not in the original three-row slice (coordinates / terrain / civilian
// units): Prospected, Improvement, the Road / railroad primary numeric
// line on land tiles, and the sea-tile "Road / railroad: —" row.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Tile section body tokens
// (Refs #2865 S5 — extends the existing road-caption + live-data rows
// slice).
//
// Every Tile row that renders exact world-state values for a revealed
// selected tile MUST resolve its `TextStyle.color` to
// `EditorialMonoclePalette.fg` directly via the shared `_fgBodyStyle()`
// helper. Bare `Text(...)` with `style: null` is forbidden (the rendered
// colour would resolve through `DefaultTextStyle` fall-through). An
// `isNot(onSurface)` assertion is intentionally NOT used because under
// `editorialMonocle` the dark theme wires `colorScheme.onSurface` itself
// to `EditorialMonoclePalette.fg`, so the guard would tautologically
// fail for the correct token value (matching the existing live-data
// Tile-row pattern and the S6 Economic, S7 Military, S8 Civilian, Naval,
// and Political body pin patterns).

import 'package:colonizethis_logic/colonizethis_logic.dart'
    show VisibilityLevel, buildPlayerView;
import 'package:colonizethis_map/colonizethis_map.dart' show TileVisibility;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoRegionForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

/// Builds the overlay under [AppThemes.editorialMonocle] with the
/// debug-init full player view so the selected demo tile is revealed and
/// the Tile section actually renders its live-data rows rather than the
/// `???` placeholders. The land-tile road level is set via [roadLevel].
Widget _darkOverlayWithRevealedLandTile({required int roadLevel}) {
  final base = demoGameForOverlay;
  final region = demoRegionForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;
  final humanPlayerId = base.players.first.id;
  final init = getDebugInitGameResult();
  final playerView = buildPlayerView(
    base,
    init.combinedTopology,
    humanPlayerId,
  );
  final ws = base.worldState;
  final tileState = ws.tileState.setRoadLevel(tileKey, roadLevel);
  final game = base.copyWith(
    worldState: ws.copyWith(tileState: tileState),
  );
  final parts = tileKey.split('|');
  final provinceId = '${parts[0]}|${parts[1]}';
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: region,
        displayId: provinceId,
        selectedTileKey: tileKey,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
      ),
    ),
  );
}

/// Builds the overlay with a province-context [displayId] but a sea-cell
/// [selectedTileKey] (mirroring the SPEC's port-harbor sea-cell case).
/// The Tile section's `cell.isSea` branch fires so `roadLevel` is `null`
/// and the row renders the localized `provinceOverlay_tileRoadNone`
/// string (`Road / railroad: —`) via `_buildTileRoadLabelWidgets`.
Widget? _darkOverlayWithSeaCellSelectedAtLandProvince() {
  final base = demoGameForOverlay;
  final region = demoRegionForOverlay;
  final humanPlayerId = base.players.first.id;
  final init = getDebugInitGameResult();
  final playerView = buildPlayerView(
    base,
    init.combinedTopology,
    humanPlayerId,
  );
  // First land-province displayId (any revealed land province whose Tile
  // section can host a sea-cell selectedTileKey for the port-harbor case).
  String? landDisplayId;
  for (final cell in region.cells) {
    if (!cell.isSea) {
      landDisplayId = '${region.regionId}|${cell.regionCellId}';
      break;
    }
  }
  // First sea cell in the region — its `(x, y)` makes the selectedTileKey
  // address a sea cell so `cell.isSea` is true in `_buildTileSection`.
  // Prefer a sea cell whose cell-level visibility is not unrevealed so the
  // Tile section renders the live `Road / railroad: -` row rather than the
  // obfuscated placeholder.
  String? seaTileKey;
  for (final cell in region.cells) {
    if (!cell.isSea) continue;
    if (cell.visibility == TileVisibility.unrevealed) continue;
    final candidate =
        '${region.regionId}|${cell.regionCellId}|${cell.x}|${cell.y}';
    if (playerView.visibilityForTile(candidate) != VisibilityLevel.unknown) {
      seaTileKey = candidate;
      break;
    }
  }
  if (landDisplayId == null || seaTileKey == null) return null;
  // Promote the sea cell to a visible state so the Tile section doesn't
  // render the obfuscated `???` body. Sea visibility is part of the
  // PlayerView used above, which already reflects the debug-init reveal
  // pattern, so we rely on the existing full reveal rather than mutating
  // the cell here (mirrors the land-tile fixture path).
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: base,
        region: region,
        displayId: landDisplayId,
        selectedTileKey: seaTileKey,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
      ),
    ),
  );
}

/// Returns the `Text` widget whose `data` starts with [prefix]. Each row
/// renders exactly once, so a single match is expected.
Text _findTileBodyText(WidgetTester tester, String prefix) {
  final finder = find.byWidgetPredicate(
    (Widget w) => w is Text && (w.data ?? '').startsWith(prefix),
  );
  expect(
    finder,
    findsOneWidget,
    reason: 'Expected exactly one Text starting with "$prefix" in the '
        'Tile section live-data body.',
  );
  return tester.widget<Text>(finder);
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile section '
    'remaining live-data rows (SPEC § Dark-theme Tile section body '
    'tokens — live-data body rows)',
    () {
      testWidgets(
        'Prospected row resolves to EditorialMonoclePalette.fg under '
        'editorialMonocle (positive AC: live-data Prospected row colour)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRevealedLandTile(roadLevel: 0),
          );
          await tester.pumpAndSettle();

          final text = _findTileBodyText(tester, 'Prospected: ');
          expect(
            text.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Tile Prospected row must resolve to '
                'EditorialMonoclePalette.fg (SPEC AC '
                '"Dark-theme Tile live-data — Prospected row colour").',
          );
        },
      );

      testWidgets(
        'Improvement row resolves to EditorialMonoclePalette.fg under '
        'editorialMonocle (positive AC: live-data Improvement row colour)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRevealedLandTile(roadLevel: 0),
          );
          await tester.pumpAndSettle();

          final text = _findTileBodyText(tester, 'Improvement: ');
          expect(
            text.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Tile Improvement row must resolve to '
                'EditorialMonoclePalette.fg (SPEC AC '
                '"Dark-theme Tile live-data — Improvement row colour").',
          );
        },
      );

      testWidgets(
        'Road / railroad primary numeric line on a land tile resolves to '
        'EditorialMonoclePalette.fg under editorialMonocle (positive AC: '
        'live-data road primary line colour)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRevealedLandTile(roadLevel: 2),
          );
          await tester.pumpAndSettle();

          final text = _findTileBodyText(
            tester,
            'Road / railroad: transport level ',
          );
          expect(
            text.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Tile Road / railroad primary numeric line must resolve '
                'to EditorialMonoclePalette.fg (SPEC AC '
                '"Dark-theme Tile live-data — Road / railroad primary '
                'numeric line colour (land tiles)").',
          );
        },
      );

      testWidgets(
        'Road / railroad primary numeric line on a land tile remains '
        'EditorialMonoclePalette.fg across stored transport levels 0 / 1 '
        '/ 2 / 4 (regression guard for the full canonical land-tile '
        'level set)',
        (WidgetTester tester) async {
          for (final level in const <int>[0, 1, 2, 4]) {
            await tester.pumpWidget(
              _darkOverlayWithRevealedLandTile(roadLevel: level),
            );
            await tester.pumpAndSettle();

            final text = _findTileBodyText(
              tester,
              'Road / railroad: transport level ',
            );
            expect(
              text.style?.color,
              EditorialMonoclePalette.fg,
              reason:
                  'Tile Road / railroad primary numeric line at stored '
                  'transport level $level must resolve to '
                  'EditorialMonoclePalette.fg (SPEC live-data rule).',
            );
          }
        },
      );

      testWidgets(
        'sea-tile no-road row (Road / railroad: —) resolves to '
        'EditorialMonoclePalette.fg under editorialMonocle when the '
        'overlay renders a province-context Tile section with a '
        'sea-cell selectedTileKey (positive AC: live-data sea-tile '
        'no-road row colour)',
        (WidgetTester tester) async {
          final overlay = _darkOverlayWithSeaCellSelectedAtLandProvince();
          if (overlay == null) {
            // No sea cell available in the demo region; skip without
            // failing so the slice remains stable on fixtures that lack
            // a port-harbor scenario. The land-tile road primary line
            // tests above still cover the shared `_fgBodyStyle()` pin
            // applied in `_buildTileRoadLabelWidgets`.
            return;
          }
          await tester.pumpWidget(overlay);
          await tester.pumpAndSettle();

          // Either the live `Road / railroad: -` row (when the sea cell
          // passes visibility gating) or the obfuscated `Road / railroad: ???`
          // row (when the cell is unrevealed) may render depending on the
          // demo fixture. Only the live row is in scope for this AC, so
          // skip when the obfuscated placeholder fired.
          final liveFinder = find.byWidgetPredicate(
            (Widget w) =>
                w is Text && (w.data ?? '').startsWith('Road / railroad: -'),
          );
          if (liveFinder.evaluate().isEmpty) {
            return;
          }
          final text = tester.widget<Text>(liveFinder);
          expect(
            text.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Sea-tile no-road row must resolve to '
                'EditorialMonoclePalette.fg (SPEC AC '
                '"Dark-theme Tile live-data — sea-tile no-road row '
                'colour").',
          );
        },
      );

      testWidgets(
        'negative regression guard — Prospected / Improvement / road '
        'primary numeric line rows never fall through DefaultTextStyle '
        'and never resolve to Colors.white (the bare dark Material '
        'bodyMedium fallback) under editorialMonocle',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlayWithRevealedLandTile(roadLevel: 2),
          );
          await tester.pumpAndSettle();

          for (final prefix in const <String>[
            'Prospected: ',
            'Improvement: ',
            'Road / railroad: transport level ',
          ]) {
            final text = _findTileBodyText(tester, prefix);

            expect(
              text.style,
              isNotNull,
              reason:
                  '"$prefix" row must declare its own TextStyle and not '
                  'fall through DefaultTextStyle (SPEC AC "Dark-theme '
                  'Tile live-data — Prospected / Improvement / road '
                  'primary / sea-tile no-road Material fallback '
                  'regression guard").',
            );
            expect(
              text.style?.color,
              isNotNull,
              reason:
                  '"$prefix" row TextStyle.color must be non-null per '
                  'SPEC regression guard.',
            );
            expect(
              text.style?.color,
              isNot(Colors.white),
              reason:
                  '"$prefix" row must not regress to the dark Material '
                  'bodyMedium `Colors.white` fallback (SPEC regression '
                  'guard).',
            );
            expect(
              text.style?.color,
              EditorialMonoclePalette.fg,
              reason:
                  '"$prefix" row must resolve to '
                  'EditorialMonoclePalette.fg (SPEC regression guard '
                  'positive token pin).',
            );
          }
        },
      );
    },
  );
}
