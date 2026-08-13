// Pins the dark editorial-monocle Economic section commodity-id label
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Economic section body tokens
// (Refs #2865 S6 — extends the row-label slice by bringing the
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';

import 'province_overlay_economic_resource_label_support.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay dark editorial-monocle Economic section '
      '— ResourceLabelInline commodity-id label '
      '(SPEC § Dark-theme Economic section body tokens — improved / '
      'improvable commodity-id label colour)', () {
    testWidgets('improved-row commodity-id label resolves to '
        'EditorialMonoclePalette.fg under editorialMonocle (positive AC: '
        'Economic improved-row commodity-id label colour)', (
      WidgetTester tester,
    ) async {
      await pumpEconomicResourceLabelOverlay(
        tester,
        improvementByTile: {economicResourceLabelTileKey(0, 0): 2},
      );

      expectEconomicGrainLabelColor(tester, EditorialMonoclePalette.fg);
      expectEconomicGrainTextColor(tester, EditorialMonoclePalette.fg);
    });

    testWidgets('improvable-row commodity-id label resolves to '
        'EditorialMonoclePalette.muted under editorialMonocle (positive '
        'AC: Economic improvable-row commodity-id label colour)', (
      WidgetTester tester,
    ) async {
      await pumpEconomicResourceLabelOverlay(
        tester,
        improvementByTile: const {},
      );

      expectEconomicGrainLabelColor(tester, EditorialMonoclePalette.muted);
      expectEconomicGrainTextColor(tester, EditorialMonoclePalette.muted);
    });

    testWidgets(
      'improved-row commodity-id label regression guard — never falls '
      'through DefaultTextStyle and never resolves to Colors.white (the '
      'bare dark Material bodyMedium fallback) under editorialMonocle '
      '(negative AC: Economic improved-row commodity-id label Material '
      'fallback regression guard)',
      (WidgetTester tester) async {
        await pumpEconomicResourceLabelOverlay(
          tester,
          improvementByTile: {economicResourceLabelTileKey(0, 0): 2},
        );

        final all = economicResourceLabelWidgets(tester);
        expect(all, isNotEmpty);
        final style = all.single.labelStyle;
        expect(style, isNotNull);
        expect(style?.color, isNotNull);
        expect(style?.color, isNot(Colors.white));
        expect(style?.color, EditorialMonoclePalette.fg);
      },
    );

    testWidgets(
      'improvable-row commodity-id label regression guard — never falls '
      'through DefaultTextStyle, never resolves to Colors.white, and '
      'never resolves to Theme.colorScheme.onSurface (negative AC: '
      'Economic improvable-row commodity-id label Material fallback '
      'regression guard)',
      (WidgetTester tester) async {
        await pumpEconomicResourceLabelOverlay(
          tester,
          improvementByTile: const {},
        );

        final all = economicResourceLabelWidgets(tester);
        expect(all, isNotEmpty);
        final style = all.single.labelStyle;
        expect(style, isNotNull);
        expect(style?.color, isNotNull);
        expect(style?.color, isNot(Colors.white));

        final BuildContext context = tester.element(
          find.byType(ResourceLabelInline).first,
        );
        final Color onSurface = Theme.of(context).colorScheme.onSurface;
        expect(style?.color, isNot(equals(onSurface)));
        expect(style?.color, EditorialMonoclePalette.muted);
      },
    );
  });
}
