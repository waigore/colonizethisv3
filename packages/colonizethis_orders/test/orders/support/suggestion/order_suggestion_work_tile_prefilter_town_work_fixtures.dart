// Shared town-work prefilter scenario fixtures (Refs #3949 / #3971 wave 4).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const workTilePrefilterTownPlayerId = 'gp1';
const workTilePrefilterTownOldWorld = 'oldWorld';

const _townGpPlayers = [
  Player(id: workTilePrefilterTownPlayerId, displayName: 'GP', isHuman: true),
  Player(id: 'gp2', displayName: 'GP2', isHuman: false),
];

Province _townProvince({
  required String local,
  required String ownerId,
  required String townTileKey,
}) => Province(
  id: '$workTilePrefilterTownOldWorld|$local',
  regionId: workTilePrefilterTownOldWorld,
  ownerId: ownerId,
  townTileKey: townTileKey,
);

Game workTilePrefilterOwnedTownGame({
  required String ownedTownTile,
  required String otherTownTile,
}) => ordersOwRegionGame(
  id: 'g-town-prefilter',
  turnNumber: 1,
  players: _townGpPlayers,
  oldWorld: RegionData(
    provinces: [
      _townProvince(
        local: 'p1',
        ownerId: workTilePrefilterTownPlayerId,
        townTileKey: ownedTownTile,
      ),
      _townProvince(local: 'p2', ownerId: 'gp2', townTileKey: otherTownTile),
    ],
  ),
);

Game workTilePrefilterSingleTownGame({required String townTile}) =>
    ordersOwRegionGame(
      id: 'g-fort-prefilter',
      turnNumber: 1,
      players: const [
        Player(
          id: workTilePrefilterTownPlayerId,
          displayName: 'GP',
          isHuman: true,
        ),
      ],
      oldWorld: RegionData(
        provinces: [
          _townProvince(
            local: 'p1',
            ownerId: workTilePrefilterTownPlayerId,
            townTileKey: townTile,
          ),
        ],
      ),
    );

Game workTilePrefilterCacheGame({
  required String ownedTownTile,
  required String otherTownTile,
}) => ordersOwRegionGame(
  id: 'g-prefilter-cache',
  turnNumber: 1,
  players: _townGpPlayers,
  oldWorld: RegionData(
    provinces: [
      _townProvince(
        local: 'p1',
        ownerId: workTilePrefilterTownPlayerId,
        townTileKey: ownedTownTile,
      ),
      _townProvince(local: 'p2', ownerId: 'gp2', townTileKey: otherTownTile),
    ],
  ),
);
