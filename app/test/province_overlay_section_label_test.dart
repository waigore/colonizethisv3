// Pins the dark editorial-monocle section-label contract for
// ProvinceSeaZoneDetailOverlay section bodies (S4 — sections layer).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme section labels (Refs #2865 S4).
//
// Each section body's header band MUST render via CtSectionLabel so the
// dark theme inherits the canonical small-caps + `--accent-dim` underline
// contract. Raw `Text(..., style: TextStyle(fontWeight: FontWeight.bold))`
// is no longer allowed as the section header.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';

Widget _darkOverlay({
  required String displayId,
  String? selectedTileKey,
}) {
  final game = demoGameForOverlay;
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: demoRegionForOverlay,
        displayId: displayId,
        selectedTileKey: selectedTileKey,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
      ),
    ),
  );
}

Set<String> _sectionLabelTexts(WidgetTester tester) {
  return tester
      .widgetList<CtSectionLabel>(find.byType(CtSectionLabel))
      .map((w) => w.text)
      .toSet();
}

void main() {
  suppressLogsForTests();

  // No flutter/assets stub — the same fallback path documented in
  // province_overlay_dark_chrome_test.dart applies here.

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle section labels '
    '(SPEC § Dark-theme section labels)',
    () {
      testWidgets(
        'province wide layout renders Political, Tile, Economic, Military, '
        'Civilian, Naval via CtSectionLabel',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlay(
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
            ),
          );
          await tester.pumpAndSettle();

          final labels = _sectionLabelTexts(tester);
          expect(
            labels,
            containsAll(<String>[
              'Political',
              'Tile',
              'Economic',
              'Military',
              'Civilian',
              'Naval',
            ]),
            reason:
                'All six province section headers must render through '
                'CtSectionLabel so the dark theme owns their small-caps + '
                'accent-dim underline (SPEC § Dark-theme section labels).',
          );
        },
      );

      testWidgets(
        'sea-zone wide layout renders Political and Naval via CtSectionLabel '
        'and never emits a Tile section header',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlay(displayId: sampleSeaZoneIdForOverlay),
          );
          await tester.pumpAndSettle();

          final labels = _sectionLabelTexts(tester);
          expect(labels, containsAll(<String>['Political', 'Naval']));
          expect(
            labels.contains('Tile'),
            isFalse,
            reason:
                'Sea-zone overlay must not render a Tile section header in '
                'any context per SPEC § Province overlay content (sea zone '
                'tab order is Political, Naval).',
          );
        },
      );

      testWidgets(
        'negative: no raw bold-Text section heading appears in the overlay '
        'subtree (regression guard against legacy bold heading pattern)',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            _darkOverlay(
              displayId: sampleProvinceIdForOverlay,
              selectedTileKey: sampleTileKeyForProvinceOverlay,
            ),
          );
          await tester.pumpAndSettle();

          // No section heading text may render via a raw const TextStyle
          // with FontWeight.bold (the legacy pattern this S4 slice replaces).
          // Limit the search to the canonical heading strings so unrelated
          // bold typography (e.g. inside CtTopBar title or unit-row chips)
          // is not falsely flagged.
          const headingTexts = <String>[
            'Political',
            'Tile',
            'Economic',
            'Military',
            'Civilian',
            'Naval',
          ];
          for (final heading in headingTexts) {
            final finder = find.text(heading);
            for (final element in finder.evaluate()) {
              final widget = element.widget as Text;
              expect(
                widget.style?.fontWeight,
                isNot(FontWeight.bold),
                reason:
                    'Section header "$heading" must render via '
                    'CtSectionLabel, not a raw bold Text widget '
                    '(SPEC § Dark-theme section labels).',
              );
            }
          }
        },
      );

      testWidgets(
        'fully-unrevealed province wide layout still surfaces every section '
        'header via CtSectionLabel',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          // Use a synthetic fully-unrevealed province id: the demo region's
          // first cell mirrored via an id that does not exist in the region.
          // The overlay's `isFullyUnrevealed` branch is triggered when no
          // cell matches the local province id, which is the case here.
          const unknownProvinceId = 'oldWorld|never-exists-province';
          await tester.pumpWidget(
            MaterialApp(
              theme: AppThemes.editorialMonocle,
              home: Scaffold(
                body: ProvinceSeaZoneDetailOverlay(
                  game: game,
                  region: demoRegionForOverlay,
                  displayId: unknownProvinceId,
                  selectedTileKey: null,
                  humanPlayerId: game.players.first.id,
                  playerView: demoHumanPlayerViewForOverlay,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final labels = _sectionLabelTexts(tester);
          expect(
            labels,
            containsAll(<String>[
              'Political',
              'Tile',
              'Economic',
              'Military',
              'Civilian',
              'Naval',
            ]),
            reason:
                'Fully-unrevealed wide-layout sections column must also use '
                'CtSectionLabel for every section header (SPEC AC '
                '"Dark-theme section headers in fully-unrevealed wide '
                'layout").',
          );
        },
      );
    },
  );
}
