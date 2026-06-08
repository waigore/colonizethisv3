import 'package:colonizethis_models/colonizethis_models.dart';

/// Minimal games for turn news digest tests (`test/turn/turn_news_digest_test.dart`).
///
/// Refs waigore/colonizethis#2216.
Game turnNewsMinimalGame({required int turn}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
    ],
  );
}

Game turnNewsTwoGpGame({required int turn, required RelationState relState}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
      Player(id: 'gp2', displayName: 'B', isHuman: false, treasury: 0),
    ],
    diplomacyRelations: [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', state: relState),
    ],
  );
}

Game turnNewsGameWithProvinceVis({
  required int turn,
  required String fullProvinceId,
  required String regionId,
  required String localProvinceId,
  required String visibility,
  List<String> revealDone = const [],
}) {
  final tileKey = '$regionId|$localProvinceId|0|0';
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: turn),
      oldWorld: RegionData(
        provinces: [
          Province(id: fullProvinceId, regionId: regionId, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        regionId: {
          fullProvinceId: [tileKey],
        },
      },
      playerVisibilityByTile: {
        'gp1': {tileKey: visibility},
      },
      newsDigestProvinceRevealDoneIds: revealDone,
    ),
    players: const [
      Player(id: 'gp1', displayName: 'A', isHuman: true, treasury: 0),
    ],
  );
}
