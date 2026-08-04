// Pins the dark editorial-monocle sea-zone Political display-name body
// token. Positive + Material-default guards share one editorialMonocle
// pump; bare ThemeData keeps a short theme-decoupling guard
// (Refs #4021 densify).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme sea-zone Political display-name
// body token.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'editorial_monocle_dark_token_assertions.dart';
import 'province_overlay_dark_token_scenarios.dart';
import 'province_overlay_test_harness.dart';

Widget _overlay({
  required ThemeData theme,
  required RegionMapViewData region,
  required String displayId,
}) {
  final game = demoGameForOverlay;
  return buildProvinceOverlayDarkThemeShell(
    game: game,
    region: region,
    displayId: displayId,
    shellTheme: theme == AppThemes.editorialMonocle ? null : theme,
  );
}

Finder _findTextStartingWith(String prefix) => find.byWidgetPredicate(
  (Widget w) => w is Text && (w.data ?? '').startsWith(prefix),
);

({RegionMapViewData region, String seaZoneId}) _foggedSeaZoneScenario() {
  final region = regionMapWithCellVisibility(
    visibilityForCell: (c) =>
        c.isSea ? TileVisibility.fogged : c.visibility,
  );
  final seaCell = region.cells.firstWhere((c) => c.isSea);
  return (
    region: region,
    seaZoneId: '${region.regionId}|${seaCell.regionCellId}',
  );
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle sea-zone '
    'Political display-name body '
    '(SPEC § Dark-theme sea-zone Political display-name body token)',
    () {
      testWidgets(
        '"Sea zone: ..." display-name resolves to fg '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final scenario = _foggedSeaZoneScenario();
          await tester.pumpWidget(
            _overlay(
              theme: AppThemes.editorialMonocle,
              region: scenario.region,
              displayId: scenario.seaZoneId,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _findTextStartingWith('Sea zone:');
          expect(
            finder,
            findsAtLeastNWidgets(1),
            reason: 'Political "Sea zone: ..." row must render when fogged.',
          );
          final Text row = tester.widget<Text>(finder.first);
          expectFgSingleSource(
            row.style?.color,
            'Sea-zone Political display-name',
          );
        },
      );

      testWidgets(
        'bare dark ThemeData — "Sea zone: ..." still resolves to fg',
        (WidgetTester tester) async {
          final scenario = _foggedSeaZoneScenario();
          await tester.pumpWidget(
            _overlay(
              theme: ThemeData(brightness: Brightness.dark),
              region: scenario.region,
              displayId: scenario.seaZoneId,
            ),
          );
          await tester.pumpAndSettle();

          final finder = _findTextStartingWith('Sea zone:');
          expect(finder, findsAtLeastNWidgets(1));
          final Text row = tester.widget<Text>(finder.first);
          expectFgSingleSource(
            row.style?.color,
            'Sea-zone Political (bare ThemeData)',
          );
          final onSurface = Theme.of(
            tester.element(find.byType(ProvinceSeaZoneDetailOverlay)),
          ).colorScheme.onSurface;
          expect(
            row.style?.color,
            isNot(equals(onSurface)),
            reason:
                'Bare ThemeData: row must not use colorScheme.onSurface '
                '(would alias under editorialMonocle where onSurface==fg).',
          );
        },
      );
    },
  );
}
