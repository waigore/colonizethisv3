// AC-3: Upgrade town only when selected tile is the province town tile.
// SPEC/ui/components/tile-radial-catalog.md (Refs #4570).
// Concern split under repo.app_test_file_size (Refs #4013, #4352, #4747):
// fixtures in tile_radial_host_catalog_upgrade_town_support.dart.

import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_catalog.dart';
import 'package:colonizethis_app/features/game/widgets/map_radial/tile_radial_host_catalog.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show buildPlayerView;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tile_radial_host_catalog_upgrade_town_support.dart';

void main() {
  suppressLogsForTests();

  test(
    'Upgrade town is in the radial catalog only on the province town tile',
    () {
      final game = upgradeTownCatalogGame();
      final region = upgradeTownCatalogRegion();
      final playerView = buildPlayerView(
        game,
        kUpgradeTownCatalogTopology,
        kUpgradeTownCatalogHumanPlayerId,
      );
      final cache = upgradeTownCatalogCache(game);

      final onTownContext = computeTileRadialHostCatalogContext(
        game: game,
        humanPlayerId: kUpgradeTownCatalogHumanPlayerId,
        tileKey: kUpgradeTownCatalogTownTileKey,
        region: region,
        playerView: playerView,
        workTargetSelectionCache: cache,
        draftOrders: const Orders(),
        mapData: kUpgradeTownCatalogMapData,
      );
      final onOtherContext = computeTileRadialHostCatalogContext(
        game: game,
        humanPlayerId: kUpgradeTownCatalogHumanPlayerId,
        tileKey: kUpgradeTownCatalogOtherTileKey,
        region: region,
        playerView: playerView,
        workTargetSelectionCache: cache,
        draftOrders: const Orders(),
        mapData: kUpgradeTownCatalogMapData,
      );
      final onTown = tileRadialHostCatalogLayout(
        catalogContext: onTownContext,
        tileKey: kUpgradeTownCatalogTownTileKey,
      );
      final onOther = tileRadialHostCatalogLayout(
        catalogContext: onOtherContext,
        tileKey: kUpgradeTownCatalogOtherTileKey,
      );

      expect(
        upgradeTownCatalogActions(onTown),
        contains(TileRadialCatalogAction.upgradeTown),
      );
      expect(
        upgradeTownCatalogActions(onOther),
        isNot(contains(TileRadialCatalogAction.upgradeTown)),
      );
    },
  );

  testWidgets(
    'enabled Upgrade town spoke caption is the pause gist (Refs #4747)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const SizedBox(),
        ),
      );
      final context = tester.element(find.byType(SizedBox));
      final l10n = appL10n(context);
      final game = upgradeTownCatalogGame();
      final region = upgradeTownCatalogRegion();
      final playerView = buildPlayerView(
        game,
        kUpgradeTownCatalogTopology,
        kUpgradeTownCatalogHumanPlayerId,
      );
      final catalogContext = computeTileRadialHostCatalogContext(
        game: game,
        humanPlayerId: kUpgradeTownCatalogHumanPlayerId,
        tileKey: kUpgradeTownCatalogTownTileKey,
        region: region,
        playerView: playerView,
        workTargetSelectionCache: upgradeTownCatalogCache(game),
        draftOrders: const Orders(),
        mapData: kUpgradeTownCatalogMapData,
      );
      final layout = tileRadialHostCatalogLayout(
        catalogContext: catalogContext,
        tileKey: kUpgradeTownCatalogTownTileKey,
      );
      final views = tileRadialHostSpokeViews(
        context: context,
        l10n: l10n,
        game: game,
        humanPlayerId: kUpgradeTownCatalogHumanPlayerId,
        tileKey: kUpgradeTownCatalogTownTileKey,
        draftOrders: const Orders(),
        catalogContext: catalogContext,
        spokes: layout.wedges,
      );
      final upgradeTown = views.firstWhere(
        (view) => view.action == TileRadialCatalogAction.upgradeTown,
      );
      expect(upgradeTown.enabled, isTrue);
      expect(upgradeTown.caption, contains('pause until level 4'));
      expect(upgradeTown.caption, contains('Takes 1 turn'));
    },
  );
}
