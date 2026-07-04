// Game and battle-context fixtures for buildQuickBattleInput scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

const _buildProvinceId = 'P1';
const _buildRegionId = 'oldWorld';

/// Minimal two-unit game for [buildQuickBattleInput] smoke tests.
Game quickBattleBuildContextGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: _buildProvinceId, regionId: _buildRegionId, ownerId: 'def'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: _buildProvinceId,
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: _buildProvinceId,
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: [
      Player(id: 'att', displayName: 'A', isHuman: true),
      Player(id: 'def', displayName: 'D', isHuman: true),
    ],
  );
}

/// [BattleContext] matching [quickBattleBuildContextGame].
BattleContext quickBattleBuildContext() {
  return BattleContext(
    provinceId: _buildProvinceId,
    regionId: _buildRegionId,
    defenderFactionId: 'def',
    defenderUnitIds: ['u2'],
    attackers: [
      AttackingSide(factionId: 'att', unitIds: ['u1']),
    ],
    fortLevel: 0,
    terrain: 'plains',
  );
}

/// Reserve and Napoleon-attacker games sharing the same [BattleContext].
({Game reserve, Game napoleon, BattleContext ctx}) napoleonLeaderComparisonFixtures() {
  final gameReserve = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(id: _buildProvinceId, regionId: _buildRegionId, ownerId: 'def'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'pikemen',
            ownerId: 'att',
            locationProvinceId: _buildProvinceId,
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: _buildProvinceId,
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'att', displayName: 'Att', isHuman: true),
      Player(id: 'def', displayName: 'Def', isHuman: true),
    ],
  );
  final gameNapoleon = gameReserve.copyWith(
    players: [
      gameReserve.players[0].copyWith(leaderKey: 'napoleon'),
      gameReserve.players[1],
    ],
  );
  const ctx = BattleContext(
    provinceId: _buildProvinceId,
    regionId: _buildRegionId,
    defenderFactionId: 'def',
    defenderUnitIds: ['u2'],
    attackers: [
      AttackingSide(factionId: 'att', unitIds: ['u1']),
    ],
    fortLevel: 0,
    terrain: 'plains',
  );
  return (reserve: gameReserve, napoleon: gameNapoleon, ctx: ctx);
}

/// Fort-2 game with emplaced-siege-guns tech for virtual gun spawn tests.
({Game game, BattleContext ctx}) emplacedGunBuildFixtures() {
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: _buildProvinceId,
            regionId: _buildRegionId,
            ownerId: 'def',
            fortLevel: 2,
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'musketeers',
            ownerId: 'att',
            locationProvinceId: _buildProvinceId,
          ),
          Unit(
            id: 'u2',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: _buildProvinceId,
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'att', displayName: 'A', isHuman: true, militaryLevel: 3),
      Player(
        id: 'def',
        displayName: 'D',
        isHuman: true,
        militaryLevel: 3,
        techUnlocked: {kTechEmplacedSiegeGuns: true},
      ),
    ],
  );
  const ctx = BattleContext(
    provinceId: _buildProvinceId,
    regionId: _buildRegionId,
    defenderFactionId: 'def',
    defenderUnitIds: ['u2'],
    attackers: [
      AttackingSide(factionId: 'att', unitIds: ['u1']),
    ],
    fortLevel: 2,
    terrain: 'plains',
  );
  return (game: game, ctx: ctx);
}

/// Game + context for [applyQuickBattleResultToGame] fort-downgrade without flip.
({Game game, BattleContext ctx}) fortDowngradeApplyFixtures() {
  const ow = kRegionOldWorld;
  const provinceId = '$ow|P1';
  final game = Game(
    id: 'g-fort',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: provinceId,
            regionId: ow,
            ownerId: 'def',
            fortLevel: 2,
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'pikemen',
            ownerId: 'def',
            locationProvinceId: provinceId,
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [Player(id: 'def', displayName: 'D', isHuman: true)],
  );
  const ctx = BattleContext(
    provinceId: provinceId,
    regionId: ow,
    defenderFactionId: 'def',
    defenderUnitIds: ['u1'],
    attackers: [
      AttackingSide(factionId: 'att', unitIds: ['x1']),
    ],
    fortLevel: 2,
    terrain: 'plains',
  );
  return (game: game, ctx: ctx);
}
