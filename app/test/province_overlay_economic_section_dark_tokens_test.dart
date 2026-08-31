// Pins the dark editorial-monocle Economic section body tokens for
// ProvinceSeaZoneDetailOverlay (S6 — Economic body).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Economic section body tokens
// (Refs #2865 S6).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'province_overlay_economic_section_dark_tokens_support.dart';

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay dark editorial-monocle Economic section '
      'body (SPEC § Dark-theme Economic section body tokens)', () {
    testWidgets(
      'improved-resource row label resolves to EditorialMonoclePalette.fg',
      (WidgetTester tester) async {
        final tk = econDarkTokenTileKey(0, 0);
        await pumpEconDarkTokenOverlay(
          tester,
          tileKey: tk,
          improvementByTile: {tk: 2},
        );

        final finder = econDarkImprovedRowLabelFinder();
        expect(
          finder,
          findsAtLeastNWidgets(1),
          reason:
              'Test setup: with improvementByTile[$tk] = 2 the Economic '
              'section must render the "{terrain}/Grain with {impBase}" '
              'row label per province_economic_resourceRow + '
              'province_economic_withImprovement (app_en.arb).',
        );
        final Text label = tester.widget<Text>(finder.first);
        expect(
          label.style?.color,
          EditorialMonoclePalette.fg,
          reason:
              'Improved-resource row label must resolve TextStyle.color '
              'to EditorialMonoclePalette.fg per SPEC § Dark-theme '
              'Economic section body tokens (S6 — Economic body).',
        );
      },
    );

    testWidgets('improvable-resource row label resolves to '
        'EditorialMonoclePalette.muted', (WidgetTester tester) async {
      final tk = econDarkTokenTileKey(0, 0);
      await pumpEconDarkTokenOverlay(
        tester,
        tileKey: tk,
        improvementByTile: const {},
      );

      final finder = econDarkImprovableRowLabelFinder();
      expect(
        finder,
        findsAtLeastNWidgets(1),
        reason:
            'Test setup: with no improvement set, the Economic section '
            'must render the "{terrain}/Grain (improvable)" row label '
            'per province_economic_resourceRow + '
            'province_economic_improvableSuffix (app_en.arb).',
      );
      final Text label = tester.widget<Text>(finder.first);
      expect(
        label.style?.color,
        EditorialMonoclePalette.muted,
        reason:
            'Improvable-resource row label must resolve '
            'TextStyle.color to EditorialMonoclePalette.muted per SPEC '
            '§ Dark-theme Economic section body tokens (S6 — Economic '
            'body).',
      );
    });

    testWidgets(
      'negative: improved-resource row label does not fall back to bare '
      'Material defaults',
      (WidgetTester tester) async {
        final tk = econDarkTokenTileKey(0, 0);
        await pumpEconDarkTokenOverlay(
          tester,
          tileKey: tk,
          improvementByTile: {tk: 2},
        );

        final finder = econDarkImprovedRowLabelFinder();
        final Text label = tester.widget<Text>(finder.first);
        expect(
          label.style?.color,
          isNotNull,
          reason:
              'Material defaults regression guard: improved-row label '
              'must declare its own TextStyle.color rather than relying '
              'on DefaultTextStyle fall-through (so the contract survives '
              'a change in ambient bodyMedium colour).',
        );
        expect(
          label.style?.color,
          isNot(equals(Colors.white)),
          reason:
              'Material defaults regression guard: improved-row label '
              'must not resolve to the dark Material `Colors.white` '
              'fallback before the editorialMonocle overlay.',
        );
        expect(
          label.style?.color,
          equals(EditorialMonoclePalette.fg),
          reason:
              'Material defaults regression guard: improved-row label '
              'must resolve to EditorialMonoclePalette.fg (the single '
              'source).',
        );
      },
    );

    testWidgets('negative: improvable-resource row label is not '
        'Theme.colorScheme.onSurface and is not the dark Material default', (
      WidgetTester tester,
    ) async {
      final tk = econDarkTokenTileKey(0, 0);
      await pumpEconDarkTokenOverlay(
        tester,
        tileKey: tk,
        improvementByTile: const {},
      );

      final finder = econDarkImprovableRowLabelFinder();
      final Text label = tester.widget<Text>(finder.first);
      final BuildContext context = tester.element(finder.first);
      final Color onSurface = Theme.of(context).colorScheme.onSurface;
      expect(
        label.style?.color,
        isNotNull,
        reason:
            'Material defaults regression guard: improvable-row label '
            'must declare its own TextStyle.color rather than relying '
            'on DefaultTextStyle fall-through.',
      );
      expect(
        label.style?.color,
        isNot(equals(onSurface)),
        reason:
            'Material defaults regression guard: improvable-row label '
            'must not resolve to Theme.of(context).colorScheme.onSurface; '
            'use EditorialMonoclePalette.muted instead.',
      );
      expect(
        label.style?.color,
        isNot(equals(Colors.white)),
        reason:
            'Material defaults regression guard: improvable-row label '
            'must not resolve to the dark Material `Colors.white` '
            'fallback.',
      );
      expect(
        label.style?.color,
        equals(EditorialMonoclePalette.muted),
        reason:
            'Material defaults regression guard: improvable-row label '
            'must resolve to EditorialMonoclePalette.muted (the single '
            'source).',
      );
    });
  });
}
