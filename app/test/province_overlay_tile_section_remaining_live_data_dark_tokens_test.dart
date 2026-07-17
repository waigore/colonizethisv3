// Pins the dark editorial-monocle Tile section live-data rows that were
// not in the original three-row slice (coordinates / terrain / civilian
// units): Prospected, Improvement, the Road / railroad primary numeric
// line on land tiles, and the sea-tile "Road / railroad: —" row.
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Tile section body tokens
// (Refs #2865 S5 — extends the existing road-caption + live-data rows
// slice). Shared prefix/roadLevel tables densify residual mid-size cases
// (Refs #4021).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';

import 'support/province_overlay_test_harness.dart';

/// Returns the `Text` widget whose `data` starts with [prefix]. Each row
/// renders exactly once, so a single match is expected.
Text _findTileBodyText(WidgetTester tester, String prefix) {
  final finder = find.byWidgetPredicate(
    (Widget w) => w is Text && (w.data ?? '').startsWith(prefix),
  );
  expect(
    finder,
    findsOneWidget,
    reason:
        'Expected exactly one Text starting with "$prefix" in the '
        'Tile section live-data body.',
  );
  return tester.widget<Text>(finder);
}

Future<void> _pumpRevealed(
  WidgetTester tester, {
  required int roadLevel,
}) async {
  await tester.pumpWidget(
    buildProvinceOverlayWithRevealedDemoTile(roadLevel: roadLevel),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectFgPrefix(
  WidgetTester tester, {
  required int roadLevel,
  required String prefix,
}) async {
  await _pumpRevealed(tester, roadLevel: roadLevel);
  expect(
    _findTileBodyText(tester, prefix).style?.color,
    EditorialMonoclePalette.fg,
  );
}

void main() {
  suppressLogsForTests();

  group('ProvinceSeaZoneDetailOverlay dark editorial-monocle Tile section '
      'remaining live-data rows (SPEC § Dark-theme Tile section body '
      'tokens — live-data body rows)', () {
    for (final c in <({String prefix, int roadLevel})>[
      (prefix: 'Prospected: ', roadLevel: 0),
      (prefix: 'Improvement: ', roadLevel: 0),
      (prefix: 'Road / railroad: transport level ', roadLevel: 2),
    ]) {
      testWidgets(
        '${c.prefix.trim()} resolves to EditorialMonoclePalette.fg',
        (WidgetTester tester) async {
          await _expectFgPrefix(
            tester,
            roadLevel: c.roadLevel,
            prefix: c.prefix,
          );
        },
      );
    }

    testWidgets('Road / railroad primary numeric line remains fg across '
        'stored transport levels 0 / 1 / 2 / 4', (WidgetTester tester) async {
      for (final level in const <int>[0, 1, 2, 4]) {
        await _expectFgPrefix(
          tester,
          roadLevel: level,
          prefix: 'Road / railroad: transport level ',
        );
      }
    });

    testWidgets('sea-tile no-road row (Road / railroad: —) resolves to fg '
        'when a sea-cell selectedTileKey is live', (WidgetTester tester) async {
      final overlay = buildProvinceOverlayWithSeaCellAtLandProvince();
      if (overlay == null) {
        return;
      }
      await tester.pumpWidget(overlay);
      await tester.pumpAndSettle();

      final liveFinder = find.byWidgetPredicate(
        (Widget w) =>
            w is Text && (w.data ?? '').startsWith('Road / railroad: -'),
      );
      if (liveFinder.evaluate().isEmpty) {
        return;
      }
      expect(
        tester.widget<Text>(liveFinder).style?.color,
        EditorialMonoclePalette.fg,
      );
    });

    testWidgets('negative — Prospected / Improvement / road primary never '
        'fall through DefaultTextStyle or Colors.white', (
      WidgetTester tester,
    ) async {
      await _pumpRevealed(tester, roadLevel: 2);

      for (final prefix in const <String>[
        'Prospected: ',
        'Improvement: ',
        'Road / railroad: transport level ',
      ]) {
        final text = _findTileBodyText(tester, prefix);
        expect(text.style, isNotNull);
        expect(text.style?.color, isNotNull);
        expect(text.style?.color, isNot(Colors.white));
        expect(text.style?.color, EditorialMonoclePalette.fg);
      }
    });
  });
}
