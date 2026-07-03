// Pins the dark editorial-monocle obfuscated `???` body tokens for
// ProvinceSeaZoneDetailOverlay.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme obfuscated `???` body tokens
// (Refs #2865).
//
// Every obfuscated `???` body Text widget (fully-unrevealed province /
// sea-zone sections, partially-revealed Tile rows, and intel-gated
// Economic / Military / Civilian / Naval fallbacks) MUST resolve its
// `TextStyle.color` to `EditorialMonoclePalette.muted` so the dark theme
// owns the obfuscation surface end-to-end. Material defaults
// (`Theme.of(context).colorScheme.onSurface`, the dark Material
// `Colors.white` fallback, or a bare `Text(...)` whose `style` is `null`
// and so falls back to `DefaultTextStyle`) MUST NOT colour these
// placeholders. Mirrors the existing Political / Military / Naval /
// Economic / Civilian / Tile section-body dark-token pins on this issue.

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

import 'support/province_overlay_test_harness.dart';

/// Builds a fresh [RegionMapViewData] derived from [demoRegionForOverlay]
/// with cell visibility overridden by [visibilityForCell]. Used to trigger
/// fully-unrevealed (province / sea zone) and partially-revealed tile
/// branches deterministically without depending on the debug-init
/// visibility distribution.
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

/// All rendered `Text` widgets whose visible data matches one of the
/// obfuscation tokens defined by `provinceOverlay_unknown` (`???`) or by
/// one of the seven `provinceOverlay_tile*Unknown` strings. Returns the
/// canonical strings used by the running English ARB so the test stays
/// resilient to ARB key renames as long as the obfuscation glyph is `???`.
const Set<String> _obfuscatedDataExact = <String>{
  '???',
  'Coordinates: ???',
  'Terrain: ???',
  'Resource: ???',
  'Prospected: ???',
  'Improvement: ???',
  'Road / railroad: ???',
  'Civilian units (province): ???',
};

bool _isObfuscatedText(Widget widget) {
  if (widget is! Text) return false;
  final data = widget.data ?? '';
  return _obfuscatedDataExact.contains(data);
}

List<Text> _obfuscatedTextWidgets(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byWidgetPredicate(_isObfuscatedText))
      .toList(growable: false);
}

void _expectMutedObfuscated(Text widget, {required String context}) {
  // Each obfuscated `???` body row MUST declare its own
  // `TextStyle.color`. A bare `Text(line)` (no `style`) resolves
  // `style` to `null` and rendering falls through to ambient
  // `DefaultTextStyle`. Asserting `style?.color != null` catches any
  // regression that drops the explicit `EditorialMonoclePalette.muted`
  // colour back to `null`.
  expect(
    widget.style?.color,
    isNotNull,
    reason:
        'Material defaults regression guard: obfuscated body row '
        '"${widget.data}" ($context) must declare its own '
        'TextStyle.color rather than relying on DefaultTextStyle '
        'fall-through.',
  );
  // The bare dark-Material `bodyMedium` colour without the
  // `editorialMonocle` override is `Colors.white`; explicitly forbid it
  // so a future theme swap that lost the
  // `EditorialMonoclePalette.muted` override is surfaced.
  expect(
    widget.style?.color,
    isNot(equals(Colors.white)),
    reason:
        'Material defaults regression guard: obfuscated body row '
        '"${widget.data}" ($context) must not resolve to the dark '
        'Material `Colors.white` fallback.',
  );
  expect(
    widget.style?.color,
    equals(EditorialMonoclePalette.muted),
    reason:
        'Obfuscated body row "${widget.data}" ($context) must resolve '
        'TextStyle.color to EditorialMonoclePalette.muted per SPEC '
        '§ Dark-theme obfuscated `???` body tokens.',
  );
}

void main() {
  suppressLogsForTests();

  // Mirrors `province_overlay_dark_chrome_test.dart` (Refs #2859 R2 / S3):
  // `CtPanel` paints its dark editorial-monocle chrome programmatically so
  // no asset bundle stub is required.

  group('ProvinceSeaZoneDetailOverlay dark editorial-monocle obfuscated `???` '
      'body (SPEC § Dark-theme obfuscated `???` body tokens)', () {
    testWidgets('fully-unrevealed province sections — every `???` placeholder '
        'resolves to EditorialMonoclePalette.muted', (
      WidgetTester tester,
    ) async {
      // Force every cell to TileVisibility.unrevealed so the
      // `_provinceContent` `isFullyUnrevealed` branch fires for the
      // synthetic prefixed province id below. The local id need only
      // match no actual region cell to keep the branch deterministic;
      // we still pass a valid region so the overlay constructs.
      final region = _regionWith(
        visibilityForCell: (_) => TileVisibility.unrevealed,
      );
      final provinceId =
          '${region.regionId}|${region.cells.first.regionCellId}';

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: demoGameForOverlay,
          region: region,
          displayId: provinceId,
        ),
      );
      await tester.pumpAndSettle();

      final obfuscated = _obfuscatedTextWidgets(tester);
      // The fully-unrevealed province `sections` column renders one
      // `???` placeholder per section (Political, Tile, Economic,
      // Military, Civilian, Naval) plus the same six in the tab
      // views (politicalObs, tileObs, four _ObfuscatedSection). The
      // exact count is not the contract — at least one is required
      // and every rendered placeholder must resolve to muted.
      expect(
        obfuscated,
        isNotEmpty,
        reason:
            'Fully-unrevealed province path must render at least one '
            '`???` placeholder Text in the obfuscated sections column.',
      );
      for (final widget in obfuscated) {
        _expectMutedObfuscated(
          widget,
          context: 'fully-unrevealed province sections',
        );
      }
    });

    testWidgets('fully-unrevealed sea-zone sections — every `???` placeholder '
        'resolves to EditorialMonoclePalette.muted', (
      WidgetTester tester,
    ) async {
      // Drive every sea cell to unrevealed so the
      // `_seaZoneContent` `isSeaZoneFullyUnrevealed` branch fires
      // for any sea-zone prefixed id (land cells keep their
      // visibility so unrelated paths are not perturbed).
      final region = _regionWith(
        visibilityForCell: (c) =>
            c.isSea ? TileVisibility.unrevealed : c.visibility,
      );
      // Pick the first sea cell so the synthetic id exists; the
      // sea-zone branch only inspects sea cells with matching local
      // id, all of which are unrevealed under the override above.
      final seaCell = region.cells.firstWhere((c) => c.isSea);
      final seaZoneId = '${region.regionId}|${seaCell.regionCellId}';

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: demoGameForOverlay,
          region: region,
          displayId: seaZoneId,
        ),
      );
      await tester.pumpAndSettle();

      final obfuscated = _obfuscatedTextWidgets(tester);
      expect(
        obfuscated,
        isNotEmpty,
        reason:
            'Fully-unrevealed sea-zone path must render at least one '
            '`???` placeholder Text (Political + Naval).',
      );
      for (final widget in obfuscated) {
        _expectMutedObfuscated(
          widget,
          context: 'fully-unrevealed sea-zone sections',
        );
      }
    });

    testWidgets('partially-revealed Tile section — every `Coordinates/Terrain/'
        'Resource/Prospected/Improvement/Road/CivilianUnits: ???` row '
        'resolves to EditorialMonoclePalette.muted', (
      WidgetTester tester,
    ) async {
      // Pick the first non-sea cell whose province also has at least
      // one other revealed cell, then drive that cell unrevealed
      // while leaving the rest of the province visible. This
      // triggers the partially-revealed Tile branch in
      // `_buildTileSection` (province is not fully-unrevealed, but
      // the selected tile is).
      final baseRegion = demoRegionForOverlay;
      final targetCell = baseRegion.cells.firstWhere(
        (c) =>
            !c.isSea &&
            baseRegion.cells.any(
              (other) =>
                  other.regionCellId == c.regionCellId &&
                  other.visibility != TileVisibility.unrevealed,
            ),
      );
      final region = _regionWith(
        visibilityForCell: (c) => c.x == targetCell.x && c.y == targetCell.y
            ? TileVisibility.unrevealed
            : c.visibility,
      );
      final selectedTileKey =
          '${region.regionId}|${targetCell.regionCellId}|'
          '${targetCell.x}|${targetCell.y}';
      final provinceId = '${region.regionId}|${targetCell.regionCellId}';

      await tester.pumpWidget(
        buildProvinceOverlayDarkThemeShell(
          game: demoGameForOverlay,
          region: region,
          displayId: provinceId,
          selectedTileKey: selectedTileKey,
        ),
      );
      await tester.pumpAndSettle();

      // The Tile branch emits the seven `provinceOverlay_tile*Unknown`
      // rows in a Column inside `_buildSection`. Each of them must
      // render with the shared muted token.
      const tileUnknownDataset = <String>{
        'Coordinates: ???',
        'Terrain: ???',
        'Resource: ???',
        'Prospected: ???',
        'Improvement: ???',
        'Road / railroad: ???',
        'Civilian units (province): ???',
      };
      for (final expected in tileUnknownDataset) {
        final finder = find.byWidgetPredicate(
          (Widget w) => w is Text && w.data == expected,
        );
        expect(
          finder,
          findsOneWidget,
          reason:
              'Partially-revealed Tile section must render the '
              '"$expected" placeholder exactly once.',
        );
        final Text row = tester.widget<Text>(finder);
        _expectMutedObfuscated(
          row,
          context: 'partially-revealed Tile section row',
        );
      }
    });

    testWidgets('negative regression guard — under any ThemeData no obfuscated '
        '`???` body row resolves to null / Colors.white / colorScheme.'
        'onSurface', (WidgetTester tester) async {
      // Mount the overlay under a *bare* ThemeData (no
      // editorialMonocle override) so a future regression that
      // dropped the explicit muted style would have its bodyMedium
      // resolve to the dark Material `Colors.white` fallback. With
      // the SPEC-authorized helper in place every obfuscated row
      // still resolves to `EditorialMonoclePalette.muted`.
      final region = _regionWith(
        visibilityForCell: (_) => TileVisibility.unrevealed,
      );
      final provinceId =
          '${region.regionId}|${region.cells.first.regionCellId}';
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Scaffold(
            body: ProvinceSeaZoneDetailOverlay(
              game: demoGameForOverlay,
              region: region,
              displayId: provinceId,
              selectedTileKey: null,
              humanPlayerId: demoGameForOverlay.players.first.id,
              playerView: demoHumanPlayerViewForOverlay,
              draftOrders: const Orders(),
            ),
          ),
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

      final obfuscated = _obfuscatedTextWidgets(tester);
      expect(
        obfuscated,
        isNotEmpty,
        reason:
            'Regression guard requires at least one obfuscated `???` '
            'body row to exist on the fully-unrevealed province path.',
      );
      for (final widget in obfuscated) {
        expect(
          widget.style?.color,
          isNotNull,
          reason:
              'Material defaults regression guard (any theme): '
              '"${widget.data}" must declare its own TextStyle.color.',
        );
        expect(
          widget.style?.color,
          isNot(equals(Colors.white)),
          reason:
              'Material defaults regression guard (any theme): '
              '"${widget.data}" must not resolve to the dark Material '
              '`Colors.white` fallback.',
        );
        expect(
          widget.style?.color,
          isNot(equals(onSurface)),
          reason:
              'Material defaults regression guard (any theme): '
              '"${widget.data}" must not resolve to '
              'Theme.of(context).colorScheme.onSurface (the dark '
              'Material bodyMedium proxy — distinct from '
              'EditorialMonoclePalette.muted, and itself wired to '
              'EditorialMonoclePalette.fg under editorialMonocle so '
              'the obfuscated body would otherwise visually equal '
              'the always-exact Political rows).',
        );
        expect(
          widget.style?.color,
          equals(EditorialMonoclePalette.muted),
          reason:
              'Obfuscated body row "${widget.data}" must resolve to '
              'EditorialMonoclePalette.muted (the explicit single '
              'source) regardless of ambient ThemeData.',
        );
      }
    });
  });
}
