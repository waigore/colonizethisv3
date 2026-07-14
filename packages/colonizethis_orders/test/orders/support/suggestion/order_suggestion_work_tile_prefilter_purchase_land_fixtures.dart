// Shared purchase_land prefilter scenario fixtures (Refs #3949 / #3971 wave 4).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const workTilePrefilterPlayerId = 'gp1';
const workTilePrefilterOldWorld = 'oldWorld';

Player get _prefilterPlayer => Player(
  id: workTilePrefilterPlayerId,
  displayName: 'GP',
  isHuman: false,
  treasury: 500,
);

Province _prefilterProvince(String local, String ownerId) => Province(
  id: '$workTilePrefilterOldWorld|$local',
  regionId: workTilePrefilterOldWorld,
  ownerId: ownerId,
);

Game workTilePrefilterMinorGpGame({
  required String minorTile,
  required String gpTile,
}) => ordersOwRegionGame(
  turnNumber: 1,
  players: [_prefilterPlayer],
  oldWorld: RegionData(
    provinces: [
      _prefilterProvince('p1', workTilePrefilterPlayerId),
      _prefilterProvince('minor1', 'minor1'),
    ],
  ),
  tileKeysByRegionAndProvince: {
    workTilePrefilterOldWorld: {
      '$workTilePrefilterOldWorld|p1': [gpTile],
      '$workTilePrefilterOldWorld|minor1': [minorTile],
    },
  },
  resourceByTileKey: {minorTile: 'grain', gpTile: 'timber'},
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
);

Game workTilePrefilterTribeGame({required String tribeTile}) =>
    ordersOwRegionGame(
      turnNumber: 1,
      players: [_prefilterPlayer],
      oldWorld: RegionData(provinces: [_prefilterProvince('tribe1', 'tribe1')]),
      tileKeysByRegionAndProvince: {
        workTilePrefilterOldWorld: {
          '$workTilePrefilterOldWorld|tribe1': [tribeTile],
        },
      },
      resourceByTileKey: {tribeTile: 'grain'},
      tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
    );

Game workTilePrefilterBuildRoadGame({
  required String minorTile,
  required String gpTile,
}) => ordersOwRegionGame(
  turnNumber: 1,
  players: [_prefilterPlayer],
  oldWorld: RegionData(
    provinces: [
      _prefilterProvince('p1', workTilePrefilterPlayerId),
      _prefilterProvince('minor1', 'minor1'),
    ],
  ),
  tileKeysByRegionAndProvince: {
    workTilePrefilterOldWorld: {
      '$workTilePrefilterOldWorld|p1': [gpTile],
      '$workTilePrefilterOldWorld|minor1': [minorTile],
    },
  },
  minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
);
