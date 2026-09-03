// Pins the Economic-section row CONTENT contracts for
// ProvinceSeaZoneDetailOverlay (S6 — Economic body): within a single
// player-visible resource bucket, improved tile rows render BEFORE
// improvable terrain rows, and no economic row text leaks tile
// coordinates.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md § Acceptance criteria
//   - "Economic improved before improvable order"
//   - "Economic rows omit coordinates"
// (Refs #2865 S6).
//
// These ACs describe the row ORDERING and coordinate-suppression behavior,
// which is distinct from the dark-token colour pins in
// province_overlay_economic_section_dark_tokens_test.dart and the
// prospection/exclusion pins in province_sea_zone_resource_labels_test.dart.

import 'package:colonizethis_logic/colonizethis_logic.dart' show PlayerView;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_overlay_economic_row_order_coords_support.dart';
import 'province_overlay_test_harness.dart';

Widget _overlay({
  required Game game,
  required RegionMapViewData region,
  required String selectedTileKey,
  required PlayerView playerView,
}) {
  return buildProvinceOverlayDarkThemeShell(
    game: game,
    region: region,
    displayId: kEconRowOrderFullProvinceId,
    selectedTileKey: selectedTileKey,
    humanPlayerId: kEconRowOrderHumanPlayerId,
    playerView: playerView,
    shellWidth: 800,
  );
}

/// Improved-tile economic row label: `"{terrain}/Grain with {improvement}"`
/// (`province_economic_resourceRow` + `province_economic_withImprovement`).
/// Excludes the `(improvable)` suffix so the two row variants never collide.
Finder _improvedRowLabelFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains('Grain') &&
        (w.data ?? '').contains('with ') &&
        !(w.data ?? '').contains('(improvable)'),
  );
}

/// Improvable-tile economic row label: `"{terrain}/Grain (improvable)"`
/// (`province_economic_resourceRow` + `province_economic_improvableSuffix`).
Finder _improvableRowLabelFinder() {
  return find.byWidgetPredicate(
    (w) =>
        w is Text &&
        (w.data ?? '').contains('Grain') &&
        (w.data ?? '').contains('(improvable)'),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay Economic section row content '
    '(SPEC § Economic improved-before-improvable order + omit coordinates)',
    () {
      testWidgets('improved row renders before improvable row within the same '
          'resource bucket', (WidgetTester tester) async {
        final improvedTk = econRowOrderTileKey(0, 0);
        final improvableTk = econRowOrderTileKey(1, 0);
        final game = econRowOrderGameWithGrainTiles(
          tileKeys: [improvedTk, improvableTk],
          improvementByTile: {improvedTk: 2},
        );
        // Dense row-major grid (cellAt(x, y) == cells[y * width + x]).
        final region = econRowOrderRegionWithGrainCells(
          [(x: 0, y: 0), (x: 1, y: 0)],
          width: 2,
          height: 1,
        );

        await tester.pumpWidget(
          _overlay(
            game: game,
            region: region,
            selectedTileKey: improvedTk,
            playerView: econRowOrderOmniscientViewForTiles([
              improvedTk,
              improvableTk,
            ]),
          ),
        );
        await tester.pumpAndSettle();

        final improved = _improvedRowLabelFinder();
        final improvable = _improvableRowLabelFinder();
        expect(
          improved,
          findsOneWidget,
          reason:
              'Test setup: improvementByTile[$improvedTk] = 2 must render '
              'one "{terrain}/Grain with {impBase}" improved row.',
        );
        expect(
          improvable,
          findsOneWidget,
          reason:
              'Test setup: the unimproved grain tile $improvableTk must '
              'render one "{terrain}/Grain (improvable)" row.',
        );

        final double improvedDy = tester.getCenter(improved).dy;
        final double improvableDy = tester.getCenter(improvable).dy;
        expect(
          improvedDy,
          lessThan(improvableDy),
          reason:
              'SPEC § "Economic improved before improvable order": within '
              'a single resource bucket the UI layer lists improved tiles '
              'first and improvable terrain rows after, so the improved '
              'row must sit above the improvable row in the section column.',
        );
      });

      testWidgets(
        'economic improved and improvable row text omits tile coordinates',
        (WidgetTester tester) async {
          final improvedTk = econRowOrderTileKey(0, 0);
          final improvableTk = econRowOrderTileKey(1, 0);
          final game = econRowOrderGameWithGrainTiles(
            tileKeys: [improvedTk, improvableTk],
            improvementByTile: {improvedTk: 2},
          );
          // Dense row-major grid (cellAt(x, y) == cells[y * width + x]).
          final region = econRowOrderRegionWithGrainCells(
            [(x: 0, y: 0), (x: 1, y: 0)],
            width: 2,
            height: 1,
          );

          await tester.pumpWidget(
            _overlay(
              game: game,
              region: region,
              selectedTileKey: improvedTk,
              playerView: econRowOrderOmniscientViewForTiles([
                improvedTk,
                improvableTk,
              ]),
            ),
          );
          await tester.pumpAndSettle();

          final String improvedText =
              tester.widget<Text>(_improvedRowLabelFinder()).data ?? '';
          final String improvableText =
              tester.widget<Text>(_improvableRowLabelFinder()).data ?? '';

          // The economic row labels are "{terrain}/Grain with {impBase}" and
          // "{terrain}/Grain (improvable)". With plains terrain and the grain
          // Farm improvement name, no row token carries a digit, so any digit
          // in the rendered row text could only come from a leaked tile
          // coordinate (x=3 / y=0 / x=7). SPEC § "Economic rows omit
          // coordinates" forbids that.
          final RegExp anyDigit = RegExp(r'\d');
          expect(
            anyDigit.hasMatch(improvedText),
            isFalse,
            reason:
                'SPEC § "Economic rows omit coordinates": the improved row '
                'text "$improvedText" must not include tile coordinates.',
          );
          expect(
            anyDigit.hasMatch(improvableText),
            isFalse,
            reason:
                'SPEC § "Economic rows omit coordinates": the improvable row '
                'text "$improvableText" must not include tile coordinates.',
          );
          // Negative guard against the exact coordinate encodings that would
          // appear if a tile key or (x, y) tuple leaked into the row text.
          for (final coordFragment in <String>[
            '|0|0',
            '|1|0',
            '(0, 0)',
            '(1, 0)',
            '0,0',
            '1,0',
          ]) {
            expect(
              improvedText.contains(coordFragment),
              isFalse,
              reason: 'Improved row must not contain "$coordFragment".',
            );
            expect(
              improvableText.contains(coordFragment),
              isFalse,
              reason: 'Improvable row must not contain "$coordFragment".',
            );
          }
        },
      );
    },
  );
}
