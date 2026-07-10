// Colonial discovery declare-war fixtures (Refs #3620, #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';

/// gp1 has OW home visibility only; tribe1 NW colony is sea-reachable but has
/// no tile visibility (first-contact gate not satisfied).
Game colonialDiscoveryNoNwVisibilityGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(id: 'oldWorld|home', regionId: 'oldWorld', ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(
        provinces: [
          Province(
            id: 'newWorld|colony',
            regionId: 'newWorld',
            ownerId: 'tribe1',
          ),
        ],
      ),
      playerVisibilityByTile: const {
        'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
      },
      tileKeysByRegionAndProvince: {
        'oldWorld': {
          'oldWorld|home': const ['oldWorld|home|0|0'],
        },
        'newWorld': {
          'newWorld|colony': const ['newWorld|colony|0|0'],
        },
      },
    ),
    players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
  );
}

PlayerView colonialDiscoveryViewFor(Game game) =>
    buildPlayerView(game, colonialAcquisitionTopology, 'gp1');
