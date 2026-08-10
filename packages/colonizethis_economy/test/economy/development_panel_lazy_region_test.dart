import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  suppressLogsForTests();

  test(
    'buildDevelopmentPanelRegionModel scopes owned provinces to region only (Refs #4175 Slice E)',
    () {
      const playerId = 'pl1';
      const owProvince = 'oldWorld|p1';
      const nwProvince = 'newWorld|n1';
      const owTile = 'oldWorld|p1|0|0';
      const nwTile = 'newWorld|n1|0|0';

      final owMap = tileMapFromGrids(
        grid: const [
          ['p1'],
        ],
        resourceGrid: const [
          [Resource.grain],
        ],
      );
      final nwMap = tileMapFromGrids(
        grid: const [
          ['n1'],
        ],
        resourceGrid: const [
          [Resource.timber],
        ],
      );

      final game = spainExtractorGame(
        tileState: const TileMapState(),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: owProvince,
              regionId: kRegionOldWorld,
              ownerId: playerId,
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: nwProvince,
              regionId: kRegionNewWorld,
              ownerId: playerId,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: {
          kRegionOldWorld: {owProvince: [owTile]},
          kRegionNewWorld: {nwProvince: [nwTile]},
        },
      );

      final tileMapByRegion = <String, TileMapResult>{
        kRegionOldWorld: owMap,
        kRegionNewWorld: nwMap,
      };
      const orders = Orders();
      final shared = buildDevelopmentPanelBuildContext(
        game: game,
        playerId: playerId,
        tileMapByRegion: tileMapByRegion,
        topology: MapTopology(),
        currentOrders: orders,
      );

      final owModel = buildDevelopmentPanelRegionModel(
        shared: shared,
        game: game,
        playerId: playerId,
        regionId: kRegionOldWorld,
        tileMapByRegion: tileMapByRegion,
        currentOrders: orders,
        provinceDisplayNamesById: const {owProvince: 'OW', nwProvince: 'NW'},
        playerDisplayNamesById: const {playerId: 'Spain'},
      );
      final nwModel = buildDevelopmentPanelRegionModel(
        shared: shared,
        game: game,
        playerId: playerId,
        regionId: kRegionNewWorld,
        tileMapByRegion: tileMapByRegion,
        currentOrders: orders,
        provinceDisplayNamesById: const {owProvince: 'OW', nwProvince: 'NW'},
        playerDisplayNamesById: const {playerId: 'Spain'},
      );

      expect(owModel.ownedScopes, hasLength(1));
      expect(owModel.ownedScopes.first.provinceId, owProvince);
      expect(nwModel.ownedScopes, hasLength(1));
      expect(nwModel.ownedScopes.first.provinceId, nwProvince);
      expect(
        owModel.ownedScopes.first.improvableCommodities.first.commodityId,
        CommodityCatalog.grain.id,
      );
      expect(
        nwModel.ownedScopes.first.improvableCommodities.first.commodityId,
        CommodityCatalog.timber.id,
      );
    },
  );
}
