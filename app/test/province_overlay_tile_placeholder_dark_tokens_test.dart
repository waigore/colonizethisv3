// Pins the dark editorial-monocle Tile-section placeholder body tokens
// for ProvinceSeaZoneDetailOverlay (S5 follow-up — Tile empty / unparsed).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation —
//   Dark-theme Tile section placeholder body tokens (S5 follow-up).
//
// Unlike the four intel-gated sections owned by the S9 empty-state slice,
// the Tile section renders two placeholder bodies that are not driven by
// intel gating:
//
//  * the no-selection guidance prompt (`provinceOverlay_clickTileForDetails`,
//    "Click a tile to see details.") rendered when `selectedTileKey == null`,
//  * the degenerate em-dash placeholder (`Text('—')`) rendered when a
//    `selectedTileKey` is set but cannot be parsed into in-region tile
//    coordinates (`tryParseProvinceOverlayTileCoords` returns null).
//
// Both are placeholder copy, not live world-state data, so under
// `AppThemes.editorialMonocle` each MUST resolve `TextStyle.color` to
// `EditorialMonoclePalette.muted` (the guidance prompt inline, the
// em-dash via the shared `_emptyBodyDashText()` helper). Material defaults
// (`Theme.of(context).colorScheme.onSurface`, the dark `Colors.white`
// fallback, or a `style: null` `DefaultTextStyle` fall-through) MUST NOT
// colour either placeholder.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

import 'support/province_overlay_test_harness.dart';

/// Mounts the overlay under the editorial-monocle dark theme for [displayId]
/// and [selectedTileKey].

/// Resolves the rendered Tile-section body `Text` whose `data == [data]` by
/// scoping the search to the `_buildSection('Tile', ...)` Column (the nearest
/// `Column` ancestor of the Tile `CtSectionLabel`). This isolates the Tile
/// placeholder from any incidental `—` placeholders other sections may emit.
Text _tileSectionBodyText(WidgetTester tester, String data) {
  final tileLabel = find.byWidgetPredicate(
    (w) => w is CtSectionLabel && w.text == 'Tile',
  );
  expect(
    tileLabel,
    findsOneWidget,
    reason:
        'Test setup: the Tile section must render its CtSectionLabel header '
        'so the placeholder body can be scoped to that section.',
  );
  final tileSectionColumn = find
      .ancestor(of: tileLabel, matching: find.byType(Column))
      .first;
  final bodyFinder = find.descendant(
    of: tileSectionColumn,
    matching: find.text(data),
  );
  expect(
    bodyFinder,
    findsOneWidget,
    reason:
        'Test setup: the Tile section body must render exactly one '
        '`Text("$data")` placeholder.',
  );
  return tester.widget<Text>(bodyFinder);
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile placeholder '
    'body (SPEC § Dark-theme Tile section placeholder body tokens — '
    'S5 follow-up)',
    () {
      testWidgets(
        'no-selection guidance prompt resolves to '
        'EditorialMonoclePalette.muted',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: game.players.first.id,
          );
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: ownedProvince,
              selectedTileKey: null,
            ),
          );
          await tester.pumpAndSettle();

          final prompt = _tileSectionBodyText(
            tester,
            'Click a tile to see details.',
          );
          expect(
            prompt.style?.color,
            EditorialMonoclePalette.muted,
            reason:
                'The Tile no-selection guidance prompt must resolve '
                'TextStyle.color to EditorialMonoclePalette.muted per '
                'SPEC § Dark-theme Tile section placeholder body tokens '
                '(S5 follow-up).',
          );
        },
      );

      testWidgets(
        'degenerate (unparsed key) em-dash placeholder resolves to '
        'EditorialMonoclePalette.muted',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: game.players.first.id,
          );
          // A non-null key carrying the correct region prefix but only a
          // single `|` segment fails `tryParseProvinceOverlayTileCoords`
          // (no x|y tail), driving the Tile section's `coords == null`
          // degenerate em-dash branch.
          final degenerateKey = '${demoRegionForOverlay.regionId}|unparsed';

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: ownedProvince,
              selectedTileKey: degenerateKey,
            ),
          );
          await tester.pumpAndSettle();

          final dash = _tileSectionBodyText(tester, '—');
          expect(
            dash.style?.color,
            EditorialMonoclePalette.muted,
            reason:
                'The Tile degenerate em-dash placeholder must resolve '
                'TextStyle.color to EditorialMonoclePalette.muted via the '
                'shared `_emptyBodyDashText()` helper per SPEC § Dark-theme '
                'Tile section placeholder body tokens (S5 follow-up).',
          );
        },
      );

      testWidgets(
        'negative: both Tile placeholders declare their own '
        'TextStyle.color and are neither Colors.white nor the dark '
        'Material onSurface fallback',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: game.players.first.id,
          );

          // No-selection guidance prompt.
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: ownedProvince,
              selectedTileKey: null,
            ),
          );
          await tester.pumpAndSettle();
          final prompt = _tileSectionBodyText(
            tester,
            'Click a tile to see details.',
          );
          final BuildContext promptContext = tester.element(
            find.text('Click a tile to see details.'),
          );
          final Color promptOnSurface =
              Theme.of(promptContext).colorScheme.onSurface;
          _expectMutedSingleSource(prompt.style?.color, promptOnSurface,
              'no-selection guidance prompt');

          // Degenerate em-dash placeholder.
          final degenerateKey = '${demoRegionForOverlay.regionId}|unparsed';
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: ownedProvince,
              selectedTileKey: degenerateKey,
            ),
          );
          await tester.pumpAndSettle();
          final dash = _tileSectionBodyText(tester, '—');
          final BuildContext dashContext = tester.element(
            find
                .descendant(
                  of: find
                      .ancestor(
                        of: find.byWidgetPredicate(
                          (w) => w is CtSectionLabel && w.text == 'Tile',
                        ),
                        matching: find.byType(Column),
                      )
                      .first,
                  matching: find.text('—'),
                )
                .first,
          );
          final Color dashOnSurface =
              Theme.of(dashContext).colorScheme.onSurface;
          _expectMutedSingleSource(
              dash.style?.color, dashOnSurface, 'degenerate em-dash');
        },
      );
    },
  );
}

/// Asserts [color] declares its own value, is neither `Colors.white` nor the
/// dark Material `onSurface` proxy, and resolves exactly to
/// `EditorialMonoclePalette.muted` (the single source).
void _expectMutedSingleSource(Color? color, Color onSurface, String label) {
  expect(
    color,
    isNotNull,
    reason:
        'Material defaults regression guard: the Tile $label placeholder '
        'must declare its own TextStyle.color rather than relying on '
        'DefaultTextStyle fall-through.',
  );
  expect(
    color,
    isNot(equals(Colors.white)),
    reason:
        'Material defaults regression guard: the Tile $label placeholder '
        'must not resolve to the dark Material `Colors.white` fallback.',
  );
  expect(
    color,
    isNot(equals(onSurface)),
    reason:
        'Material defaults regression guard: the Tile $label placeholder '
        'must not resolve to Theme.of(context).colorScheme.onSurface (the '
        'dark Material `bodyMedium` proxy — distinct from '
        '`EditorialMonoclePalette.muted` under any non-`editorialMonocle` '
        'theme).',
  );
  expect(
    color,
    equals(EditorialMonoclePalette.muted),
    reason:
        'Material defaults regression guard: the Tile $label placeholder '
        'must resolve to EditorialMonoclePalette.muted (the single source).',
  );
}
