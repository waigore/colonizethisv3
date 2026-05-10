import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('buildQuickBattleInput', () {
    test('builds input from BattleContext', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'P1', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'att',
                locationProvinceId: 'P1',
              ),
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'def',
                locationProvinceId: 'P1',
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
      final ctx = BattleContext(
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['u1']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final input = buildQuickBattleInput(game, ctx, seed: 5);
      expect(input.attackerFactionId, 'att');
      expect(input.defenderFactionId, 'def');
      expect(input.provinceId, 'P1');
      expect(input.attackerDeployment.groups.single.unitIds, ['u1']);
      expect(input.defenderDeployment.groups.single.unitIds, ['u2']);
      expect(input.attackerGeneralMedals, 0);
      expect(input.defenderGeneralMedals, 0);
    });

    test(
      'attacker with napoleon bonus wins more often than with reserve (same seed)',
      () {
        final gameReserve = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'P1', regionId: 'oldWorld', ownerId: 'def'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'pikemen',
                  ownerId: 'att',
                  locationProvinceId: 'P1',
                ),
                Unit(
                  id: 'u2',
                  type: 'pikemen',
                  ownerId: 'def',
                  locationProvinceId: 'P1',
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
          provinceId: 'P1',
          regionId: 'oldWorld',
          defenderFactionId: 'def',
          defenderUnitIds: ['u2'],
          attackers: [
            AttackingSide(factionId: 'att', unitIds: ['u1']),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );
        final inputReserve = buildQuickBattleInput(gameReserve, ctx, seed: 100);
        final inputNapoleon = buildQuickBattleInput(
          gameNapoleon,
          ctx,
          seed: 100,
        );
        expect(inputReserve.attackerLeaderMultiplier, 1.0);
        expect(inputNapoleon.attackerLeaderMultiplier, 1.25);

        final resultReserve = resolveQuickBattle(inputReserve);
        final resultNapoleon = resolveQuickBattle(inputNapoleon);
        expect(
          resultNapoleon.attackerCasualties.length,
          lessThanOrEqualTo(resultReserve.attackerCasualties.length),
          reason: 'Napoleon bonus should not increase attacker casualties',
        );
      },
    );
  });

  group('siege virtual emplaced guns (COL-151)', () {
    test('buildQuickBattleInput spawns guns by fort level and stable ids', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'P1',
                regionId: 'oldWorld',
                ownerId: 'def',
                fortLevel: 2,
              ),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'att',
                locationProvinceId: 'P1',
              ),
              Unit(
                id: 'u2',
                type: 'pikemen',
                ownerId: 'def',
                locationProvinceId: 'P1',
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
        provinceId: 'P1',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['u2'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['u1']),
        ],
        fortLevel: 2,
        terrain: 'plains',
      );

      final input = buildQuickBattleInput(game, ctx);
      expect(input.emplacedGuns.length, 2);
      expect(input.emplacedGuns[0].id, 'qb:emplaced:oldWorld:P1:0');
      expect(input.emplacedGuns[0].rng, 11); // heavy 10 + 1
      expect(
        input.emplacedGuns[0].maxHp,
        emplacedVirtualGunMaxHpByFortLevel[2],
      );
      expect(
        input.emplacedGuns[0].attackStrength,
        closeTo(fortEmplacedStrength[2] * 1.30 * 0.5 * 1.04, 1e-9),
      );
    });

    test('resolveQuickBattle duplicate runs match emplaced outcomes', () {
      final emplaced = [
        QuickBattleEmplacedGun(
          id: 'qb:emplaced:oldWorld:p1:0',
          maxHp: 4,
          hp: 4,
          attackStrength: 2.0,
          defenseStrength: 2.0,
          rng: 11,
        ),
      ];
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        fortLevel: 1,
        emplacedGuns: emplaced,
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(8, (i) => 'a$i'),
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
              unitIds: List.generate(6, (i) => 'd$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 12345,
        maxRounds: 3,
      );
      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(
        r1.fortDowngradeFromDestroyedEmplaced,
        r2.fortDowngradeFromDestroyedEmplaced,
      );
      expect(r1.emplacedGunOutcomes.length, r2.emplacedGunOutcomes.length);
      for (var i = 0; i < r1.emplacedGunOutcomes.length; i++) {
        expect(r1.emplacedGunOutcomes[i].id, r2.emplacedGunOutcomes[i].id);
        expect(r1.emplacedGunOutcomes[i].hp, r2.emplacedGunOutcomes[i].hp);
        expect(
          r1.emplacedGunOutcomes[i].destroyed,
          r2.emplacedGunOutcomes[i].destroyed,
        );
      }
      expect(r1.defenderCasualties, r2.defenderCasualties);
      expect(r1.attackerCasualties, r2.attackerCasualties);
    });

    test(
      'applyQuickBattleResultToGame downgrades fort when flag set without flip',
      () {
        const ow = 'oldWorld';
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
        const result = QuickBattleResult(
          winner: QuickBattleWinner.mutualExhaustion,
          attackerCasualties: [],
          defenderCasualties: [],
          provinceFlips: false,
          fortDowngradeFromDestroyedEmplaced: true,
          emplacedGunOutcomes: [
            QuickBattleEmplacedGunOutcome(id: 'g0', hp: 0, destroyed: true),
          ],
        );
        final after = applyQuickBattleResultToGame(game, ctx, result);
        final province = after.worldState.oldWorld.provinces.first;
        expect(province.ownerId, 'def');
        expect(province.fortLevel, 1);
      },
    );
  });
}
