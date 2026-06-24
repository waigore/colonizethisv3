// Pins the dark editorial-monocle Tile section live-data body rows for
// ProvinceSeaZoneDetailOverlay (Refs #2865 S5 — extends the existing
// road-caption + disabled-icons slice).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Tile section body tokens.
//
// The three bare Tile rows that render exact world-state values for a
// revealed selected tile — coordinates, terrain, civilian-units count —
// MUST resolve their `TextStyle.color` to `EditorialMonoclePalette.fg`
// directly, mirroring the Political "Name" / "Owner" body rows. The same
// rows MUST NOT be authored as bare `Text(...)` with `style: null` (so
// the rendered colour resolves through `DefaultTextStyle` fall-through),
// MUST NOT fall back to the bare dark Material `bodyMedium` colour
// (`Colors.white`), and MUST NOT consume any other Material colour-scheme
// lookup. An `isNot(onSurface)` assertion is intentionally NOT used here
// because under `editorialMonocle` the dark theme wires
// `colorScheme.onSurface` itself to `EditorialMonoclePalette.fg`, so the
// guard would tautologically fail for the correct token value (matching
// the S6 Economic, S7 Military, S8 Civilian, Naval, and Political body
// pin patterns).

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
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

/// Builds the overlay under [AppThemes.editorialMonocle] with the
/// debug-init full player view so the selected demo tile is revealed and
/// the Tile section actually renders its live-data rows (coordinates /
/// terrain / civilian-units) rather than the `???` placeholders.
///
/// Mirrors `_darkOverlayWithRoadLevelFullPlayerView` in
/// `province_overlay_tile_section_dark_tokens_test.dart` — uses the full
/// player view rather than the demo fixture so the land tile passes
/// visibility gating.
Widget _darkOverlayWithRevealedTile() {
  final base = demoGameForOverlay;
  final region = demoRegionForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;
  final humanPlayerId = base.players.first.id;
  // Refs #3656: buildPlayerView ignores its topology argument, so an empty
  // const MapTopology() replaces the ~11s getDebugInitGameResult() map
  // generation with identical PlayerView output for this demo game.
  final playerView = buildPlayerView(
    base,
    const MapTopology(),
    humanPlayerId,
  );
  final parts = tileKey.split('|');
  final provinceId = '${parts[0]}|${parts[1]}';
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: base,
        region: region,
        displayId: provinceId,
        selectedTileKey: tileKey,
        humanPlayerId: humanPlayerId,
        playerView: playerView,
      ),
    ),
  );
}

/// Returns the `Text` widget whose `data` starts with [prefix] (e.g.
/// `Coordinates: `, `Terrain: `, `Civilian units (province): `). The Tile
/// section renders each live-data row exactly once, so a single match is
/// expected.
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
    'live-data body rows (SPEC § Dark-theme Tile section body tokens — '
    'live-data body rows)',
    () {
      testWidgets(
        'coordinates row resolves to EditorialMonoclePalette.fg under '
        'editorialMonocle (positive AC: live-data coordinates row colour)',
        (WidgetTester tester) async {
          await tester.pumpWidget(_darkOverlayWithRevealedTile());
          await tester.pumpAndSettle();

          final text = _findTileBodyText(tester, 'Coordinates: ');
          expect(
            text.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Tile coordinates row must resolve to '
                'EditorialMonoclePalette.fg (SPEC AC '
                '"Dark-theme Tile live-data — coordinates row colour").',
          );
        },
      );

      testWidgets(
        'terrain row resolves to EditorialMonoclePalette.fg under '
        'editorialMonocle (positive AC: live-data terrain row colour)',
        (WidgetTester tester) async {
          await tester.pumpWidget(_darkOverlayWithRevealedTile());
          await tester.pumpAndSettle();

          final text = _findTileBodyText(tester, 'Terrain: ');
          expect(
            text.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Tile terrain row must resolve to '
                'EditorialMonoclePalette.fg (SPEC AC '
                '"Dark-theme Tile live-data — terrain row colour").',
          );
        },
      );

      testWidgets(
        'civilian-units row resolves to EditorialMonoclePalette.fg under '
        'editorialMonocle (positive AC: live-data civilian-units row '
        'colour)',
        (WidgetTester tester) async {
          await tester.pumpWidget(_darkOverlayWithRevealedTile());
          await tester.pumpAndSettle();

          final text = _findTileBodyText(
            tester,
            'Civilian units (province): ',
          );
          expect(
            text.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Tile civilian-units row must resolve to '
                'EditorialMonoclePalette.fg (SPEC AC '
                '"Dark-theme Tile live-data — civilian-units row '
                'colour").',
          );
        },
      );

      testWidgets(
        'negative regression guard — coordinates / terrain / civilian-units '
        'rows never fall through DefaultTextStyle and never resolve to '
        'Colors.white (the bare dark Material bodyMedium fallback) under '
        'editorialMonocle',
        (WidgetTester tester) async {
          await tester.pumpWidget(_darkOverlayWithRevealedTile());
          await tester.pumpAndSettle();

          for (final prefix in const <String>[
            'Coordinates: ',
            'Terrain: ',
            'Civilian units (province): ',
          ]) {
            final text = _findTileBodyText(tester, prefix);

            // (a) style must not be null and color must not be null —
            // bare `Text(...)` with `style: null` is forbidden by SPEC.
            expect(
              text.style,
              isNotNull,
              reason:
                  '"$prefix" row must declare its own TextStyle and not '
                  'fall through DefaultTextStyle (SPEC AC "Dark-theme '
                  'Tile live-data — Material fallback regression guard").',
            );
            expect(
              text.style?.color,
              isNotNull,
              reason:
                  '"$prefix" row TextStyle.color must be non-null per '
                  'SPEC regression guard.',
            );

            // (b) color must not be the bare dark Material bodyMedium
            // fallback (`Colors.white`) that would surface if a future
            // refactor stripped the explicit `_fgBodyStyle()`.
            expect(
              text.style?.color,
              isNot(Colors.white),
              reason:
                  '"$prefix" row must not regress to the dark Material '
                  'bodyMedium `Colors.white` fallback (SPEC regression '
                  'guard).',
            );

            // (c) positive pin to the canonical fg token (the explicit
            // single source per SPEC).
            expect(
              text.style?.color,
              EditorialMonoclePalette.fg,
              reason:
                  '"$prefix" row must resolve to '
                  'EditorialMonoclePalette.fg (SPEC AC "Dark-theme Tile '
                  'live-data — Material fallback regression guard, '
                  'positive token pin").',
            );
          }
        },
      );
    },
  );
}
