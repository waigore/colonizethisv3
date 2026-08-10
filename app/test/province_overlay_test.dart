// Tests for ProvinceSeaZoneDetailOverlay. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart';
import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        demoRegionForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay,
        sampleTileKeyForProvinceOverlay;
import 'package:colonizethis_app/widgets/ct_icon_action.dart';

import 'province_overlay_core_test_support.dart';

void main() {
  suppressLogsForTests();

  group('demoGameForOverlay', () {
    test('returns game with Old World provinces and players', () {
      final game = demoGameForOverlay;
      expect(game.players.length, greaterThanOrEqualTo(1));
      expect(
        game.worldState.oldWorld.provinces.length,
        greaterThanOrEqualTo(1),
      );
      expect(
        game.worldState.tileKeysByRegionAndProvince.containsKey('oldWorld'),
        isTrue,
      );
    });
  });

  group('ProvinceSeaZoneDetailOverlay', () {
    testWidgets(
      'AC: province sections, name/owner, close, and sea-zone sections',
      (WidgetTester tester) async {
        final region = demoRegionForOverlay;
        final selectedId = sampleProvinceIdForOverlay;
        final cell = region.cells.firstWhere(
          (c) =>
              !c.isSea && '${region.regionId}|${c.regionCellId}' == selectedId,
        );
        final game = demoGameForOverlay;
        var closed = false;
        await pumpProvinceOverlayDemo(tester, onClose: () => closed = true);

        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
        expectProvinceOverlayTexts(const [
          'Province',
          'TILE',
          'POLITICAL',
          'ECONOMIC',
          'MILITARY',
          'CIVILIAN',
          'NAVAL',
        ]);
        expect(find.byKey(const Key('overlay_close')), findsOneWidget);

        final provinceName = cell.provinceDisplayName ?? cell.regionCellId;
        expect(provinceName, isNotEmpty);
        expect(find.textContaining(provinceName), findsAtLeastNWidgets(1));
        final ownerId = cell.ownerFactionId;
        if (ownerId != null && ownerId.isNotEmpty) {
          final ownerName =
              game.players
                  .where((p) => p.id == ownerId)
                  .map((p) => p.displayName)
                  .firstOrNull ??
              game.minorNations
                  .where((m) => m.id == ownerId)
                  .map((m) => m.displayName ?? m.id)
                  .firstOrNull ??
              ownerId;
          expect(find.textContaining(ownerName), findsAtLeastNWidgets(1));
        }

        await tester.tap(find.byKey(const Key('overlay_close')));
        await tester.pumpAndSettle();
        expect(closed, isTrue);

        await pumpProvinceOverlay(tester, displayId: sampleSeaZoneIdForOverlay);
        expect(find.byType(ProvinceSeaZoneDetailOverlay), findsOneWidget);
        expectProvinceOverlayTexts(const ['Sea zone', 'POLITICAL', 'NAVAL']);
      },
    );

    testWidgets('sea zone display name follows reveal/fog visibility', (
      WidgetTester tester,
    ) async {
      await pumpNamedSeaZoneOverlay(tester);
      expect(find.text('Sea zone: Named Test Sea'), findsOneWidget);

      await pumpNamedSeaZoneOverlay(
        tester,
        region: regionWithVisibility(
          demoRegionForOverlay,
          (_) => TileVisibility.unrevealed,
        ),
      );
      expect(find.textContaining('Named Test Sea'), findsNothing);
      expect(find.textContaining('Sea zone:'), findsNothing);
      expect(find.text('???'), findsWidgets);

      final seaParts = sampleSeaZoneIdForOverlay.split('|');
      final localSea = seaParts.length >= 2
          ? seaParts.sublist(1).join('|')
          : sampleSeaZoneIdForOverlay;
      var revealOneSeaInZone = true;
      await pumpNamedSeaZoneOverlay(
        tester,
        region: regionWithVisibility(demoRegionForOverlay, (c) {
          final inZone = c.isSea && c.regionCellId == localSea;
          if (inZone && revealOneSeaInZone) {
            revealOneSeaInZone = false;
            return TileVisibility.fogged;
          }
          return TileVisibility.unrevealed;
        }),
      );
      expect(find.text('Sea zone: Named Test Sea'), findsOneWidget);
    });

    testWidgets('tile shortcut tooltips: prospect / explore order / build', (
      WidgetTester tester,
    ) async {
      await pumpProvinceOverlayDemo(
        tester,
        showProspectActionIcon: true,
        prospectActionEnabled: true,
        onProspectWithExplorerTap: () {},
      );
      expect(find.byTooltip('Prospect with explorer'), findsOneWidget);

      await pumpProvinceOverlayDemo(
        tester,
        showExploreActionIcon: true,
        exploreActionEnabled: true,
        onExploreWithExplorerTap: () {},
        showProspectActionIcon: true,
        prospectActionEnabled: true,
        onProspectWithExplorerTap: () {},
        showBuildImprovementActionIcon: true,
        buildImprovementActionEnabled: true,
        buildImprovementActionHasBuilderUnits: true,
        onBuildImprovementTap: () {},
      );
      final exploreFinder = find.byTooltip('Explore with explorer');
      final prospectFinder = find.byTooltip('Prospect with explorer');
      final buildImprovementFinder = find.byWidgetPredicate(
        (widget) => widget is CtIconAction && widget.icon == Icons.handyman,
      );
      expect(exploreFinder, findsOneWidget);
      expect(prospectFinder, findsOneWidget);
      expect(buildImprovementFinder, findsOneWidget);
      expect(
        tester.getTopLeft(exploreFinder).dx,
        lessThan(tester.getTopLeft(prospectFinder).dx),
      );
    });

    testWidgets('AC: overlay height — narrow one-third vs desktop full', (
      WidgetTester tester,
    ) async {
      const viewportHeight = 600.0;
      for (final case_ in <({double width, double maxHeight})>[
        (width: 400, maxHeight: 198.0), // 0.33 * 600
        (width: 800, maxHeight: viewportHeight),
      ]) {
        await pumpProvinceOverlayDemo(
          tester,
          onClose: () {},
          mediaQuerySize: Size(case_.width, viewportHeight),
        );
        expectProvinceOverlayMaxHeight(case_.maxHeight);
      }
    });

    testWidgets(
      'Tile section shows ??? for unrevealed tiles in player-constrained view',
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
        final region = regionWithVisibility(
          baseRegion,
          (c) => c.x == targetCell.x && c.y == targetCell.y
              ? TileVisibility.unrevealed
              : c.visibility,
        );

        final selectedTileKey =
            '${region.regionId}|${targetCell.regionCellId}|${targetCell.x}|${targetCell.y}';
        final provinceId = '${region.regionId}|${targetCell.regionCellId}';

        await pumpProvinceOverlay(
          tester,
          displayId: provinceId,
          selectedTileKey: selectedTileKey,
          region: region,
          onClose: () {},
        );

        expect(find.textContaining('Coordinates: ???'), findsOneWidget);
        expect(find.textContaining('Terrain: ???'), findsOneWidget);
        expect(find.textContaining('Resource: ???'), findsOneWidget);
      },
    );

    testWidgets('Province sections use ??? when province is fully unrevealed', (
      WidgetTester tester,
    ) async {
      final region = regionWithVisibility(
        demoRegionForOverlay,
        (_) => TileVisibility.unrevealed,
      );
      final provinceId =
          '${region.regionId}|${region.cells.first.regionCellId}';

      await pumpProvinceOverlay(
        tester,
        displayId: provinceId,
        region: region,
        onClose: () {},
      );

      expect(find.text('???'), findsWidgets);
    });
  });
}
