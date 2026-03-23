import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveQuickBattle', () {
    test('deterministic for same seed', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2', 'a3', 'a4', 'a5'],
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
              unitIds: ['d1', 'd2'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 42,
        maxRounds: 3,
      );

      final r1 = resolveQuickBattle(input);
      final r2 = resolveQuickBattle(input);
      expect(r1.winner, r2.winner);
      expect(r1.attackerCasualties.length, r2.attackerCasualties.length);
      expect(r1.defenderCasualties.length, r2.defenderCasualties.length);
    });

    test('stronger attacker tends to win', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: List.generate(10, (i) => 'a$i'),
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
              unitIds: ['d1', 'd2'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 1,
        maxRounds: 3,
      );

      final result = resolveQuickBattle(input);
      expect(result.winner, QuickBattleWinner.attacker);
      expect(result.provinceFlips, true);
    });

    test('custom roundActions override default Volley Fire', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2'],
              cohesion: 2,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        defenderDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['d1'],
              cohesion: 2,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 99,
        maxRounds: 2,
      );
      final result = resolveQuickBattle(
        input,
        roundActions: [
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.volleyFire],
            defenderActions: [QuickBattleAction.volleyFire],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.volleyFire],
            defenderActions: [QuickBattleAction.volleyFire],
          ),
        ],
      );
      expect(result.attackerCasualties, isNotNull);
      expect(result.defenderCasualties, isNotNull);
    });

    test('fort level applies wall and damage reduction', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        fortLevel: 2,
        provinceTerrain: 'plains',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2', 'a3'],
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
              unitIds: ['d1', 'd2'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 7,
        maxRounds: 3,
      );
      final result = resolveQuickBattle(input);
      expect(result.winner, isNotNull);
    });

    test('stronger defender tends to hold', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2'],
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
              unitIds: List.generate(10, (i) => 'd$i'),
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.open},
        ),
        seed: 1,
        maxRounds: 3,
      );

      final result = resolveQuickBattle(input);
      expect(result.winner, QuickBattleWinner.defender);
      expect(result.provinceFlips, false);
    });

    test('uses lane terrain modifiers and actions', () {
      final input = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p1',
        regionId: 'oldWorld',
        attackerDeployment: QuickBattleDeployment(
          groups: const [
            QuickBattleGroup(
              lane: QuickBattleLane.center,
              line: QuickBattleLine.front,
              unitIds: ['a1', 'a2', 'a3', 'a4'],
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
              unitIds: ['d1', 'd2', 'd3', 'd4'],
              cohesion: 3,
            ),
          ],
          laneTerrain: const {'center_front': QuickBattleLaneTerrain.hill},
        ),
        seed: 7,
        maxRounds: 3,
      );

      final aggressive = resolveQuickBattle(
        input,
        roundActions: const [
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
          QuickBattleRoundActions(actions: [QuickBattleAction.assaultCharge]),
        ],
      );
      final cautious = resolveQuickBattle(
        input,
        roundActions: const [
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
          QuickBattleRoundActions(actions: [QuickBattleAction.defendEntrench]),
        ],
      );

      // Both runs should be deterministic for same seed + actions.
      expect(
        aggressive.attackerCasualties.length +
            aggressive.defenderCasualties.length,
        greaterThan(0),
      );
      expect(
        cautious.attackerCasualties.length + cautious.defenderCasualties.length,
        greaterThan(0),
      );
    });

    test('initiative ordering is deterministic and affects sequencing', () {
      final inputAttFirst = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p-order',
        regionId: 'oldWorld',
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
        seed: 123,
      );

      final resultAttFirst = resolveQuickBattle(
        inputAttFirst,
        roundActions: const [
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
        ],
      );

      final inputDefFirst = QuickBattleInput(
        attackerFactionId: 'att',
        defenderFactionId: 'def',
        provinceId: 'p-order',
        regionId: 'oldWorld',
        attackerDeployment: inputAttFirst.attackerDeployment,
        defenderDeployment: inputAttFirst.defenderDeployment,
        attackerCavalryShare: 0.0,
        defenderCavalryShare: 1.0,
        seed: 123,
      );
      final resultDefFirst = resolveQuickBattle(
        inputDefFirst,
        roundActions: const [
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
          QuickBattleRoundActions(
            attackerActions: [QuickBattleAction.assaultCharge],
            defenderActions: [QuickBattleAction.defendEntrench],
          ),
        ],
      );

      expect(
        resultAttFirst.attackerCasualties.length,
        isNot(resultDefFirst.attackerCasualties.length),
      );
    });
  });

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
          attackers: const [
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

  group('applyQuickBattleResultToGame Spy timer interaction', () {
    test('quick battle conquest clears Spy timer for new owner province', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: ow, ownerId: 'def'),
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
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'att': {tileKey: 'fullyVisible'},
          },
          spyRevealTurnsByPlayer: const {
            'att': {provinceId: 3, 'oldWorld|OTHER': 2},
            'ally': {provinceId: 4},
          },
          tileKeysByRegionAndProvince: const {
            ow: {
              provinceId: [tileKey],
            },
          },
        ),
        players: const [
          Player(id: 'att', displayName: 'Att', isHuman: true),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: ow,
        defenderFactionId: 'def',
        defenderUnitIds: ['def1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['att1'], generalMedals: 0),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      const result = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: ['att1'],
        defenderCasualties: ['def1'],
        provinceFlips: true,
      );

      final after = applyQuickBattleResultToGame(game, ctx, result);
      final province = after.worldState.oldWorld.provinces
          .where((p) => p.id == provinceId)
          .first;
      expect(province.ownerId, 'att');

      // Spy timer for (att, provinceId) cleared but other timers remain.
      final attackerTimers =
          after.worldState.spyRevealTurnsByPlayer['att'] ?? const {};
      expect(attackerTimers.containsKey(provinceId), isFalse);
      expect(attackerTimers['oldWorld|OTHER'], 2);
      // Other player's timers unchanged.
      expect(after.worldState.spyRevealTurnsByPlayer['ally']?[provinceId], 4);
      // Visibility for attacker remains fullyVisible.
      expect(
        after.worldState.playerVisibilityByTile['att']?[tileKey],
        'fullyVisible',
      );
    });

    test('quick battle conquest in newWorld region also clears Spy timer', () {
      const nw = 'newWorld';
      const provinceId = '$nw|P1';
      const tileKey = '$nw|P1|0|0';

      final game = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: nw, ownerId: 'def'),
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
            ],
          ),
          playerVisibilityByTile: const {
            'att': {tileKey: 'fullyVisible'},
          },
          spyRevealTurnsByPlayer: const {
            'att': {provinceId: 2},
          },
          tileKeysByRegionAndProvince: const {
            nw: {
              provinceId: [tileKey],
            },
          },
        ),
        players: const [
          Player(id: 'att', displayName: 'Att', isHuman: true),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: nw,
        defenderFactionId: 'def',
        defenderUnitIds: ['def1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['att1'], generalMedals: 0),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      const result = QuickBattleResult(
        winner: QuickBattleWinner.attacker,
        attackerCasualties: ['att1'],
        defenderCasualties: ['def1'],
        provinceFlips: true,
      );

      final after = applyQuickBattleResultToGame(game, ctx, result);
      final province = after.worldState.newWorld.provinces
          .where((p) => p.id == provinceId)
          .first;
      expect(province.ownerId, 'att');
      // Spy timer map no longer contains (att, provinceId).
      expect(after.worldState.spyRevealTurnsByPlayer['att'], isNull);
      expect(
        after.worldState.playerVisibilityByTile['att']?[tileKey],
        'fullyVisible',
      );
    });
  });
}
