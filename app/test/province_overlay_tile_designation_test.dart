// localized keys).

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show sampleProvinceIdForOverlay, sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';

import 'province_overlay_tile_designation_cases.dart';
import 'province_overlay_tile_designation_test_support.dart';

void main() {
  suppressLogsForTests();

  final l10n = lookupAppLocalizations(const Locale('en'));
  final provinceId = sampleProvinceIdForOverlay;
  final tileKey = sampleTileKeyForProvinceOverlay;

  group('provinceOverlayTileDesignationLine (Refs #3617 — logic)', () {
    for (final c in provinceOverlayTileDesignationLogicCases(
      l10n: l10n,
      provinceId: provinceId,
      tileKey: tileKey,
    )) {
      test(c.name, () {
        final game = c.game();
        final line = provinceOverlayTileDesignationLine(
          l10n: l10n,
          game: game,
          provinceId: provinceId,
          selectedTileKey: tileKey,
        );
        expect(line, c.want(game));
        if (c.also != null && line != null) {
          expect(line, c.also);
        }
      });
    }

    test('minor-nation capital tile resolves the minor display name', () {
      final base = provinceOverlayDesignationDemoGame;
      if (base.minorNations.isEmpty) {
        return;
      }
      final cleared = provinceOverlayWithoutMatchingCapitals(base);
      final cap = provinceOverlayCapitalTileFromKey(tileKey);
      final minors = <MinorNation>[
        cleared.minorNations.first.copyWith(capitalTile: cap),
        ...cleared.minorNations.skip(1),
      ];
      final game = cleared.copyWith(minorNations: minors);
      final provinceName = provinceOverlayProvinceDisplayName(game, provinceId);
      final expectedName =
          game.minorNations.first.displayName ?? game.minorNations.first.id;

      final line = provinceOverlayTileDesignationLine(
        l10n: l10n,
        game: game,
        provinceId: provinceId,
        selectedTileKey: tileKey,
      );

      expect(
        line,
        l10n.provinceOverlay_tileCapitalOf(provinceName, expectedName),
      );
    });
  });

  group(
    'ProvinceSeaZoneDetailOverlay Tile designation rendering (Refs #3617)',
    () {
      testWidgets('capital line renders between Terrain and Resource in fg '
          '(AC capital designation line)', (WidgetTester tester) async {
        final game = provinceOverlayWithFirstPlayerCapitalTile(
          provinceOverlayDesignationDemoGame,
          tileKey,
        );
        final expected = l10n.provinceOverlay_tileCapitalOf(
          provinceOverlayProvinceDisplayName(game, provinceId),
          game.players.first.displayName,
        );

        await pumpProvinceOverlayDesignation(
          tester,
          game: game,
          provinceId: provinceId,
          tileKey: tileKey,
        );

        final finder = find.text(expected);
        expect(finder, findsOneWidget);
        final Text row = tester.widget<Text>(finder);
        expect(row.style?.color, EditorialMonoclePalette.fg);

        final order = provinceOverlayTileTextDataInOrder(tester);
        final terrainIdx = order.indexWhere((d) => d.startsWith('Terrain: '));
        final designationIdx = order.indexOf(expected);
        final resourceIdx = order.indexWhere((d) => d.startsWith('Resource: '));
        expect(terrainIdx, greaterThanOrEqualTo(0));
        expect(resourceIdx, greaterThan(terrainIdx));
        expect(designationIdx, greaterThan(terrainIdx));
        expect(designationIdx, lessThan(resourceIdx));
      });

      for (final c in provinceOverlayTileDesignationRenderingCases(
        l10n: l10n,
        provinceId: provinceId,
        tileKey: tileKey,
      )) {
        testWidgets(c.name, (WidgetTester tester) async {
          final game = c.game();
          await pumpProvinceOverlayDesignation(
            tester,
            game: game,
            provinceId: provinceId,
            tileKey: tileKey,
          );
          c.assertUi(tester, game);
        });
      }

      testWidgets('unrevealed selected tile renders no designation line '
          '(AC suppressed for unrevealed)', (WidgetTester tester) async {
        final game = provinceOverlayWithFirstPlayerCapitalTile(
          provinceOverlayDesignationDemoGame,
          tileKey,
        );
        final parts = tileKey.split('|');
        final tx = int.parse(parts[parts.length - 2]);
        final ty = int.parse(parts.last);
        final region = provinceOverlayRegionWith(
          visibilityForCell: (c) =>
              c.x == tx && c.y == ty ? TileVisibility.unrevealed : c.visibility,
        );

        await pumpProvinceOverlayDesignation(
          tester,
          game: game,
          provinceId: provinceId,
          tileKey: tileKey,
          region: region,
        );

        expect(find.textContaining('the capital of'), findsNothing);
        expect(find.text('Terrain: ???'), findsOneWidget);
      });
    },
  );

  group('ProvinceSeaZoneDetailOverlay Tile designation goldens (Refs #3617)', () {
    for (final c in provinceOverlayTileDesignationGoldenCases(
      l10n: l10n,
      provinceId: provinceId,
      tileKey: tileKey,
    )) {
      testWidgets(c.name, (WidgetTester tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(const Size(600, 1000));
        final boundaryKey = ValueKey<String>(c.key);
        final game = c.game();

        await tester.pumpWidget(
          provinceOverlayDesignationGoldenHost(
            game: game,
            region: provinceOverlayDesignationDemoRegion,
            displayId: provinceId,
            selectedTileKey: tileKey,
            boundaryKey: boundaryKey,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(c.expectedText(game)), findsOneWidget);

        await expectLater(find.byKey(boundaryKey), matchesGoldenFile(c.golden));
      });
    }
  });
}
