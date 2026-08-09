import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Shared empty orders-phase [Game] for Full AI civilian-work selection pins.
Game civilianWorkSelectionGame({
  String playerId = 'gp1',
  Map<String, String> resourceByTileKey = const {},
  RegionData? oldWorld,
  Map<String, Map<String, String>> playerVisibilityByTile = const {},
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince = const {},
  List<Tribe> tribes = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: oldWorld ?? const RegionData(),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey,
      playerVisibilityByTile: playerVisibilityByTile,
      tileKeysByRegionAndProvince: tileKeysByRegionAndProvince,
    ),
    players: [Player(id: playerId, displayName: 'GP', isHuman: false)],
    tribes: tribes,
  );
}

/// Builder/Explorer [PlayerView] over [game] with a single owned civilian unit.
PlayerView civilianWorkSelectionView({
  required Game game,
  required String unitId,
  required String unitType,
  String playerId = 'gp1',
  String locationProvinceId = 'oldWorld|p1',
  String? tileKey,
  Map<String, VisibilityLevel> visibilityByTile = const {},
}) {
  return PlayerView(
    playerId: playerId,
    player: game.players.single,
    ownUnitsById: {
      unitId: Unit(
        id: unitId,
        type: unitType,
        ownerId: playerId,
        locationProvinceId: locationProvinceId,
        tileKey: tileKey,
      ),
    },
    provincesById: const {},
    visibilityByTile: visibilityByTile,
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}
