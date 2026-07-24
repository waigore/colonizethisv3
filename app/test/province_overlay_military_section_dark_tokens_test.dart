// Pins dark editorial-monocle Military section body tokens for
// ProvinceSeaZoneDetailOverlay (S7). Positive + Material-default regression
// guards share one pump per scenario (Refs #4021 densify).
//
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme Military section body tokens.

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
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle Military section '
    'body (SPEC § Dark-theme Military section body tokens)',
    () {
      testWidgets(
        'owner sub-header and regiment type-count resolve to fg '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final setup = gameWithMilitaryDarkTokenUnit(
            ownerId: humanId,
            provinceId: ownedProvince,
          );

          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: setup.game,
              displayId: ownedProvince,
              draftOrders: setup.orders,
            ),
          );
          await tester.pumpAndSettle();

          final humanDisplayName = setup.game.players
              .firstWhere((p) => p.id == humanId)
              .displayName;
          expect(humanDisplayName, isNotEmpty);
          final renderedTexts = tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data ?? '')
              .toList();
          expect(
            find.text(humanDisplayName),
            findsAtLeastNWidgets(1),
            reason:
                'Owner sub-header "$humanDisplayName" must render. '
                'Visible: ${renderedTexts.where((s) => s.isNotEmpty).take(40).toList()}',
          );
          final Text ownerHeader = tester.widget<Text>(
            find.text(humanDisplayName),
          );
          expectFgSingleSource(ownerHeader.style?.color, 'Military owner');
          expect(
            ownerHeader.style?.fontWeight,
            FontWeight.w600,
            reason: 'Military owner sub-header must retain FontWeight.w600.',
          );

          final typeCountFinder = find.byWidgetPredicate(
            (w) =>
                w is Text && (w.data ?? '').trimLeft().startsWith('Pikemen:'),
          );
          expect(
            typeCountFinder,
            findsAtLeastNWidgets(1),
            reason: 'Appended pikemen must render as indented type-count.',
          );
          final Text typeCountLine = tester.widget<Text>(
            typeCountFinder.first,
          );
          expectFgSingleSource(
            typeCountLine.style?.color,
            'Military regiment type-count',
          );
        },
      );

      testWidgets(
        'pending land MoveOrder preview resolves to muted '
        '(with Material-default guards)',
        (WidgetTester tester) async {
          final game = demoGameForOverlay;
          final humanId = game.players.first.id;
          final ownedProvince = ownedProvinceIdInOldWorld(
            game: game,
            ownerId: humanId,
          );
          final tileKeys = game.worldState
              .tileKeysByRegionAndProvince['oldWorld']?[ownedProvince];
          expect(tileKeys, isNotNull);
          expect(tileKeys!, isNotEmpty);

          final setup = gameWithMilitaryDarkTokenUnit(
            ownerId: humanId,
            provinceId: ownedProvince,
            withPendingMove: true,
            destinationTileKey: tileKeys.first,
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
            reason: 'Pending regiment MoveOrder must render Ordered: line.',
          );
          final Text previewLine = tester.widget<Text>(previewFinder.first);
          final onSurface =
              Theme.of(tester.element(previewFinder.first)).colorScheme.onSurface;
          expectMutedSingleSource(
            previewLine.style?.color,
            onSurface,
            'Military pending MoveOrder preview',
          );
        },
      );
    },
  );
}
