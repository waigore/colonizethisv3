// Game and battle-context fixtures for buildQuickBattleInput scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'quick_battle_build_game_fixtures.dart';

export 'quick_battle_build_game_fixtures.dart';

/// Minimal two-unit game for [buildQuickBattleInput] smoke tests.
Game quickBattleBuildContextGame() {
  return twoUnitOldWorldBuildGame(
    attackerType: 'musketeers',
    defenderType: 'pikemen',
    players: const [
      Player(id: 'att', displayName: 'A', isHuman: true),
      Player(id: 'def', displayName: 'D', isHuman: true),
    ],
  );
}

/// [BattleContext] matching [quickBattleBuildContextGame].
BattleContext quickBattleBuildContext() => twoUnitOldWorldBuildContext();

/// Reserve and Napoleon-attacker games sharing the same [BattleContext].
({Game reserve, Game napoleon, BattleContext ctx})
napoleonLeaderComparisonFixtures() {
  final gameReserve = twoUnitOldWorldBuildGame(
    attackerType: 'pikemen',
    defenderType: 'pikemen',
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
  return (
    reserve: gameReserve,
    napoleon: gameNapoleon,
    ctx: twoUnitOldWorldBuildContext(),
  );
}

/// Fort-2 game with emplaced-siege-guns tech for virtual gun spawn tests.
({Game game, BattleContext ctx}) emplacedGunBuildFixtures() {
  final game = twoUnitOldWorldBuildGame(
    attackerType: 'musketeers',
    defenderType: 'pikemen',
    fortLevel: 2,
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
  return (game: game, ctx: twoUnitOldWorldBuildContext(fortLevel: 2));
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
          Province(id: provinceId, regionId: ow, ownerId: 'def', fortLevel: 2),
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
