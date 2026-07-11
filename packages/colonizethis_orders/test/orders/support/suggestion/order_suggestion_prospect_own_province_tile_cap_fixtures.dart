// Own-province prospect tile-cap fixtures (Refs #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const prospectOwnProvinceTileCapPlayerId = 'gp1';
const prospectOwnProvinceTileCapOw = kRegionOldWorld;
const prospectOwnProvinceTileCapProvinceId = 'oldWorld|home';
const prospectOwnProvinceTileCapFeedstockTileKey = 'oldWorld|home|9|0';

Game prospectOwnProvinceTileCapGame() {
  final mineralTiles = <String>[
    'oldWorld|home|0|0',
    'oldWorld|home|1|0',
    'oldWorld|home|2|0',
    'oldWorld|home|3|0',
    prospectOwnProvinceTileCapFeedstockTileKey,
  ];
  return ordersOwRegionGame(
    id: 'g',
    turnNumber: 1,
    players: const [
      Player(
        id: prospectOwnProvinceTileCapPlayerId,
        displayName: 'GP',
        isHuman: false,
      ),
    ],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: prospectOwnProvinceTileCapProvinceId,
          regionId: prospectOwnProvinceTileCapOw,
          ownerId: prospectOwnProvinceTileCapPlayerId,
        ),
      ],
      units: [
        Unit(
          id: 'e1',
          type: kUnitTypeExplorer,
          ownerId: prospectOwnProvinceTileCapPlayerId,
          locationProvinceId: prospectOwnProvinceTileCapProvinceId,
        ),
      ],
    ),
    playerVisibilityByTile: {
      prospectOwnProvinceTileCapPlayerId: {
        for (final tk in mineralTiles) tk: 'fogged',
      },
    },
    resourceByTileKey: {for (final tk in mineralTiles) tk: 'iron'},
    tileKeysByRegionAndProvince: {
      prospectOwnProvinceTileCapOw: {
        prospectOwnProvinceTileCapProvinceId: mineralTiles,
      },
    },
  );
}

MapTopology prospectOwnProvinceTileCapTopology(Game game) =>
    ordersProvinceTopology(
      game.worldState.oldWorld.provinces,
      regionId: prospectOwnProvinceTileCapOw,
    );
