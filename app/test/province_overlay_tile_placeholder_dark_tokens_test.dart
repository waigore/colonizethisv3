// Pins the dark editorial-monocle Tile-section placeholder body tokens
// for ProvinceSeaZoneDetailOverlay (S5 follow-up — Tile empty / unparsed).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation —
//   Dark-theme Tile section placeholder body tokens (S5 follow-up).
// Shared shell pump + muted pin densify residual mid-size cases (Refs #4021).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoRegionForOverlay;

import 'support/editorial_monocle_dark_token_assertions.dart';
import 'support/province_overlay_test_harness.dart';

Text _tileSectionBodyText(WidgetTester tester, String data) {
  final tileLabel = find.byWidgetPredicate(
    (w) => w is CtSectionLabel && w.text == 'Tile',
  );
  expect(tileLabel, findsOneWidget);
  final tileSectionColumn = find
      .ancestor(of: tileLabel, matching: find.byType(Column))
      .first;
  final bodyFinder = find.descendant(
    of: tileSectionColumn,
    matching: find.text(data),
  );
  expect(bodyFinder, findsOneWidget);
  return tester.widget<Text>(bodyFinder);
}

Future<(Game, String)> _ownedProvinceShell(
  WidgetTester tester, {
  String? selectedTileKey,
}) async {
  final game = demoGameForOverlay;
  final ownedProvince = ownedProvinceIdInOldWorld(
    game: game,
    ownerId: game.players.first.id,
  );
  await tester.pumpWidget(
    buildProvinceOverlayDarkThemeShell(
      game: game,
      displayId: ownedProvince,
      selectedTileKey: selectedTileKey,
    ),
  );
  await tester.pumpAndSettle();
  return (game, ownedProvince);
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile placeholder '
    'body (SPEC § Dark-theme Tile section placeholder body tokens — '
    'S5 follow-up)',
    () {
      testWidgets(
        'no-selection guidance prompt resolves to muted',
        (WidgetTester tester) async {
          await _ownedProvinceShell(tester, selectedTileKey: null);
          expect(
            _tileSectionBodyText(
              tester,
              'Click a tile to see details.',
            ).style?.color,
            EditorialMonoclePalette.muted,
          );
        },
      );

      testWidgets(
        'degenerate (unparsed key) em-dash placeholder resolves to muted',
        (WidgetTester tester) async {
          final degenerateKey = '${demoRegionForOverlay.regionId}|unparsed';
          await _ownedProvinceShell(tester, selectedTileKey: degenerateKey);
          expect(
            _tileSectionBodyText(tester, '—').style?.color,
            EditorialMonoclePalette.muted,
          );
        },
      );

      testWidgets(
        'negative: both Tile placeholders declare muted TextStyle.color '
        'and are neither Colors.white nor dark Material onSurface',
        (WidgetTester tester) async {
          await _ownedProvinceShell(tester, selectedTileKey: null);
          final prompt = _tileSectionBodyText(
            tester,
            'Click a tile to see details.',
          );
          final promptOnSurface = Theme.of(
            tester.element(find.text('Click a tile to see details.')),
          ).colorScheme.onSurface;
          expectMutedSingleSource(
            prompt.style?.color,
            promptOnSurface,
            'no-selection guidance prompt',
          );

          final degenerateKey = '${demoRegionForOverlay.regionId}|unparsed';
          await _ownedProvinceShell(tester, selectedTileKey: degenerateKey);
          final dash = _tileSectionBodyText(tester, '—');
          final dashContext = tester.element(
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
          expectMutedSingleSource(
            dash.style?.color,
            Theme.of(dashContext).colorScheme.onSurface,
            'degenerate em-dash',
          );
        },
      );
    },
  );
}
