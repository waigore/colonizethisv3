// Table-driven land resolver part-2 integration scenarios (Refs #3865).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_resolver_test_support.dart';

/// One row in a land resolver part-2 scenario table.
class CombatResolverPart2Scenario {
  const CombatResolverPart2Scenario({
    required this.scenarioId,
    required this.label,
    required this.run,
  });

  final String scenarioId;
  final String label;
  final void Function() run;
}

/// Runs [scenario].
void runCombatResolverPart2Scenario(CombatResolverPart2Scenario scenario) {
  scenario.run();
}

/// Scenarios for tie-break determinism and garrison recovery (part 2).
List<CombatResolverPart2Scenario> combatResolverPart2Scenarios() => [
      CombatResolverPart2Scenario(
        scenarioId: 'crp2-tie-break-deterministic',
        label: 'battle tie-break is deterministic for same seed and context',
        run: () {
          Game makeGame() => landResolverTieBreakGame();
          const ctx = BattleContext(
            provinceId: 'p',
            regionId: 'oldWorld',
            defenderFactionId: 'def',
            defenderUnitIds: ['d1'],
            attackers: [
              AttackingSide(factionId: 'attA', unitIds: ['a1']),
              AttackingSide(factionId: 'attB', unitIds: ['a2']),
            ],
            fortLevel: 0,
            terrain: 'plains',
          );

          final r1 = resolveBattleContext(makeGame(), ctx);
          final r2 = resolveBattleContext(makeGame(), ctx);
          expect(
            r1.worldState.oldWorld.provinces,
            r2.worldState.oldWorld.provinces,
          );
          expect(r1.worldState.oldWorld.units, r2.worldState.oldWorld.units);
          expect(r1.generals, r2.generals);
        },
      ),
      CombatResolverPart2Scenario(
        scenarioId: 'crp2-gp-garrison-recovery-era4',
        label:
            'great power defender: recovered regiments match most-advanced infantry era 4',
        run: () {
          const provinceId = 'ma_gp';
          final game = landResolverMutualAnnihilationGame(
            provinceId: provinceId,
            defenderOwnerId: 'def',
            units: [
              Unit(
                id: 'aStrong',
                type: 'rifle_infantry',
                ownerId: 'att1',
                locationProvinceId: provinceId,
              ),
              Unit(
                id: 'd1',
                type: 'guards',
                ownerId: 'def',
                locationProvinceId: provinceId,
              ),
            ],
            players: const [
              Player(id: 'att1', displayName: 'A1', isHuman: true),
              Player(id: 'att2', displayName: 'A2', isHuman: true),
              Player(id: 'def', displayName: 'Def', isHuman: true),
            ],
          );
          final ctx = BattleContext(
            provinceId: provinceId,
            regionId: 'oldWorld',
            defenderFactionId: 'def',
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
          final after = resolveBattleContext(game, ctx);
          final expected = garrisonRecoveryRegimentTypeForEra(4);
          final recovered = after.worldState.oldWorld.units
              .where((u) => u.id.startsWith('recover_'))
              .toList();
          expect(recovered, isNotEmpty);
          for (final u in recovered) {
            expect(u.type, expected);
          }
        },
      ),
      CombatResolverPart2Scenario(
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
              Unit(
                id: 'aStrong',
                type: 'regulars',
                ownerId: 'att1',
                locationProvinceId: provinceId,
              ),
              Unit(
                id: 'd1',
                type: 'grenadiers',
                ownerId: 'minor1',
                locationProvinceId: provinceId,
              ),
            ],
            players: const [
              Player(id: 'att1', displayName: 'A1', isHuman: true),
              Player(id: 'att2', displayName: 'A2', isHuman: true),
            ],
          );
          final ctx = BattleContext(
            provinceId: provinceId,
            regionId: 'oldWorld',
            defenderFactionId: 'minor1',
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
          final after = resolveBattleContext(game, ctx);
          expect(garrisonRecoveryRegimentTypeForEra(3), 'grenadiers');
          final recovered = after.worldState.oldWorld.units
              .where((u) => u.id.startsWith('recover_'))
              .toList();
          expect(recovered, isNotEmpty);
          for (final u in recovered) {
            expect(u.type, 'grenadiers');
          }
        },
      ),
      CombatResolverPart2Scenario(
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
              Unit(
                id: 'aStrong',
                type: 'bowmen',
                ownerId: 'att1',
                locationProvinceId: provinceId,
              ),
              Unit(
                id: 'd1',
                type: 'pikemen',
                ownerId: 'tr1',
                locationProvinceId: provinceId,
              ),
            ],
            players: const [
              Player(id: 'att1', displayName: 'A1', isHuman: true),
              Player(id: 'att2', displayName: 'A2', isHuman: true),
            ],
          );
          final ctx = BattleContext(
            provinceId: provinceId,
            regionId: 'oldWorld',
            defenderFactionId: 'tr1',
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
          final after = resolveBattleContext(game, ctx);
          final recovered = after.worldState.oldWorld.units
              .where((u) => u.id.startsWith('recover_'))
              .toList();
          expect(recovered, isNotEmpty);
          for (final u in recovered) {
            expect(u.type, 'arquebusiers');
          }
        },
      ),
    ];
