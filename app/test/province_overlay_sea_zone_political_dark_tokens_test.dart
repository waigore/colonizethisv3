// Pins the dark editorial-monocle sea-zone Political display-name body
// token for ProvinceSeaZoneDetailOverlay.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme sea-zone Political display-name
// body token (Refs #2865).
//
// When the overlay mounts for a sea zone whose Political section
// renders (i.e. the sea zone has at least one sea cell whose
// `TileVisibility != TileVisibility.unrevealed`, so the
// `isSeaZoneFullyUnrevealed` branch does NOT fire and the obfuscated
// `???` fallback does not apply), the localized
// `provinceOverlay_seaZone(seaName)` row (`Sea zone: {name}`) MUST
// resolve its `TextStyle.color` to `EditorialMonoclePalette.fg`.
// Material defaults (`Theme.of(context).colorScheme.onSurface`, the
// dark Material `Colors.white` fallback, or a `Text` whose `style`
// is `null` and so falls back to `DefaultTextStyle`) MUST NOT
// colour this row. Mirrors the existing province Political "Name" /
// "Owner" pins on this issue.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_sea_zone_detail_overlay.dart';

/// Builds a fresh [RegionMapViewData] derived from [demoRegionForOverlay]
/// with cell visibility overridden by [visibilityForCell]. Mirrors the
/// pattern in `province_overlay_obfuscated_body_dark_tokens_test.dart`
/// so this test can deterministically reveal a sea zone (i.e. force at
/// least one of its sea cells to `TileVisibility != unrevealed`) without
/// depending on the debug-init visibility distribution.
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

Widget _overlay({
  required ThemeData theme,
  required RegionMapViewData region,
  required String displayId,
}) {
  final game = demoGameForOverlay;
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: ProvinceSeaZoneDetailOverlay(
        game: game,
        region: region,
        displayId: displayId,
        selectedTileKey: null,
        humanPlayerId: game.players.first.id,
        playerView: demoHumanPlayerViewForOverlay,
        draftOrders: const Orders(),
      ),
    ),
  );
}

Finder _findTextStartingWith(String prefix) => find.byWidgetPredicate(
  (Widget w) => w is Text && (w.data ?? '').startsWith(prefix),
);

void main() {
  suppressLogsForTests();

  // Mirrors `province_overlay_dark_chrome_test.dart` (Refs #2859 R2 / S3):
  // `CtPanel` paints its dark editorial-monocle chrome programmatically so
  // no asset bundle stub is required here either.

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle sea-zone '
    'Political display-name body '
    '(SPEC § Dark-theme sea-zone Political display-name body token)',
    () {
      testWidgets(
        '"Sea zone: ..." display-name row resolves to '
        'EditorialMonoclePalette.fg',
        (WidgetTester tester) async {
          // Force every sea cell to TileVisibility.fogged so the
          // `_seaZoneContent` `isSeaZoneFullyUnrevealed` branch does
          // NOT fire and the live Political display-name row is built
          // via `_buildSection(political, Text(provinceOverlay_seaZone))`.
          // Land cells keep their visibility so unrelated paths are not
          // perturbed.
          final region = _regionWith(
            visibilityForCell: (c) =>
                c.isSea ? TileVisibility.fogged : c.visibility,
          );
          final seaCell = region.cells.firstWhere((c) => c.isSea);
          final seaZoneId = '${region.regionId}|${seaCell.regionCellId}';

          await tester.pumpWidget(
            _overlay(
              theme: AppThemes.editorialMonocle,
              region: region,
              displayId: seaZoneId,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _findTextStartingWith('Sea zone:');
          final List<String> renderedTexts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .toList();
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason:
                'Political "Sea zone: ..." display-name row must render '
                'when the sea zone has at least one non-unrevealed sea '
                'cell. Visible texts so far: '
                '${renderedTexts.where((s) => s.isNotEmpty).take(40).toList()}',
          );
          final Text row = tester.widget<Text>(finder.first);
          expect(
            row.style?.color,
            EditorialMonoclePalette.fg,
            reason:
                'Sea-zone Political "Sea zone: ..." display-name row '
                'must resolve TextStyle.color to '
                'EditorialMonoclePalette.fg per SPEC § Dark-theme '
                'sea-zone Political display-name body token.',
          );
        },
      );

      testWidgets(
        'negative: sea-zone Political "Sea zone: ..." row declares '
        'explicit TextStyle.color (no DefaultTextStyle fall-through) '
        'and does not resolve to the dark Material `Colors.white` '
        'fallback',
        (WidgetTester tester) async {
          final region = _regionWith(
            visibilityForCell: (c) =>
                c.isSea ? TileVisibility.fogged : c.visibility,
          );
          final seaCell = region.cells.firstWhere((c) => c.isSea);
          final seaZoneId = '${region.regionId}|${seaCell.regionCellId}';

          await tester.pumpWidget(
            _overlay(
              theme: AppThemes.editorialMonocle,
              region: region,
              displayId: seaZoneId,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _findTextStartingWith('Sea zone:');
          expect(finder, findsAtLeastNWidgets(1));
          final Text row = tester.widget<Text>(finder.first);
          // Contract: the sea-zone display-name row must declare its own
          // `TextStyle.color`. A bare `Text(line)` (no `style`) resolves
          // `style` to `null` and rendering falls through to ambient
          // `DefaultTextStyle`. Asserting `style?.color != null`
          // catches any regression that drops the explicit
          // `EditorialMonoclePalette.fg` colour back to `null`.
          expect(
            row.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard: sea-zone Political '
                '"Sea zone: ..." row must declare its own '
                'TextStyle.color rather than relying on '
                'DefaultTextStyle fall-through (so the contract '
                'survives a change in ambient bodyMedium colour).',
          );
          // The bare dark-Material `bodyMedium` colour without the
          // `editorialMonocle` override is `Colors.white`; explicitly
          // forbid it so a future theme swap that lost the
          // `EditorialMonoclePalette.fg` override is surfaced.
          expect(
            row.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard: sea-zone Political '
                '"Sea zone: ..." row must not resolve to the dark '
                'Material `Colors.white` fallback.',
          );
          expect(
            row.style?.color,
            equals(EditorialMonoclePalette.fg),
            reason:
                'Material defaults regression guard: sea-zone Political '
                '"Sea zone: ..." row must resolve to '
                'EditorialMonoclePalette.fg (the single source).',
          );
        },
      );

      testWidgets(
        'negative regression guard — under a bare dark ThemeData (no '
        'editorialMonocle override) the sea-zone Political "Sea zone: ..." '
        'row still resolves to EditorialMonoclePalette.fg, not '
        'null / Colors.white / colorScheme.onSurface',
        (WidgetTester tester) async {
          // Mount the overlay under a *bare* ThemeData (no
          // editorialMonocle override) so a future regression that
          // dropped the explicit fg style would have its bodyMedium
          // resolve to the dark Material `Colors.white` fallback. With
          // the SPEC-authorized token in place the row still resolves
          // to `EditorialMonoclePalette.fg` regardless of theme.
          final region = _regionWith(
            visibilityForCell: (c) =>
                c.isSea ? TileVisibility.fogged : c.visibility,
          );
          final seaCell = region.cells.firstWhere((c) => c.isSea);
          final seaZoneId = '${region.regionId}|${seaCell.regionCellId}';

          await tester.pumpWidget(
            _overlay(
              theme: ThemeData(brightness: Brightness.dark),
              region: region,
              displayId: seaZoneId,
            ),
          );
          await tester.pumpAndSettle();

          // Resolve `colorScheme.onSurface` against an Element in the
          // overlay subtree so the assertion targets the *same* dark
          // Material proxy the overlay would otherwise inherit.
          final BuildContext context = tester.element(
            find.byType(ProvinceSeaZoneDetailOverlay),
          );
          final Color onSurface = Theme.of(context).colorScheme.onSurface;

          final finder = _findTextStartingWith('Sea zone:');
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason:
                'Regression guard requires the sea-zone Political '
                '"Sea zone: ..." row to render on the partially-revealed '
                'sea-zone path.',
          );
          final Text row = tester.widget<Text>(finder.first);
          expect(
            row.style?.color,
            isNotNull,
            reason:
                'Material defaults regression guard (any theme): sea-zone '
                'Political "Sea zone: ..." row must declare its own '
                'TextStyle.color.',
          );
          expect(
            row.style?.color,
            isNot(equals(Colors.white)),
            reason:
                'Material defaults regression guard (any theme): sea-zone '
                'Political "Sea zone: ..." row must not resolve to the '
                'dark Material `Colors.white` fallback.',
          );
          expect(
            row.style?.color,
            isNot(equals(onSurface)),
            reason:
                'Material defaults regression guard (any theme): sea-zone '
                'Political "Sea zone: ..." row must not resolve to '
                'Theme.of(context).colorScheme.onSurface (the dark '
                'Material bodyMedium proxy — distinct from the explicit '
                'EditorialMonoclePalette.fg token under a bare dark '
                'ThemeData; under editorialMonocle this aliasing is '
                'expected and the editorialMonocle case asserts equality '
                'against EditorialMonoclePalette.fg directly).',
          );
          expect(
            row.style?.color,
            equals(EditorialMonoclePalette.fg),
            reason:
                'Sea-zone Political "Sea zone: ..." row must resolve to '
                'EditorialMonoclePalette.fg (the explicit single source) '
                'regardless of ambient ThemeData.',
          );
        },
      );
    },
  );
}
