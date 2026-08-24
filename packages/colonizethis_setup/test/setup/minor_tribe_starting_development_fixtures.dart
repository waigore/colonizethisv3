import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

Game buildGame({
  required CapitalTile? minorCapital,
  required CapitalTile? tribeCapital,
}) {
  final owProvinces = <Province>[
    Province(id: 'oldWorld|p_minor', regionId: 'oldWorld', ownerId: 'minor_1'),
  ];
  final nwProvinces = <Province>[
    Province(id: 'newWorld|p_tribe', regionId: 'newWorld', ownerId: 'tribe_1'),
  ];
  return TestFixtures.minimalGame(
    id: 'g_minor_tribe_dev',
    players: const <Player>[
      Player(id: 'gp1', displayName: 'Power 1', isHuman: true),
    ],
    minorNations: <MinorNation>[
      MinorNation(
        id: 'minor_1',
        displayName: 'Minor',
        capitalProvinceId: minorCapital == null ? null : 'oldWorld|p_minor',
        capitalTile: minorCapital,
      ),
    ],
    tribes: <Tribe>[
      Tribe(
        id: 'tribe_1',
        displayName: 'Tribe',
        capitalProvinceId: tribeCapital == null ? null : 'newWorld|p_tribe',
        capitalTile: tribeCapital,
      ),
    ],
    turnNumber: 0,
    oldWorld: RegionData(provinces: owProvinces),
    newWorld: RegionData(provinces: nwProvinces),
  );
}

TileMapResult resourceGrid({
  required int width,
  required int height,
  required String localId,
  required String regionId,
}) {
  return TileMapResult(
    width: width,
    height: height,
    grid: List.generate(height, (_) => List<String>.filled(width, localId)),
    terrainGrid: List.generate(
      height,
      (_) => List<TerrainType?>.filled(width, TerrainType.plains),
    ),
    resourceGrid: List.generate(
      height,
      (_) => List<Resource?>.filled(width, Resource.grain),
    ),
  );
}
