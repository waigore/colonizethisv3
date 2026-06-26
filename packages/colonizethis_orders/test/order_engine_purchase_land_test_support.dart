import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Shared topology and [Game] builder for purchase-land validator tests.
///
/// Refs waigore/colonizethis#2216.
class PurchaseLandTestFixture {
  PurchaseLandTestFixture._();

  static const ow = 'oldWorld';
  static const minorProvinceId = '$ow|M1';
  static const tileKey = '$ow|M1|0|0';

  static MapTopology topology() => const MapTopology(
    nodes: [
      TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: 'M1', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: [TopologyEdge(id1: 'P1', id2: 'M1')],
  );

  static Game baseGame({
    required int treasury,
    List<OvertureState>? overtureStates,
    List<DiplomacyRelation>? diplomacyRelations,
    Map<String, String>? resourceByTileKey,
    Map<String, Set<String>>? playerProspectedTiles,
    Map<String, String>? purchasedTilesByTileKey,
  }) {
    return TestFixtures.minimalGame(
      id: 'g1',
      turnNumber: 0,
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'merchant1',
            type: kUnitTypeMerchant,
            ownerId: 'p1',
            locationProvinceId: minorProvinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      resourceByTileKey: resourceByTileKey ?? {tileKey: 'grain'},
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: {
        ow: {
          minorProvinceId: [tileKey],
          '$ow|P1': ['$ow|P1|0|0'],
        },
      },
      playerProspectedTiles: playerProspectedTiles,
      purchasedTilesByTileKey: purchasedTilesByTileKey,
      players: [
        Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
          capitalProvinceId: '$ow|P1',
          stockpile: const Stockpile(),
          treasury: treasury,
          techUnlocked: {kTechIdMerchantCompanies: true},
        ),
      ],
      minorNations: const [
        MinorNation(id: 'minor1', displayName: 'Minor 1'),
      ],
      overtureStates: overtureStates ?? const [],
      diplomacyRelations: diplomacyRelations ?? const [],
    );
  }
}
