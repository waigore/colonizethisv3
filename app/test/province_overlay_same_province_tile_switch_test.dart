// Same-province tile switch: lazy tabs + read-model reuse (Refs #4690 AC3).

import 'package:colonizethis_app_fixtures/demo/province_overlay_demo_data.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/providers/province_overlay_read_model_cache_provider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'province_detail_overlay_host_support_fixtures.dart';
import 'province_sea_zone_overlay_detail_paths_support.dart';

void main() {
  suppressLogsForTests();

  test(
    'resolveProvinceOverlayProvinceReadModel reuses cache when tile key changes in same province (Refs #4690 AC3)',
    () {
      final cache = ProvinceOverlaySessionCache();
      final game = provinceDetailGameWithImprovedGrain(ownerId: 'gp1');
      final mapData = provinceDetailMapDataForProjection();
      const displayId = provinceDetailSupportProvinceId;

      final first = resolveProvinceOverlayProvinceReadModel(
        cache: cache,
        game: game,
        displayId: displayId,
        mapData: mapData,
      );
      final second = resolveProvinceOverlayProvinceReadModel(
        cache: cache,
        game: game,
        displayId: displayId,
        mapData: mapData,
      );

      expect(identical(first, second), isTrue);
    },
  );

  testWidgets(
    'narrow MAP20001 keeps unvisited tabs deferred when selected tile changes in same province (Refs #4690 AC3)',
    (WidgetTester tester) async {
      final binding = tester.view;
      final oldSize = binding.physicalSize;
      final oldRatio = binding.devicePixelRatio;
      addTearDown(() {
        binding.physicalSize = oldSize;
        binding.devicePixelRatio = oldRatio;
      });
      binding.physicalSize = const Size(400, 2000);
      binding.devicePixelRatio = 1.0;

      final game = demoGameForOverlay;
      final region = demoRegionForOverlay;
      final tiles = twoRevealedLandTilesInSameProvince(
        game: game,
        region: region,
      );
      final l10n = lookupAppLocalizations(const Locale('en'));
      var selectedTileKey = tiles.firstTileKey;
      final hostKey = GlobalKey<State<StatefulWidget>>();

      await tester.pumpWidget(
        StatefulBuilder(
          key: hostKey,
          builder: (context, setState) {
            return buildProvinceSeaZoneOverlayPathShell(
              game: game,
              region: region,
              displayId: tiles.provinceId,
              humanPlayerId: game.players.first.id,
              selectedTileKey: selectedTileKey,
            );
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text(l10n.provinceOverlay_sectionTile));
      await tester.pump();

      final firstCoords = overlayTileCoordsFromKey(tiles.firstTileKey);
      expect(
        find.text(
          l10n.provinceOverlay_tileCoordinates(firstCoords.x, firstCoords.y),
        ),
        findsWidgets,
      );
      expect(find.text(l10n.provinceOverlay_extractionHeading), findsNothing);

      hostKey.currentState!.setState(() {
        selectedTileKey = tiles.secondTileKey;
      });
      await tester.pump();

      final secondCoords = overlayTileCoordsFromKey(tiles.secondTileKey);
      expect(
        find.text(
          l10n.provinceOverlay_tileCoordinates(secondCoords.x, secondCoords.y),
        ),
        findsWidgets,
      );
      expect(
        find.text(
          l10n.provinceOverlay_tileCoordinates(firstCoords.x, firstCoords.y),
        ),
        findsNothing,
      );
      expect(find.text(l10n.provinceOverlay_extractionHeading), findsNothing);
    },
  );
}
