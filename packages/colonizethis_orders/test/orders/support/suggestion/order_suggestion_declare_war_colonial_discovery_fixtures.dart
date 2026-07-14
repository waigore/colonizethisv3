// Colonial discovery declare-war fixtures (Refs #3620, #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';

/// gp1 has OW home visibility only; tribe1 NW colony is sea-reachable but has
/// no tile visibility (first-contact gate not satisfied).
Game colonialDiscoveryNoNwVisibilityGame() => colonialAcquisitionRegionGame(
  id: 'g1',
  players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
  playerVisibilityByTile: const {
    'gp1': {'oldWorld|home|0|0': 'fullyVisible'},
  },
);

PlayerView colonialDiscoveryViewFor(Game game) =>
    buildPlayerView(game, colonialAcquisitionTopology, 'gp1');
