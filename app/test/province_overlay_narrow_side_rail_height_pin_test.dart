// Pins the narrow-shell height-table cases that the existing widget tests in
// `province_overlay_test.dart` do not cover:
//
//  1. Narrow viewport, **side rail** host (panel width clearly less than
//     screen width — e.g. 320 dp inside a 400 dp viewport): the overlay
//     must use the parent rail's full height (`parentMax`), **not** the
//     `0.33 × MediaQuery.size.height` cap used for narrow full-width hosts.
//  2. Narrow viewport, parent **already constrains** height to a value
//     `≤ third` (e.g. a bottom slot wrapped in `SizedBox(height: 150)`):
//     the overlay must honor that constrained height exactly without
//     shrinking further.
//
// Both cases derive directly from
// `SPEC/ui/province-sea-zone-detail-overlay.md` § Layout / wireframe height
// table and the matching § Acceptance criteria entries:
//
//  - "Narrow side rail" — uses `parentMax`, no `0.33 × H` cap.
//  - "Narrow full-width, parent already capping" — uses parent's exact height
//    without further shrinking.
//
// Together with the existing pins in `province_overlay_test.dart` for the
// narrow full-width-uncapped and wide side-panel cases, this file completes
// the height-table test coverage for the four documented layout rows.
//
// Refs #2865 — `ProvinceSeaZoneDetailOverlay` (`MAP20001`) layout pins.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleTileKeyForProvinceOverlay;

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay narrow-shell height table', () {
    Widget buildOverlay() {
      return ProvinceSeaZoneDetailOverlay(
        game: demoGameForOverlay,
        region: demoRegionForOverlay,
        displayId: sampleProvinceIdForOverlay,
        selectedTileKey: sampleTileKeyForProvinceOverlay,
        humanPlayerId: demoGameForOverlay.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        onClose: () {},
      );
    }

    /// Returns the `maxHeight` of the inner `ConstrainedBox` that
    /// `_buildResponsivePanel` wraps around the overlay body. The widget
    /// emits exactly one such box per build (per `_buildResponsivePanel`),
    /// so this captures the resolved layout cap directly.
    double readOverlayMaxHeight(WidgetTester tester) {
      final boxes = tester
          .widgetList<ConstrainedBox>(
            find.descendant(
              of: find.byType(ProvinceSeaZoneDetailOverlay),
              matching: find.byType(ConstrainedBox),
            ),
          )
          .toList();
      // The overlay's height-controlling ConstrainedBox is the first one
      // whose maxHeight matches one of the documented bounds; pick the
      // smallest finite maxHeight to reflect the effective cap.
      final finiteHeights = boxes
          .map((b) => b.constraints.maxHeight)
          .where((h) => h.isFinite)
          .toList();
      expect(
        finiteHeights,
        isNotEmpty,
        reason:
            'Expected at least one finite-maxHeight ConstrainedBox under '
            'ProvinceSeaZoneDetailOverlay (per _buildResponsivePanel).',
      );
      finiteHeights.sort();
      return finiteHeights.first;
    }

    testWidgets(
      'AC: narrow viewport in a fixed-width side rail uses parentMax, '
      'not the one-third cap',
      (WidgetTester tester) async {
        // SPEC: "Narrow side rail: ... use the full rail height
        // (`parentMax`) without applying the `0.33 × H` cap." A 320 dp rail
        // inside a 400 dp narrow viewport (rail width clearly less than
        // screen width) is the canonical fixture for this row of the
        // height table.
        const viewportWidth = 400.0;
        const viewportHeight = 600.0;
        const railWidth = 320.0; // < viewportWidth - 8 → not full-width.
        const expectedMaxHeight = viewportHeight; // parentMax

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(viewportWidth, viewportHeight),
            ),
            child: MaterialApp(
              home: Scaffold(
                // A `Row` with the overlay constrained to a fixed-width
                // side rail mirrors how a narrow shell may host the panel
                // beside other UI rather than as the full-width bottom
                // slot. The trailing `Spacer` consumes the remaining
                // viewport width so `constraints.maxWidth` reaching the
                // overlay is exactly `railWidth`.
                body: Row(
                  children: [
                    SizedBox(width: railWidth, child: buildOverlay()),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final resolved = readOverlayMaxHeight(tester);
        expect(
          resolved,
          expectedMaxHeight,
          reason:
              'Narrow side rail host must use parentMax '
              '($expectedMaxHeight), not the one-third cap '
              '(${viewportHeight * 0.33}).',
        );
        // Negative pin: the resolved height must not equal the
        // one-third cap so a regression that re-applies the full-width
        // narrow rule to side rails fails this guard explicitly.
        expect(
          resolved,
          isNot(viewportHeight * 0.33),
          reason:
              'Narrow side rail must not be capped at one-third '
              '(${viewportHeight * 0.33}).',
        );
      },
    );

    testWidgets(
      'AC: narrow viewport with a parent that already caps height '
      'below one-third uses that parent height exactly',
      (WidgetTester tester) async {
        // SPEC: "Narrow, parent already constrains height to ≤ third
        // (e.g. bottom slot `SizedBox(height: third)`): use that height
        // exactly (do not shrink further)." We pick a host that constrains
        // height to 150 dp (well below `0.33 × 600 = 198 dp`) so the
        // overlay must honor 150 instead of falling through to either the
        // third cap or `parentMax`.
        const viewportWidth = 400.0;
        const viewportHeight = 600.0;
        const parentHeight = 150.0; // < 0.33 × 600 = 198
        const expectedMaxHeight = parentHeight;

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(viewportWidth, viewportHeight),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: viewportWidth,
                    height: parentHeight,
                    child: buildOverlay(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final resolved = readOverlayMaxHeight(tester);
        expect(
          resolved,
          expectedMaxHeight,
          reason:
              'Narrow viewport with parent already capping below third '
              'must honor the parent\'s exact height ($parentHeight) '
              'without further shrinking.',
        );
        // Negative pin: not capped at one-third, not the unrelated
        // viewport height — the implementation must use the parent\'s
        // exact constraint and nothing else.
        expect(
          resolved,
          isNot(viewportHeight * 0.33),
          reason:
              'Parent-capped narrow host must not fall through to the '
              'one-third cap (${viewportHeight * 0.33}).',
        );
        expect(
          resolved,
          isNot(viewportHeight),
          reason:
              'Parent-capped narrow host must not fall through to the '
              'parent rail / desktop full height ($viewportHeight).',
        );
      },
    );
  });
}
