// Shared Game fixtures for CMPT10001 intel helper tests (Refs #4438).

import 'package:colonizethis_models/colonizethis_models.dart';

const kCmHumanId = 'gp_h';
const kCmRivalId = 'gp_r';
const kCmThirdId = 'gp_t';
const kCmHomeId = 'oldWorld|p_home';
const kCmBattleId = 'oldWorld|p_battle';
const kCmBattleTile = 'oldWorld|p_battle|0|0';
const kCmHomeTile = 'oldWorld|p_home|0|0';

Game buildCombatModeChoiceIntelGame({
  String battleOwnerId = kCmRivalId,
  String battleDisplayName = 'Lisbon',
  int fortLevel = 1,
  bool battleFullyVisible = true,
  List<Unit> units = const [],
  List<Province> extraProvinces = const [],
  List<Army> armies = const [],
}) {
  final visibility = <String, String>{
    kCmHomeTile: 'fullyVisible',
    kCmBattleTile: battleFullyVisible ? 'fullyVisible' : 'fogged',
  };
  return Game(
    id: 'g_cm',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: kCmHomeId,
            regionId: 'oldWorld',
            ownerId: kCmHumanId,
            displayName: 'Home',
          ),
          Province(
            id: kCmBattleId,
            regionId: 'oldWorld',
            ownerId: battleOwnerId,
            displayName: battleDisplayName,
            fortLevel: fortLevel,
          ),
          ...extraProvinces,
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      armies: armies,
      tileKeysByRegionAndProvince: const {
        'oldWorld': {
          kCmHomeId: [kCmHomeTile],
          kCmBattleId: [kCmBattleTile],
        },
      },
      playerVisibilityByTile: {kCmHumanId: visibility},
    ),
    players: const [
      Player(
        id: kCmHumanId,
        displayName: 'Human',
        isHuman: true,
        capitalProvinceId: kCmHomeId,
      ),
      Player(
        id: kCmRivalId,
        displayName: 'Rival',
        isHuman: false,
        capitalProvinceId: kCmBattleId,
      ),
      Player(id: kCmThirdId, displayName: 'Third', isHuman: false),
    ],
  );
}

Unit cmUnit({
  required String id,
  required String ownerId,
  required String locationProvinceId,
  String type = 'musketeers',
}) {
  return Unit(
    id: id,
    type: type,
    ownerId: ownerId,
    locationProvinceId: locationProvinceId,
  );
}
