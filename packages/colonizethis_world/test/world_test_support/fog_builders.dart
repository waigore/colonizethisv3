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

/// Ownership-transfer visibility scenario (Refs #3968).
Game ownershipTransferVisibilityGame({
  required String provinceId,
  required String tileKey,
  required String formerOwnerId,
  required String newOwnerId,
  String formerVisibility = 'fullyVisible',
  String id = 'g',
}) {
  final regionId = ProvinceId.regionIdFrom(provinceId);
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: provinceId, regionId: regionId, ownerId: formerOwnerId),
        ],
      ),
      newWorld: const RegionData(),
      playerVisibilityByTile: {
        formerOwnerId: {tileKey: formerVisibility},
        newOwnerId: const {},
      },
      tileKeysByRegionAndProvince: {
        regionId: {
          provinceId: [tileKey],
        },
      },
    ),
    players: [
      Player(id: formerOwnerId, displayName: 'Former', isHuman: true),
      Player(id: newOwnerId, displayName: 'New', isHuman: true),
    ],
  );
}

/// Coastal sea-zone full-visibility scenario (Refs #3968).
Game coastalSeaVisibilityGame({
  required List<Province> provinces,
  required Map<String, Map<String, String>> playerVisibilityByTile,
  required Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince,
  required List<Player> players,
  String id = 'g1',
  TurnPhase phase = TurnPhase.endOfTurn,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: phase, turnNumber: 1),
      oldWorld: RegionData(provinces: provinces),
      newWorld: const RegionData(),
      playerVisibilityByTile: playerVisibilityByTile,
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    ),
    players: players,
  );
}

/// Distant-sea fog-revert scenario (Refs #3978).
Game distantSeaVisibilityGame({
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  required Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince,
  required List<Player> players,
  List<Fleet> fleets = const [],
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  int turnNumber = 0,
  String id = 'g1',
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.endOfTurn, turnNumber: turnNumber),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
      fleets: fleets,
      playerVisibilityByTile: playerVisibilityByTile,
    ),
    players: players,
  );
}

/// Immediate fog-decay visibility scenario (Refs #3978).
Game fogDecayVisibilityGame({
  List<Province> oldWorldProvinces = const [],
  List<Province> newWorldProvinces = const [],
  List<Unit> oldWorldUnits = const [],
  List<Unit> newWorldUnits = const [],
  required Map<String, Map<String, String>> playerVisibilityByTile,
  required List<Player> players,
  String id = 'g1',
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.endOfTurn, turnNumber: 1),
      oldWorld: RegionData(
        provinces: oldWorldProvinces,
        units: oldWorldUnits,
      ),
      newWorld: RegionData(
        provinces: newWorldProvinces,
        units: newWorldUnits,
      ),
      playerVisibilityByTile: playerVisibilityByTile,
    ),
    players: players,
  );
}
