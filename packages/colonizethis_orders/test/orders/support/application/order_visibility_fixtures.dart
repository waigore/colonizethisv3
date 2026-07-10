// Shared order-visibility fixtures (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

PlayerView orderVisibilityView0({
  Map<String, VisibilityLevel> visibilityByTile = const {},
  Map<String, Province> provincesById = const {},
}) {
  const playerId = 'gp1';
  const player = Player(id: playerId, displayName: 'P', isHuman: false);
  return PlayerView(
    playerId: playerId,
    player: player,
    ownUnitsById: const {},
    provincesById: provincesById,
    visibilityByTile: visibilityByTile,
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}

WorldState orderVisibilityWorldStateTwoLandTilesP1() {
  const full = 'oldWorld|p1';
  return WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(provinces: []),
    newWorld: const RegionData(provinces: []),
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        full: ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
      },
    },
  );
}

Unit orderVisibilityInfantryUnit({
  String id = 'u1',
  String ownerId = 'gp1',
  String locationProvinceId = 'oldWorld|p1',
  String? tileKey,
  String type = 'inf',
}) {
  return Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId,
    tileKey: tileKey,
  );
}

Province orderVisibilityOwnedProvince({
  required String regionId,
  required String localId,
  String ownerId = 'gp1',
}) {
  final fullId = '$regionId|$localId';
  return Province(
    id: fullId,
    regionId: regionId,
    displayName: localId.toUpperCase(),
    ownerId: ownerId,
  );
}
