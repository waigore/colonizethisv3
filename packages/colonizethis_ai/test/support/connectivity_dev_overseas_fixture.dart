/// Multi-region overseas port linkage scenario for AC-D3 (Refs #4176).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const String kConnectivityDevOverseasOw = 'oldWorld';
const String kConnectivityDevOverseasNw = 'newWorld';
const String kConnectivityDevOverseasPlayerId = 'gp1';
const String kConnectivityDevOverseasEngineerId = 'e1';

const String _owHome = '$kConnectivityDevOverseasOw|home';
const String _nwColony = '$kConnectivityDevOverseasNw|colony';
const String _owSeaLocal = 'owSea';
const String _nwSeaLocal = 'nwSea';

/// AC-D3: OW capital with seaboard port, NW colony with unconnected improved
/// resource, sea path linking regions; idle Engineer and materials for port +
/// in-province roads.
class ConnectivityDevOverseasFixture {
  ConnectivityDevOverseasFixture._({
    required this.game,
    required this.topology,
    required this.tileMapByRegion,
    required this.resourceTile,
    required this.portTile,
  });

  final Game game;
  final MapTopology topology;
  final Map<String, TileMapResult> tileMapByRegion;
  final String resourceTile;
  final String portTile;

  static ConnectivityDevOverseasFixture overseasPortLinkage() {
    const owCapTile = '$_owHome|0|0';
    const nwPortTile = '$_nwColony|0|0';
    const nwResourceTile = '$_nwColony|0|1';

    final owTiles = [owCapTile, '$_owHome|1|0'];
    final nwTiles = [nwPortTile, nwResourceTile];
    final visibility = {
      for (final t in [...owTiles, ...nwTiles]) t: 'fullyVisible',
    };

    final game = TestFixtures.minimalGame(
      players: [
        Player(
          id: kConnectivityDevOverseasPlayerId,
          displayName: 'GP',
          isHuman: false,
          capitalProvinceId: _owHome,
          capitalTile: CapitalTile(
            regionId: kConnectivityDevOverseasOw,
            provinceId: _owHome,
            x: 0,
            y: 0,
          ),
          stockpile: const Stockpile(
            quantities: {'lumber': 100, 'castIron': 100},
          ),
        ),
      ],
      oldWorld: RegionData(
        provinces: [
          Province(
            id: _owHome,
            regionId: kConnectivityDevOverseasOw,
            ownerId: kConnectivityDevOverseasPlayerId,
          ),
        ],
        units: const [],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: _nwColony,
            regionId: kConnectivityDevOverseasNw,
            ownerId: kConnectivityDevOverseasPlayerId,
          ),
        ],
        units: [
          Unit(
            id: kConnectivityDevOverseasEngineerId,
            type: kUnitTypeEngineer,
            ownerId: kConnectivityDevOverseasPlayerId,
            locationProvinceId: _nwColony,
            tileKey: nwPortTile,
          ),
        ],
      ),
      tileKeysByRegionAndProvince: {
        kConnectivityDevOverseasOw: {_owHome: owTiles},
        kConnectivityDevOverseasNw: {_nwColony: nwTiles},
      },
      playerVisibilityByTile: {
        kConnectivityDevOverseasPlayerId: visibility,
      },
      resourceByTileKey: {nwResourceTile: 'grain'},
      portsByProvinceSeaboard: {'$_owHome|$_owSeaLocal': owCapTile},
      tileState: TileMapState(
        improvementByTile: {nwResourceTile: 1},
        roadLevelByTile: {owCapTile: 4},
      ),
    );

    const topology = MapTopology(
      nodes: [
        TopologyNode(
          id: 'home',
          regionId: kConnectivityDevOverseasOw,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: _owSeaLocal,
          regionId: kConnectivityDevOverseasOw,
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: _nwSeaLocal,
          regionId: kConnectivityDevOverseasNw,
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: 'colony',
          regionId: kConnectivityDevOverseasNw,
          type: TopologyNodeType.province,
        ),
      ],
      edges: [
        TopologyEdge(id1: 'home', id2: _owSeaLocal),
        TopologyEdge(id1: _owSeaLocal, id2: _nwSeaLocal),
        TopologyEdge(id1: 'colony', id2: _nwSeaLocal),
      ],
    );

    final owTileMap = TileMapResult(
      width: 2,
      height: 1,
      grid: [
        ['home', 'home'],
      ],
    );
    final nwTileMap = TileMapResult(
      width: 1,
      height: 2,
      grid: [
        ['colony'],
        ['colony'],
      ],
    );

    return ConnectivityDevOverseasFixture._(
      game: game,
      topology: topology,
      tileMapByRegion: {
        kConnectivityDevOverseasOw: owTileMap,
        kConnectivityDevOverseasNw: nwTileMap,
      },
      resourceTile: nwResourceTile,
      portTile: nwPortTile,
    );
  }
}
