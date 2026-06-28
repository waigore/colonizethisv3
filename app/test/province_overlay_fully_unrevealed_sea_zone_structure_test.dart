// Pins the structural contract of the fully-unrevealed sea-zone overlay
// branch (`_seaZoneContent` `isSeaZoneFullyUnrevealed`) for
// ProvinceSeaZoneDetailOverlay.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Layout (sea-zone overlays render only Political and Naval) and
// § Province overlay content (fully-unrevealed sea-zone obfuscation).
// Refs GitHub #2865 (Requirement 7 + Assumptions: "Sea-zone fully
// unrevealed: Political and Naval render `???`").
//
// The existing `province_overlay_obfuscated_body_dark_tokens_test.dart`
// pins the *token colour* of the `???` placeholders on this branch; the
// existing `province_sea_zone_overlay_detail_paths_test.dart` pins the
// two-section structure for a *partially-revealed* (live) sea zone. This
// test is the complementary structural regression guard for the
// *fully-unrevealed* sea zone: the overlay title is "Sea zone", exactly
// the Political and Naval sections render (no Tile / Economic / Military /
// Civilian), and both bodies obfuscate to `???`. A regression that fell
// through to the six-section province layout, leaked the Tile/Economic/
// Military/Civilian sections, or dropped the obfuscation would be caught
// here in both the wide single-column and narrow tab-strip layouts.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show demoGameForOverlay, demoHumanPlayerViewForOverlay, demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_tab_strip.dart';

/// Builds a fresh [RegionMapViewData] derived from [demoRegionForOverlay]
/// with every sea cell forced to [TileVisibility.unrevealed] so the
/// `_seaZoneContent` `isSeaZoneFullyUnrevealed` branch fires for any
/// sea-zone prefixed id. Land cells keep their visibility so unrelated
/// paths are not perturbed. Mirrors the helper in
/// `province_overlay_obfuscated_body_dark_tokens_test.dart`.
RegionMapViewData _regionWithAllSeaUnrevealed() {
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
          visibility: c.isSea ? TileVisibility.unrevealed : c.visibility,
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

Widget _overlay({
  required RegionMapViewData region,
  required String seaZoneId,
}) {
  final game = demoGameForOverlay;
  return MaterialApp(
    theme: AppThemes.editorialMonocle,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: region,
        displayId: seaZoneId,
        selectedTileKey: null,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        draftOrders: const Orders(),
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay fully-unrevealed sea-zone structure '
    '(SPEC § Layout — Political + Naval only; § content — `???` obfuscation)',
    () {
      testWidgets(
        'wide layout: exactly Political + Naval sections, both `???`, '
        'no Tile/Economic/Military/Civilian and no tab strip',
        (WidgetTester tester) async {
          final view = tester.view;
          final oldSize = view.physicalSize;
          final oldRatio = view.devicePixelRatio;
          addTearDown(() {
            view.physicalSize = oldSize;
            view.devicePixelRatio = oldRatio;
          });
          // Width clearly >= kNarrowBreakpoint (600) so the wide
          // single-column (no tab strip) layout is used; tall so the two
          // sections lay out without overflow.
          view.physicalSize = const Size(1200, 2000);
          view.devicePixelRatio = 1.0;

          final region = _regionWithAllSeaUnrevealed();
          final seaCell = region.cells.firstWhere((c) => c.isSea);
          final seaZoneId = '${region.regionId}|${seaCell.regionCellId}';

          await tester.pumpWidget(_overlay(region: region, seaZoneId: seaZoneId));
          await tester.pumpAndSettle();

          // Header is the sea-zone title, not the province title.
          expect(find.text('Sea zone'), findsOneWidget);
          expect(find.text('Province'), findsNothing);

          // Wide layout renders the sections as a single column (no tabs).
          expect(find.byType(CtTabStrip), findsNothing);

          // Exactly two section headers: Political and Naval (CtSectionLabel
          // upper-cases the label per SPEC § Dark-theme section labels).
          expect(find.byType(CtSectionLabel), findsNWidgets(2));
          expect(find.text('POLITICAL'), findsOneWidget);
          expect(find.text('NAVAL'), findsOneWidget);

          // Sea-zone overlays never render the land-only sections.
          for (final forbidden in const <String>[
            'TILE',
            'ECONOMIC',
            'MILITARY',
            'CIVILIAN',
          ]) {
            expect(
              find.text(forbidden),
              findsNothing,
              reason:
                  'Fully-unrevealed sea-zone overlay must not render the '
                  '$forbidden section (Political + Naval only per SPEC).',
            );
          }

          // Both bodies obfuscate to `???` (provinceOverlay_unknown).
          expect(find.text('???'), findsNWidgets(2));

          // The live "Sea zone: <name>" display-name row must NOT render on
          // the fully-unrevealed branch (it shows `???` instead).
          expect(find.textContaining('Sea zone:'), findsNothing);
        },
      );

      testWidgets(
        'narrow layout: tab strip with exactly the Political + Naval tabs '
        '(no Tile/Economic/Military/Civilian tabs)',
        (WidgetTester tester) async {
          final view = tester.view;
          final oldSize = view.physicalSize;
          final oldRatio = view.devicePixelRatio;
          addTearDown(() {
            view.physicalSize = oldSize;
            view.devicePixelRatio = oldRatio;
          });
          // Width < kNarrowBreakpoint (600) so the bottom-slot tab layout is
          // used; tall so the capped (⅓ screen) body fits without overflow.
          view.physicalSize = const Size(400, 2000);
          view.devicePixelRatio = 1.0;

          final region = _regionWithAllSeaUnrevealed();
          final seaCell = region.cells.firstWhere((c) => c.isSea);
          final seaZoneId = '${region.regionId}|${seaCell.regionCellId}';

          await tester.pumpWidget(_overlay(region: region, seaZoneId: seaZoneId));
          await tester.pumpAndSettle();

          expect(find.text('Sea zone'), findsOneWidget);

          // Narrow shell uses the tab strip.
          final tabStrip = find.byType(CtTabStrip);
          expect(tabStrip, findsOneWidget);

          // The strip exposes exactly two tab labels: Political and Naval.
          final CtTabStrip strip = tester.widget<CtTabStrip>(tabStrip);
          expect(
            strip.tabLabels,
            const <String>['Political', 'Naval'],
            reason:
                'Fully-unrevealed sea-zone overlay must offer only the '
                'Political and Naval tabs (in order) per SPEC § Layout.',
          );

          // Both obfuscated section bodies are mounted (IndexedStack keeps all
          // tab bodies in the tree, with non-selected bodies offstage), each
          // with its section header.
          expect(
            find.byType(CtSectionLabel, skipOffstage: false),
            findsNWidgets(2),
          );

          // No land-only tab labels are present.
          for (final forbidden in const <String>['Tile', 'Economic']) {
            expect(
              strip.tabLabels.contains(forbidden),
              isFalse,
              reason:
                  'Fully-unrevealed sea-zone overlay must not offer a '
                  '$forbidden tab.',
            );
          }
        },
      );
    },
  );
}
