// Game and battle-context fixtures for siege pipeline scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Prefixed province id used by buildQuickBattleInput → resolve → apply pipeline.
const siegePipelineProvinceId = 'oldWorld|P-siege';

/// Wood-fort siege game: strong attacker stack vs small garrison with fort level 1.
Game siegePipelineGame() {
  return Game(
    id: 'g-siege',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: siegePipelineProvinceId,
            regionId: kRegionOldWorld,
            ownerId: 'def',
            fortLevel: 1,
          ),
        ],
        units: [
          ...List.generate(
            30,
            (i) => Unit(
              id: 'att-$i',
              type: 'pikemen',
              ownerId: 'att',
              locationProvinceId: siegePipelineProvinceId,
            ),
          ),
          ...List.generate(
            3,
            (i) => Unit(
              id: 'def-$i',
              type: 'pikemen',
              ownerId: 'def',
              locationProvinceId: siegePipelineProvinceId,
            ),
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'att', displayName: 'Att', isHuman: true),
      Player(
        id: 'def',
        displayName: 'Def',
        isHuman: true,
        militaryLevel: 3,
      ),
    ],
  );
}

/// Battle context matching [siegePipelineGame] unit ids and fort posture.
BattleContext siegePipelineBattleContext() {
  return BattleContext(
    provinceId: siegePipelineProvinceId,
    regionId: kRegionOldWorld,
    defenderFactionId: 'def',
    defenderUnitIds: ['def-0', 'def-1', 'def-2'],
    attackers: [
      AttackingSide(
        factionId: 'att',
        unitIds: List.generate(30, (i) => 'att-$i'),
      ),
    ],
    fortLevel: 1,
    terrain: 'plains',
  );
}
