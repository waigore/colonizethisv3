// Pins the dark editorial-monocle empty-state body tokens for
// ProvinceSeaZoneDetailOverlay. Positive paths fold Material-default
// guards via [expectMutedSingleSource] (Refs #4021 densify).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme empty-state body tokens (S9).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay, sampleSeaZoneIdForOverlay;

import 'editorial_monocle_dark_token_assertions.dart';
import 'province_overlay_dark_token_scenarios.dart';
import 'province_overlay_test_harness.dart';

List<Text> _emptyDashTextWidgets(WidgetTester tester) {
  return tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.data == '—')
      .toList(growable: false);
}

void _expectEmptyDashesMuted(WidgetTester tester, {required String context}) {
  final dashTexts = _emptyDashTextWidgets(tester);
  expect(
    dashTexts,
    isNotEmpty,
    reason: '$context must surface at least one empty-state em-dash.',
  );
  final onSurface = Theme.of(
    tester.element(find.byWidget(dashTexts.first)),
  ).colorScheme.onSurface;
  for (final dash in dashTexts) {
    expectMutedSingleSource(
      dash.style?.color,
      onSurface,
      '$context empty —',
    );
  }
}

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle empty-state '
    'body (SPEC § Dark-theme empty-state body tokens — S9)',
    () {
      testWidgets(
        'Economic (sparse) empty body em-dash is muted '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final base = demoGameForOverlay;
          final humanId = base.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: base,
            ownerId: humanId,
          );
          final game = sparseOverlayGame(base);

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: ownedProvince,
              draftOrders: const Orders(),
            ),
          );
          await tester.pumpAndSettle();
          _expectEmptyDashesMuted(
            tester,
            context: 'sparse province Economic/Military/Civilian/Naval',
          );
        },
      );

      testWidgets(
        'Naval (sea-zone) empty body em-dash is muted '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final base = demoGameForOverlay;
          final seaZoneId = sampleSeaZoneIdForOverlay;
          final game = gameWithNoFleets(base);

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: game,
              displayId: seaZoneId,
              draftOrders: const Orders(),
            ),
          );
          await tester.pumpAndSettle();
          _expectEmptyDashesMuted(
            tester,
            context: 'sea-zone Naval empty',
          );
        },
      );
    },
  );
}
