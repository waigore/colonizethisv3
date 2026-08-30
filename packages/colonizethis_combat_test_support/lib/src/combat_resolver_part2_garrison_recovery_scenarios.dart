// Table-driven land resolver part-2 garrison recovery (Refs #3865).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';
import 'scenario_runner.dart';

BattleContext _recoveryCtx(String provinceId, String defenderFactionId) =>
    BattleContext(
      provinceId: provinceId,
      regionId: 'oldWorld',
      defenderFactionId: defenderFactionId,
      defenderUnitIds: const ['d1'],
      attackers: const [
        AttackingSide(
          factionId: 'att1',
          unitIds: ['aStrong'],
          generalMedals: 1,
        ),
        AttackingSide(factionId: 'att2', unitIds: []),
      ],
      fortLevel: 0,
      terrain: 'plains',
    );

Unit _recoveryAtt(String provinceId, String type) => Unit(
  id: 'aStrong',
  type: type,
  ownerId: 'att1',
  locationProvinceId: provinceId,
);

Unit _recoveryDef(String provinceId, String ownerId, String type) => Unit(
  id: 'd1',
  type: type,
  ownerId: ownerId,
  locationProvinceId: provinceId,
);

void _expectRecovered(Game after, String type) {
  final recovered = after.worldState.oldWorld.units
      .where((u) => u.id.startsWith('recover_'))
      .toList();
  expect(recovered, isNotEmpty);
  for (final u in recovered) {
    expect(u.type, type);
  }
}

const _recoveryAttackerPlayers = [
  Player(id: 'att1', displayName: 'A1', isHuman: true),
  Player(id: 'att2', displayName: 'A2', isHuman: true),
];

List<RunnableScenario> combatResolverPart2GarrisonRecoveryScenarios() => [
  RunnableScenario(
    scenarioId: 'crp2-gp-garrison-recovery-era4',
    label:
        'great power defender: recovered regiments match most-advanced infantry era 4',
    run: () {
      const provinceId = 'ma_gp';
      final game = landResolverMutualAnnihilationGame(
        provinceId: provinceId,
        defenderOwnerId: 'def',
        units: [
          _recoveryAtt(provinceId, 'rifle_infantry'),
          _recoveryDef(provinceId, 'def', 'guards'),
        ],
        players: [
          ..._recoveryAttackerPlayers,
          const Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );
      final after = resolveBattleContext(game, _recoveryCtx(provinceId, 'def'));
      _expectRecovered(after, garrisonRecoveryRegimentTypeForEra(4));
    },
  ),
  RunnableScenario(
    scenarioId: 'crp2-minor-garrison-recovery-era3',
    label: 'minor nation effective era 3: recovered regiments are grenadiers',
    run: () {
      const provinceId = 'ma_minor';
      final game = landResolverMutualAnnihilationGame(
        provinceId: provinceId,
        defenderOwnerId: 'minor1',
        turnNumber: 2,
        minorNations: const [
          MinorNation(id: 'minor1', effectiveMilitaryLevel: 3),
        ],
        units: [
          _recoveryAtt(provinceId, 'regulars'),
          _recoveryDef(provinceId, 'minor1', 'grenadiers'),
        ],
        players: _recoveryAttackerPlayers,
      );
      final after = resolveBattleContext(
        game,
        _recoveryCtx(provinceId, 'minor1'),
      );
      expect(garrisonRecoveryRegimentTypeForEra(3), 'grenadiers');
      _expectRecovered(after, 'grenadiers');
    },
  ),
  RunnableScenario(
    scenarioId: 'crp2-tribe-garrison-recovery-era1',
    label: 'tribe effective era 1: recovered regiments are arquebusiers',
    run: () {
      const provinceId = 'ma_tribe';
      final game = landResolverMutualAnnihilationGame(
        provinceId: provinceId,
        defenderOwnerId: 'tr1',
        turnNumber: 3,
        tribes: const [Tribe(id: 'tr1')],
        units: [
          _recoveryAtt(provinceId, 'bowmen'),
          _recoveryDef(provinceId, 'tr1', 'pikemen'),
        ],
        players: _recoveryAttackerPlayers,
      );
      final after = resolveBattleContext(game, _recoveryCtx(provinceId, 'tr1'));
      _expectRecovered(after, 'arquebusiers');
    },
  ),
];
