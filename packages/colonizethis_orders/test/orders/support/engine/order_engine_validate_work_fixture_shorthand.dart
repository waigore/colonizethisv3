part of 'order_engine_validate_work_fixtures.dart';

Province _vwProvince({
  required String provinceId,
  required String ow,
  int fortLevel = 0,
  String? townTileKey,
  int? townDevelopmentLevel,
}) =>
    Province(
      id: provinceId,
      regionId: ow,
      ownerId: 'p1',
      fortLevel: fortLevel,
      townTileKey: townTileKey,
      townDevelopmentLevel: townDevelopmentLevel ?? kTownDevelopmentLevelMin,
    );

Game vwSingleProvinceUnitGame({
  required String unitId,
  required String unitType,
  Map<String, String>? resourceByTileKey,
  TileMapState tileState = const TileMapState(),
  Map<String, bool>? techUnlocked,
  Stockpile? stockpile,
  Map<String, Set<String>>? playerProspectedTiles,
  int fortLevel = 0,
  String? townTileKey,
  int? townDevelopmentLevel,
}) {
  const ow = ValidateWorkOw.ow;
  const provinceId = ValidateWorkOw.provinceId;
  const tileKey = ValidateWorkOw.tileKey;
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          _vwProvince(
            provinceId: provinceId,
            ow: ow,
            fortLevel: fortLevel,
            townTileKey: townTileKey,
            townDevelopmentLevel: townDevelopmentLevel,
          ),
        ],
        units: [
          Unit(
            id: unitId,
            type: unitType,
            ownerId: 'p1',
            locationProvinceId: provinceId,
            tileKey: tileKey,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: resourceByTileKey ?? const {},
      tileState: tileState,
      tileKeysByRegionAndProvince: const {
        ow: {
          provinceId: [tileKey],
        },
      },
      playerVisibilityByTile: const {
        'p1': {tileKey: 'fullyVisible'},
      },
      playerProspectedTiles: playerProspectedTiles ?? const {},
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'P1',
        isHuman: true,
        capitalProvinceId: provinceId,
        stockpile: stockpile ?? const Stockpile(),
        techUnlocked: techUnlocked ?? const {},
      ),
    ],
  );
}
