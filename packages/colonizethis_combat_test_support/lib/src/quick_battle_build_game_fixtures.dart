// Shared two-unit Old World Quick Battle build fixtures (Refs #3865, #4633).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const quickBattleBuildProvinceId = 'P1';
const quickBattleBuildRegionId = 'oldWorld';

Game twoUnitOldWorldBuildGame({
  required String attackerType,
  required String defenderType,
  required List<Player> players,
  int fortLevel = 0,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: quickBattleBuildProvinceId,
            regionId: quickBattleBuildRegionId,
            ownerId: 'def',
            fortLevel: fortLevel,
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: attackerType,
            ownerId: 'att',
            locationProvinceId: quickBattleBuildProvinceId,
          ),
          Unit(
            id: 'u2',
            type: defenderType,
            ownerId: 'def',
            locationProvinceId: quickBattleBuildProvinceId,
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}

BattleContext twoUnitOldWorldBuildContext({int fortLevel = 0}) {
  return BattleContext(
    provinceId: quickBattleBuildProvinceId,
    regionId: quickBattleBuildRegionId,
    defenderFactionId: 'def',
    defenderUnitIds: ['u2'],
    attackers: [
      AttackingSide(factionId: 'att', unitIds: ['u1']),
    ],
    fortLevel: fortLevel,
    terrain: 'plains',
  );
}
