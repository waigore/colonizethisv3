// Shared civilian-relocation conquest fixture (Refs #3865, #4633).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'combat_resolver_test_support.dart';

const civilianRelocationOldWorld = 'oldWorld';

Game civilianRelocationConquestGame({required Unit civilian}) {
  const provinceId = '$civilianRelocationOldWorld|P1';
  const capProvince = '$civilianRelocationOldWorld|C1';
  return combatResolverMinimalGame(
    players: const [
      Player(id: 'att', displayName: 'Attacker', isHuman: true),
      Player(id: 'def', displayName: 'Defender', isHuman: true),
      Player(
        id: 'civ',
        displayName: 'CivOwner',
        isHuman: false,
        capitalProvinceId: capProvince,
        capitalTile: CapitalTile(
          regionId: civilianRelocationOldWorld,
          provinceId: 'C1',
          x: 0,
          y: 0,
        ),
      ),
    ],
    oldWorld: RegionData(
      provinces: const [
        Province(
          id: provinceId,
          regionId: civilianRelocationOldWorld,
          ownerId: 'def',
        ),
        Province(
          id: capProvince,
          regionId: civilianRelocationOldWorld,
          ownerId: 'civ',
        ),
      ],
      units: [
        Unit(
          id: 'att1',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: provinceId,
        ),
        Unit(
          id: 'def1',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: provinceId,
        ),
        civilian,
      ],
    ),
  );
}

BattleContext civilianRelocationBattleContext() {
  const provinceId = '$civilianRelocationOldWorld|P1';
  return const BattleContext(
    provinceId: provinceId,
    regionId: civilianRelocationOldWorld,
    defenderFactionId: 'def',
    defenderUnitIds: ['def1'],
    attackers: [
      AttackingSide(factionId: 'att', unitIds: ['att1'], generalMedals: 0),
    ],
    fortLevel: 0,
    terrain: 'plains',
  );
}
