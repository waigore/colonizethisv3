/// Combat-style scenarios for siege Quick Battle: virtual emplaced guns absorb
/// defender-side damage before/during regiment losses; fort may downgrade when
/// all guns are destroyed. SPEC/game/quick-battle.md, SPEC/program/quick-battle-resolution.md.
library;
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

QuickBattleInput _siegeInput({
  required int seed,
  required int fortLevel,
  required List<QuickBattleEmplacedGun> emplacedGuns,
  required int attackerRegiments,
  required int defenderRegiments,
}) {
  return QuickBattleInput(
    attackerFactionId: 'att',
    defenderFactionId: 'def',
    provinceId: 'scenario-province',
    regionId: kRegionOldWorld,
    fortLevel: fortLevel,
    emplacedGuns: emplacedGuns,
    attackerDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: List.generate(attackerRegiments, (i) => 'att-$i'),
          cohesion: 3,
        ),
      ],
      laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
    ),
    defenderDeployment: QuickBattleDeployment(
      groups: [
        QuickBattleGroup(
          lane: QuickBattleLane.center,
          line: QuickBattleLine.front,
          unitIds: List.generate(defenderRegiments, (i) => 'def-$i'),
          cohesion: 3,
        ),
      ],
      laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
    ),
    seed: seed,
    maxRounds: 3,
  );
}

QuickBattleEmplacedGun _gun(String id, {required int hp}) {
  return QuickBattleEmplacedGun(
    id: id,
    maxHp: hp,
    hp: hp,
    attackStrength: 2.0,
    defenseStrength: 2.0,
    rng: 11,
  );
}

void main() {
  group('Quick Battle siege scenarios (emplaced targeting)', () {
    test(
      'Scenario: concentrated fire destroys battery before garrison — conquest + fort downgrade',
      () {
        // Given: strong attacker siege vs small garrison; single gun with low HP.
        // When: Quick Battle resolves (high attacker pressure → high defLossFraction).
        // Then: battery destroyed, province flips, fortDowngradeFromDestroyedEmplaced.
        final input = _siegeInput(
          seed: 0,
          fortLevel: 1,
          emplacedGuns: [_gun('qb:emplaced:ow:s:0', hp: 3)],
          attackerRegiments: 50,
          defenderRegiments: 8,
        );
        final result = resolveQuickBattle(input);
        expect(result.winner, QuickBattleWinner.attacker);
        expect(result.provinceFlips, isTrue);
        expect(result.fortDowngradeFromDestroyedEmplaced, isTrue);
        expect(result.emplacedGunOutcomes, hasLength(1));
        expect(result.emplacedGunOutcomes.single.destroyed, isTrue);
        expect(result.emplacedGunOutcomes.single.hp, 0);
      },
    );

    test('Scenario: battery absorbs volleys — partial HP loss, fort stands', () {
      // Given: same posture but higher gun HP so three rounds do not wipe battery.
      // When: resolve Quick Battle.
      // Then: emplaced gun loses HP but survives; no fort downgrade.
      final input = _siegeInput(
        seed: 0,
        fortLevel: 1,
        emplacedGuns: [_gun('qb:emplaced:ow:s:0', hp: 8)],
        attackerRegiments: 35,
        defenderRegiments: 8,
      );
      final result = resolveQuickBattle(input);
      expect(result.emplacedGunOutcomes, hasLength(1));
      final gun = result.emplacedGunOutcomes.single;
      expect(gun.destroyed, isFalse);
      expect(gun.hp, lessThan(8));
      expect(gun.hp, greaterThan(0));
      expect(result.fortDowngradeFromDestroyedEmplaced, isFalse);
    });

    test('Scenario: two-gun battery — round-robin damage (sorted by id)', () {
      // Given: fort level 2, two virtual guns (ids :0 and :1).
      // When: sustained defender-side losses allocate gun HP in round-robin order.
      // Then: both guns damaged; HP difference stays within one hit of parity.
      final input = _siegeInput(
        seed: 1,
        fortLevel: 2,
        emplacedGuns: [
          _gun('qb:emplaced:ow:s:0', hp: 20),
          _gun('qb:emplaced:ow:s:1', hp: 20),
        ],
        attackerRegiments: 40,
        defenderRegiments: 6,
      );
      final result = resolveQuickBattle(input);
      expect(result.emplacedGunOutcomes, hasLength(2));
      final byId = {for (final o in result.emplacedGunOutcomes) o.id: o};
      expect(byId['qb:emplaced:ow:s:0']!.destroyed, isFalse);
      expect(byId['qb:emplaced:ow:s:1']!.destroyed, isFalse);
      expect(byId['qb:emplaced:ow:s:0']!.hp, lessThan(20));
      expect(byId['qb:emplaced:ow:s:1']!.hp, lessThan(20));
      final diff =
          (byId['qb:emplaced:ow:s:0']!.hp - byId['qb:emplaced:ow:s:1']!.hp)
              .abs();
      expect(
        diff,
        lessThanOrEqualTo(2),
        reason: 'round-robin keeps guns within small HP spread',
      );
    });

    test(
      'Scenario: triple battery (fort 3) — each piece tracked independently',
      () {
        final input = _siegeInput(
          seed: 2,
          fortLevel: 3,
          emplacedGuns: [
            _gun('qb:emplaced:ow:s:0', hp: 12),
            _gun('qb:emplaced:ow:s:1', hp: 12),
            _gun('qb:emplaced:ow:s:2', hp: 12),
          ],
          attackerRegiments: 55,
          defenderRegiments: 10,
        );
        final result = resolveQuickBattle(input);
        expect(result.emplacedGunOutcomes, hasLength(3));
        final totalHp = result.emplacedGunOutcomes.fold<int>(
          0,
          (s, o) => s + o.hp,
        );
        expect(
          totalHp,
          lessThan(12 * 3),
          reason: 'at least some gun HP was consumed',
        );
      },
    );

    test(
      'Scenario: no virtual guns — legacy aggregate emplaced lump still applies',
      () {
        final input = _siegeInput(
          seed: 0,
          fortLevel: 2,
          emplacedGuns: const [],
          attackerRegiments: 6,
          defenderRegiments: 4,
        );
        final result = resolveQuickBattle(input);
        expect(result.emplacedGunOutcomes, isEmpty);
        expect(result.fortDowngradeFromDestroyedEmplaced, isFalse);
        expect(result.winner, isNotNull);
      },
    );

    test(
      'Scenario: pipeline buildQuickBattleInput → resolve → apply reduces fort on conquest',
      () {
        // Given: wood fort (level 1), one virtual gun from builder, strong attacker stack.
        // When: seed 0 produces conquest with battery destroyed (found via parameter search).
        // Then: province flips, fort drops to 0.
        const provinceId = 'oldWorld|P-siege';
        const pipelineSeed = 0;
        final game = Game(
          id: 'g-siege',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: provinceId,
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
                    locationProvinceId: provinceId,
                  ),
                ),
                ...List.generate(
                  3,
                  (i) => Unit(
                    id: 'def-$i',
                    type: 'pikemen',
                    ownerId: 'def',
                    locationProvinceId: provinceId,
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
        final ctx = BattleContext(
          provinceId: provinceId,
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

        final input = buildQuickBattleInput(game, ctx, seed: pipelineSeed);
        expect(input.emplacedGuns.length, 1);
        final qbResult = resolveQuickBattle(input);
        expect(
          qbResult.fortDowngradeFromDestroyedEmplaced,
          isTrue,
          reason: 'battery should be eliminated under this scenario',
        );
        expect(qbResult.provinceFlips, isTrue);

        final after = applyQuickBattleResultToGame(game, ctx, qbResult);
        final province = after.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == provinceId,
        );
        expect(province.ownerId, 'att');
        expect(province.fortLevel, 0);
      },
    );
  });

  group('Quick Battle initiative scenarios', () {
    test(
      'Scenario: cavalry-heavy attacker gains first action and trades better',
      () {
        final attackerFirst = QuickBattleInput(
          attackerFactionId: 'att',
          defenderFactionId: 'def',
          provinceId: 'initiative-province',
          regionId: kRegionOldWorld,
          attackerDeployment: QuickBattleDeployment(
            groups: const [
              QuickBattleGroup(
                lane: QuickBattleLane.center,
                line: QuickBattleLine.front,
                unitIds: ['a1', 'a2', 'a3', 'a4', 'a5', 'a6'],
                cohesion: 3,
              ),
            ],
            laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
          ),
          defenderDeployment: QuickBattleDeployment(
            groups: const [
              QuickBattleGroup(
                lane: QuickBattleLane.center,
                line: QuickBattleLine.front,
                unitIds: ['d1', 'd2', 'd3', 'd4', 'd5', 'd6'],
                cohesion: 3,
              ),
            ],
            laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
          ),
          attackerCavalryShare: 1.0,
          defenderCavalryShare: 0.0,
          seed: 77,
        );
        final attackerFirstResult = resolveQuickBattle(
          attackerFirst,
          roundActions: const [
            QuickBattleRoundActions(
              attackerActions: [QuickBattleAction.assaultCharge],
              defenderActions: [QuickBattleAction.volleyFire],
            ),
            QuickBattleRoundActions(
              attackerActions: [QuickBattleAction.assaultCharge],
              defenderActions: [QuickBattleAction.volleyFire],
            ),
            QuickBattleRoundActions(
              attackerActions: [QuickBattleAction.assaultCharge],
              defenderActions: [QuickBattleAction.volleyFire],
            ),
          ],
        );

        final defenderFirst = QuickBattleInput(
          attackerFactionId: attackerFirst.attackerFactionId,
          defenderFactionId: attackerFirst.defenderFactionId,
          provinceId: attackerFirst.provinceId,
          regionId: attackerFirst.regionId,
          attackerDeployment: attackerFirst.attackerDeployment,
          defenderDeployment: attackerFirst.defenderDeployment,
          attackerCavalryShare: 0.0,
          defenderCavalryShare: 1.0,
          seed: 77,
        );
        final defenderFirstResult = resolveQuickBattle(
          defenderFirst,
          roundActions: const [
            QuickBattleRoundActions(
              attackerActions: [QuickBattleAction.assaultCharge],
              defenderActions: [QuickBattleAction.volleyFire],
            ),
            QuickBattleRoundActions(
              attackerActions: [QuickBattleAction.assaultCharge],
              defenderActions: [QuickBattleAction.volleyFire],
            ),
            QuickBattleRoundActions(
              attackerActions: [QuickBattleAction.assaultCharge],
              defenderActions: [QuickBattleAction.volleyFire],
            ),
          ],
        );

        expect(
          attackerFirstResult.attackerCasualties.length,
          lessThan(defenderFirstResult.attackerCasualties.length),
          reason: 'acting first should improve attacker trade in this setup',
        );
      },
    );
  });
}
