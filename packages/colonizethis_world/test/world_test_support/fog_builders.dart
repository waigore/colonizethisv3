import 'package:colonizethis_models/colonizethis_models.dart';

import 'topology_builders.dart';

/// Minimal [Game] for spy-reveal fog timer tests.
Game spyRevealFogGame({
  required String spyPlayerId,
  required String targetOwnerId,
  required String provinceLocalId,
  required String tileKey,
  required String visibilityLevel,
  required int spyRevealTurns,
  int turnNumber = 1,
}) {
  const ow = kWorldTestOw;
  final provinceId = '$ow|$provinceLocalId';
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: TurnState(
        phase: TurnPhase.endOfTurn,
        turnNumber: turnNumber,
      ),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: ow, ownerId: targetOwnerId),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: {
        spyPlayerId: {tileKey: visibilityLevel},
      },
      tileKeysByRegionAndProvince: {
        ow: {
          provinceId: [tileKey],
        },
      },
      spyRevealTurnsByPlayer: {
        spyPlayerId: {provinceId: spyRevealTurns},
      },
    ),
    players: [
      Player(id: spyPlayerId, displayName: 'Spymaster', isHuman: true),
      if (targetOwnerId != spyPlayerId)
        Player(id: targetOwnerId, displayName: 'Target', isHuman: false),
    ],
  );
}
