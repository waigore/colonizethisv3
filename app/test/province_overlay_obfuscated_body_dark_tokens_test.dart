// Pins the dark editorial-monocle obfuscated `???` body tokens for
// ProvinceSeaZoneDetailOverlay. Positive paths fold Material-default
// guards via [expectMutedSingleSource] (Refs #4021 densify).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme obfuscated `???` body tokens.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoHumanPlayerViewForOverlay,
        demoRegionForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'province_overlay_dark_token_scenarios.dart';
import 'province_overlay_test_harness.dart';

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
  return _obfuscatedDataExact.contains(widget.data ?? '');
}

List<Text> _obfuscatedTextWidgets(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byWidgetPredicate(_isObfuscatedText))
      .toList(growable: false);
}

void _expectAllObfuscatedMuted(
  WidgetTester tester, {
  required String context,
}) {
  final obfuscated = _obfuscatedTextWidgets(tester);
  expect(
    obfuscated,
    isNotEmpty,
    reason: '$context must render at least one obfuscated `???` Text.',
  );
  final onSurface = Theme.of(
    tester.element(find.byWidget(obfuscated.first)),
  ).colorScheme.onSurface;
  for (final widget in obfuscated) {
    expectMutedSingleSource(
      widget.style?.color,
      onSurface,
      '$context "${widget.data}"',
    );
  }
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle obfuscated `???` '
    'body (SPEC § Dark-theme obfuscated `???` body tokens)',
    () {
      testWidgets(
        'fully-unrevealed province sections — every `???` is muted '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final region = regionMapWithCellVisibility(
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
          _expectAllObfuscatedMuted(
            tester,
            context: 'fully-unrevealed province sections',
          );
        },
      );

      testWidgets(
        'fully-unrevealed sea-zone sections — every `???` is muted '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final region = regionMapWithCellVisibility(
            visibilityForCell: (c) =>
                c.isSea ? TileVisibility.unrevealed : c.visibility,
          );
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
          _expectAllObfuscatedMuted(
            tester,
            context: 'fully-unrevealed sea-zone sections',
          );
        },
      );

      testWidgets(
        'partially-revealed Tile section — tile `???` rows are muted '
        '(with Material-default guards)',
        (WidgetTester tester) async {
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
          final region = regionMapWithCellVisibility(
            visibilityForCell: (c) =>
                c.x == targetCell.x && c.y == targetCell.y
                ? TileVisibility.unrevealed
                : c.visibility,
          );
          final selectedTileKey =
              '${region.regionId}|${targetCell.regionCellId}|'
              '${targetCell.x}|${targetCell.y}';
          final provinceId =
              '${region.regionId}|${targetCell.regionCellId}';

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: demoGameForOverlay,
              region: region,
              displayId: provinceId,
              selectedTileKey: selectedTileKey,
            ),
          );
          await tester.pumpAndSettle();

          const tileUnknownDataset = <String>{
            'Coordinates: ???',
            'Terrain: ???',
            'Resource: ???',
            'Prospected: ???',
            'Improvement: ???',
            'Road / railroad: ???',
            'Civilian units (province): ???',
          };
          final onSurface = Theme.of(
            tester.element(find.byType(Scaffold).first),
          ).colorScheme.onSurface;
          for (final expected in tileUnknownDataset) {
            final finder = find.byWidgetPredicate(
              (Widget w) => w is Text && w.data == expected,
            );
            expect(
              finder,
              findsOneWidget,
              reason: 'Partially-revealed Tile must render "$expected".',
            );
            final Text row = tester.widget<Text>(finder);
            expectMutedSingleSource(
              row.style?.color,
              onSurface,
              'partially-revealed Tile "$expected"',
            );
          }
        },
      );

      testWidgets(
        'bare dark ThemeData — obfuscated `???` rows still resolve to muted',
        (WidgetTester tester) async {
          final region = regionMapWithCellVisibility(
            visibilityForCell: (_) => TileVisibility.unrevealed,
          );
          final provinceId =
              '${region.regionId}|${region.cells.first.regionCellId}';
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: demoGameForOverlay,
              region: region,
              displayId: provinceId,
              shellTheme: ThemeData(brightness: Brightness.dark),
            ),
          );
          await tester.pumpAndSettle();

          final onSurface = Theme.of(
            tester.element(find.byType(ProvinceSeaZoneDetailOverlay)),
          ).colorScheme.onSurface;
          final obfuscated = _obfuscatedTextWidgets(tester);
          expect(obfuscated, isNotEmpty);
          for (final widget in obfuscated) {
            expectMutedSingleSource(
              widget.style?.color,
              onSurface,
              'bare theme "${widget.data}"',
            );
            expect(
              widget.style?.color,
              EditorialMonoclePalette.muted,
            );
          }
        },
      );
    },
  );
}
