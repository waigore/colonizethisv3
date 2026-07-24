// Pins dark editorial-monocle Naval section body tokens for
// ProvinceSeaZoneDetailOverlay (S7). Positive + Material-default regression
// guards share one pump per scenario (Refs #4021 densify).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Naval section body tokens.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show demoGameForOverlay;

import 'support/editorial_monocle_dark_token_assertions.dart';
import 'province_overlay_dark_token_scenarios.dart';
import 'support/province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Naval section '
    'body (SPEC § Dark-theme Naval section body tokens)',
    () {
      testWidgets(
        'pending NavalMoveOrder preview resolves to muted '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final setup = gameWithFleetAndPendingNavalMove(
            ownerId: humanId,
            provinceId: ownedProvince,
            destinationSeaZoneId: seaZoneIdForPendingNavalMove(game),
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          final previewFinder = find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').startsWith('Ordered:'),
          );
          expect(
            previewFinder,
            findsAtLeastNWidgets(1),
            reason: 'Pending NavalMoveOrder must render Ordered: preview.',
          );
          final Text previewLine = tester.widget<Text>(previewFinder.first);
          final onSurface =
              Theme.of(tester.element(previewFinder.first)).colorScheme.onSurface;
          expectMutedSingleSource(
            previewLine.style?.color,
            onSurface,
            'Naval pending NavalMoveOrder preview',
          );
        },
      );

      testWidgets(
        'in-port fleet-summary roster resolves to fg '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final setup = gameWithFleetAndPendingNavalMove(
            ownerId: humanId,
            provinceId: ownedProvince,
            destinationSeaZoneId: seaZoneIdForPendingNavalMove(game),
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          final fleetSummaryFinder = find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data ?? '').contains(' — ') &&
                !(w.data ?? '').startsWith('Ordered:'),
          );
          expect(
            fleetSummaryFinder,
            findsAtLeastNWidgets(1),
            reason: 'In-port fleet must render provinceOverlay_fleetSummary.',
          );
          final Text fleetSummaryLine = tester.widget<Text>(
            fleetSummaryFinder.first,
          );
          expectFgSingleSource(
            fleetSummaryLine.style?.color,
            'Naval fleet-summary roster',
          );
        },
      );
    },
  );
}
