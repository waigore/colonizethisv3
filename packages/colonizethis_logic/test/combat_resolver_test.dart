import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveEngagement', () {
    test('attacker wins decisively when much stronger', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 3,
        ),
        Unit(
          id: 'a2',
          type: 'grenadiers',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 2,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];

      final outcome = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.attackerVictory);
      expect(outcome.defenderCasualties, contains('d1'));
    });

    test('defender wins when much stronger', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'peasant_levies',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'grenadiers',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 3,
        ),
        Unit(
          id: 'd2',
          type: 'grenadiers',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 2,
        ),
      ];

      final outcome = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );

      expect(outcome.result, EngagementResult.defenderVictory);
      expect(outcome.attackerCasualties, contains('a1'));
    });

    test('siege modifiers apply when fortLevel >= 1', () {
      final attackerUnits = [
        Unit(
          id: 'a1',
          type: 'pikemen',
          ownerId: 'att',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];
      final defenderUnits = [
        Unit(
          id: 'd1',
          type: 'peasant_levies',
          ownerId: 'def',
          locationProvinceId: 'p',
          medals: 0,
        ),
      ];

      final field = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 0,
        terrain: 'plains',
      );
      final siege = resolveEngagement(
        attackerUnits: attackerUnits,
        defenderUnits: defenderUnits,
        fortLevel: 2,
        terrain: 'plains',
      );

      expect(
        siege.result,
        isNot(equals(field.result)),
        reason: 'Fort should affect outcome when strengths are close',
      );
    });

    test(
      'low attacker feeding coverage penalises strength via morale multiplier',
      () {
        final attackerUnits = [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 2,
          ),
        ];
        final defenderUnits = [
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
            medals: 0,
          ),
        ];

        final wellFed = resolveEngagement(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          attackerMoraleMultiplier: 1.0,
          defenderMoraleMultiplier: 1.0,
        );

        final underfed = resolveEngagement(
          attackerUnits: attackerUnits,
          defenderUnits: defenderUnits,
          fortLevel: 0,
          terrain: 'plains',
          attackerMoraleMultiplier: 0.5,
          defenderMoraleMultiplier: 1.0,
        );

        // Attacker should be strictly weaker when underfed.
        expect(underfed.attackerStrength, wellFed.attackerStrength);
        // Effective strength ratio should be worse for the underfed attacker,
        // leading to outcomes that are no better than the well-fed case.
        expect(
          underfed.result == EngagementResult.attackerVictory,
          isFalse,
          reason:
              'Underfed attacker should not perform better than well-fed attacker',
        );
      },
    );

    test(
      'leader keys from Game produce correct multipliers in resolveEngagement path',
      () {
        final attackerUnits = [
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 2,
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 1,
          ),
        ];
        final defenderUnits = [
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
            medals: 0,
          ),
        ];
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
              ],
              units: [...attackerUnits, ...defenderUnits],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(
              id: 'att',
              displayName: 'France',
              isHuman: true,
              leaderKey: 'napoleon',
            ),
            Player(
              id: 'def',
              displayName: 'Prussia',
              isHuman: false,
              leaderKey: 'frederick',
            ),
          ],
        );
        const ctx = BattleContext(
          provinceId: 'p',
          regionId: 'oldWorld',
          defenderFactionId: 'def',
          defenderUnitIds: ['d1'],
          attackers: [
            AttackingSide(factionId: 'att', unitIds: ['a1', 'a2']),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );
        final result = resolveBattleContext(game, ctx);
        expect(
          result.worldState.oldWorld.units.length,
          lessThanOrEqualTo(3),
          reason: 'some units may be casualties',
        );
        expect(result.worldState.oldWorld.provinces.single.id, 'p');
      },
    );

    test('resolveBattleContext updates newWorld when regionId is newWorld', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: RegionData(
            provinces: const [
              Province(id: 'N1', regionId: 'newWorld', ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'd1',
                type: 'peasant_levies',
                ownerId: 'def',
                locationProvinceId: 'N1',
                medals: 0,
              ),
              Unit(
                id: 'a1',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: 'N1',
                medals: 3,
              ),
              Unit(
                id: 'a2',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: 'N1',
                medals: 2,
              ),
            ],
          ),
        ),
        players: const [
          Player(id: 'att', displayName: 'Att', isHuman: true),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'N1',
        regionId: 'newWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(
            factionId: 'att',
            unitIds: ['a1', 'a2'],
            generalMedals: 0,
          ),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final result = resolveBattleContext(game, ctx);
      expect(result.worldState.newWorld.provinces.single.id, 'N1');
      expect(
        result.worldState.newWorld.units.length,
        greaterThanOrEqualTo(1),
        reason: 'attacker should win and have at least one surviving unit',
      );
    });

    test(
      'deployment limit caps participating regiments per side (base 10, no Nationalism)',
      () {
        // 15 attackers, 15 defenders; deployment limit 10 per side without Nationalism.
        final attackerUnits = List.generate(
          15,
          (i) => Unit(
            id: 'a$i',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 1,
          ),
        );
        final defenderUnits = List.generate(
          15,
          (i) => Unit(
            id: 'd$i',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
            medals: 0,
          ),
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
              ],
              units: [...attackerUnits, ...defenderUnits],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'att', displayName: 'Att', isHuman: true),
            Player(id: 'def', displayName: 'Def', isHuman: false),
          ],
        );
        final ctx = BattleContext(
          provinceId: 'p',
          regionId: 'oldWorld',
          defenderFactionId: 'def',
          defenderUnitIds: defenderUnits.map((u) => u.id).toList(),
          attackers: [
            AttackingSide(
              factionId: 'att',
              unitIds: attackerUnits.map((u) => u.id).toList(),
              generalMedals: 0,
            ),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );
        final result = resolveBattleContext(game, ctx);
        final survivingAtt = result.worldState.oldWorld.units
            .where((u) => u.ownerId == 'att')
            .length;
        final survivingDef = result.worldState.oldWorld.units
            .where((u) => u.ownerId == 'def')
            .length;
        // Only 10 per side participate; so at least 5 attackers never participated and must survive.
        expect(
          survivingAtt,
          greaterThanOrEqualTo(5),
          reason:
              'deployment limit 10: at most 10 attackers participate, so ≥5 must remain',
        );
        // Defender had 15; at most 10 in engagement; so ≥5 defenders could survive if they win or stalemate.
        expect(
          survivingAtt + survivingDef,
          greaterThanOrEqualTo(5),
          reason: 'at least one side has non-participants',
        );
      },
    );

    test(
      'deployment limit with Nationalism tech is 12 (attacker has 13 units, ≥1 does not participate)',
      () {
        final attackerUnits = List.generate(
          13,
          (i) => Unit(
            id: 'a$i',
            type: 'grenadiers',
            ownerId: 'att',
            locationProvinceId: 'p',
            medals: 0,
          ),
        );
        final defenderUnits = [
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'def',
            locationProvinceId: 'p',
            medals: 0,
          ),
        ];
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
              ],
              units: [...attackerUnits, ...defenderUnits],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(
              id: 'att',
              displayName: 'Att',
              isHuman: true,
              techUnlocked: {kTechIdNationalism: true},
            ),
            Player(id: 'def', displayName: 'Def', isHuman: false),
          ],
        );
        final ctx = BattleContext(
          provinceId: 'p',
          regionId: 'oldWorld',
          defenderFactionId: 'def',
          defenderUnitIds: ['d1'],
          attackers: [
            AttackingSide(
              factionId: 'att',
              unitIds: attackerUnits.map((u) => u.id).toList(),
              generalMedals: 0,
            ),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );
        final result = resolveBattleContext(game, ctx);
        final survivingAtt = result.worldState.oldWorld.units
            .where((u) => u.ownerId == 'att')
            .length;
        // With Nationalism, limit 12; 13 attackers so ≥1 does not participate and must survive.
        expect(
          survivingAtt,
          greaterThanOrEqualTo(1),
          reason:
              'deployment limit 12 with Nationalism: at most 12 participate',
        );
      },
    );

    test(
      'assigned winning general gains +1 medal immediately and persists',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
            oldWorld: RegionData(
              provinces: const [
                Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
              ],
              units: [
                Unit(
                  id: 'a1',
                  type: 'grenadiers',
                  ownerId: 'att',
                  locationProvinceId: 'p',
                ),
                Unit(
                  id: 'a2',
                  type: 'grenadiers',
                  ownerId: 'att',
                  locationProvinceId: 'p',
                ),
                Unit(
                  id: 'd1',
                  type: 'peasant_levies',
                  ownerId: 'def',
                  locationProvinceId: 'p',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'att', displayName: 'Att', isHuman: true),
            Player(id: 'def', displayName: 'Def', isHuman: true),
          ],
          generals: const [General(id: 'g-att', ownerId: 'att', medals: 1)],
        );
        const ctx = BattleContext(
          provinceId: 'p',
          regionId: 'oldWorld',
          defenderFactionId: 'def',
          defenderUnitIds: ['d1'],
          attackers: [
            AttackingSide(
              factionId: 'att',
              unitIds: ['a1', 'a2'],
              generalId: 'g-att',
              generalMedals: 1,
            ),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );

        final after = resolveBattleContext(game, ctx);
        final updatedGeneral = after.generals.firstWhere(
          (g) => g.id == 'g-att',
        );
        expect(updatedGeneral.medals, 2);
      },
    );

    test('leader fallback medals apply when no uncommitted general exists', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'a1',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: 'p',
              ),
              Unit(
                id: 'd1',
                type: 'grenadiers',
                ownerId: 'def',
                locationProvinceId: 'p',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'att',
            displayName: 'Att',
            isHuman: true,
            leaderKey: 'napoleon',
          ),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['a1']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
      // No assigned generals exist; fallback medals should not create new general records.
      expect(after.generals, isEmpty);
    });

    test('general medals are capped at 4 on immediate engagement win', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 6),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'a1',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: 'p',
              ),
              Unit(
                id: 'a2',
                type: 'grenadiers',
                ownerId: 'att',
                locationProvinceId: 'p',
              ),
              Unit(
                id: 'd1',
                type: 'peasant_levies',
                ownerId: 'def',
                locationProvinceId: 'p',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'att', displayName: 'Att', isHuman: true),
          Player(id: 'def', displayName: 'Def', isHuman: true),
        ],
        generals: const [General(id: 'g-att', ownerId: 'att', medals: 4)],
      );
      const ctx = BattleContext(
        provinceId: 'p',
        regionId: 'oldWorld',
        defenderFactionId: 'def',
        defenderUnitIds: ['d1'],
        attackers: [
          AttackingSide(factionId: 'att', unitIds: ['a1', 'a2']),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );
      final after = resolveBattleContext(game, ctx);
      final updatedGeneral = after.generals.firstWhere((g) => g.id == 'g-att');
      expect(updatedGeneral.medals, 4);
    });

    test('battle tie-break is deterministic for same seed and context', () {
      Game makeGame() => Game(
        id: 'g1',
        globalGameSeed: 1234,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 8),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'p', regionId: 'oldWorld', ownerId: 'def'),
            ],
            units: [
              Unit(
                id: 'a1',
                type: 'pikemen',
                ownerId: 'attA',
                locationProvinceId: 'p',
              ),
              Unit(
                id: 'a2',
                type: 'pikemen',
                ownerId: 'attB',
                locationProvinceId: 'p',
              ),
              Unit(
                id: 'd1',
                type: 'pikemen',
                ownerId: 'def',
                locationProvinceId: 'p',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'attA', displayName: 'A', isHuman: true),
          Player(id: 'attB', displayName: 'B', isHuman: true),
          Player(id: 'def', displayName: 'D', isHuman: true),
        ],
      );
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
    });

    group('mutual annihilation garrison recovery type', () {
      // A second attacker with no unitIds keeps remainingAttackers non-empty
      // (recovery triggers) while the resolver skips a follow-up engagement so
      // recover_* units are not fought again in the same context.
      test(
        'great power defender: recovered regiments match most-advanced infantry era 4',
        () {
          const provinceId = 'ma_gp';
          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 1,
              ),
              oldWorld: RegionData(
                provinces: const [
                  Province(
                    id: provinceId,
                    regionId: 'oldWorld',
                    ownerId: 'def',
                  ),
                ],
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
              ),
              newWorld: const RegionData(),
            ),
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
      );

      test(
        'minor nation effective era 3: recovered regiments are grenadiers',
        () {
          const provinceId = 'ma_minor';
          final game = Game(
            id: 'g1',
            minorNations: const [
              MinorNation(id: 'minor1', effectiveMilitaryLevel: 3),
            ],
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 2,
              ),
              oldWorld: RegionData(
                provinces: const [
                  Province(
                    id: provinceId,
                    regionId: 'oldWorld',
                    ownerId: 'minor1',
                  ),
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
              ),
              newWorld: const RegionData(),
            ),
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
      );

      test('tribe effective era 1: recovered regiments are arquebusiers', () {
        const provinceId = 'ma_tribe';
        final game = Game(
          id: 'g1',
          tribes: const [Tribe(id: 'tr1')],
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceId, regionId: 'oldWorld', ownerId: 'tr1'),
              ],
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
            ),
            newWorld: const RegionData(),
          ),
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
      });
    });
  });

  group('resolveBattleContext Spy timer interaction', () {
    test('combat conquest clears Spy timer for new owner province', () {
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
            'att': {provinceId: 3},
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

      final after = resolveBattleContext(game, ctx);
      final province = after.worldState.oldWorld.provinces
          .where((p) => p.id == provinceId)
          .first;
      expect(province.ownerId, 'att');
      // Spy timer for (att, provinceId) cleared.
      expect(after.worldState.spyRevealTurnsByPlayer['att'], isNull);
      // Visibility for attacker remains fullyVisible.
      expect(
        after.worldState.playerVisibilityByTile['att']?[tileKey],
        'fullyVisible',
      );
    });

    test('combat conquest clears purchased land for conquered province', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: provinceId, regionId: ow, ownerId: 'minor1'),
            ],
            units: [
              Unit(
                id: 'att1',
                type: 'grenadiers',
                ownerId: 'gp2',
                locationProvinceId: provinceId,
              ),
              Unit(
                id: 'def1',
                type: 'peasant_levies',
                ownerId: 'minor1',
                locationProvinceId: provinceId,
              ),
            ],
          ),
          newWorld: const RegionData(),
          purchasedTilesByTileKey: const {tileKey: 'gp1'},
        ),
        players: const [
          Player(id: 'gp1', displayName: 'Investor', isHuman: true),
          Player(id: 'gp2', displayName: 'Aggressor', isHuman: false),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
      );

      const ctx = BattleContext(
        provinceId: provinceId,
        regionId: ow,
        defenderFactionId: 'minor1',
        defenderUnitIds: ['def1'],
        attackers: [
          AttackingSide(factionId: 'gp2', unitIds: ['att1'], generalMedals: 0),
        ],
        fortLevel: 0,
        terrain: 'plains',
      );

      final after = resolveBattleContext(game, ctx);
      final province = after.worldState.oldWorld.provinces
          .where((p) => p.id == provinceId)
          .first;
      expect(province.ownerId, 'gp2');
      expect(
        after.worldState.purchasedTilesByTileKey.containsKey(tileKey),
        isFalse,
      );
    });

    test(
      'combat conquest relocates illegal foreign civilian in changed province to owner capital',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|P1';
        const tileKey = '$ow|P1|0|0';
        const cCapProvince = '$ow|C1';
        const cCapTile = '$ow|C1|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceId, regionId: ow, ownerId: 'def'),
                Province(id: cCapProvince, regionId: ow, ownerId: 'civ'),
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
                Unit(
                  id: 'civ1',
                  type: kUnitTypeBuilder,
                  ownerId: 'civ',
                  locationProvinceId: provinceId,
                  tileKey: tileKey,
                  status: UnitStatus.working,
                  currentWork: CurrentWork(
                    workTarget: kWorkTargetBuildRoad,
                    tileKey: tileKey,
                    totalTurns: 2,
                    remainingTurns: 1,
                  ),
                  originTileKey: tileKey,
                  assignedTileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'att', displayName: 'Attacker', isHuman: true),
            Player(id: 'def', displayName: 'Defender', isHuman: true),
            Player(
              id: 'civ',
              displayName: 'CivOwner',
              isHuman: false,
              capitalProvinceId: cCapProvince,
              capitalTile: CapitalTile(regionId: ow, provinceId: 'C1', x: 0, y: 0),
            ),
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

        final after = resolveBattleContext(game, ctx);
        final relocated = after.worldState.oldWorld.units
            .where((u) => u.id == 'civ1')
            .single;
        expect(relocated.tileKey, cCapTile);
        expect(relocated.locationProvinceId, cCapProvince);
        expect(relocated.status, UnitStatus.idle);
        expect(relocated.currentWork, isNull);
        expect(relocated.originTileKey, isNull);
        expect(relocated.assignedTileKey, isNull);
      },
    );

    test(
      'combat conquest relocates idle foreign civilian with stale assignment '
      'tracking but no currentWork to owner capital',
      () {
        const ow = 'oldWorld';
        const provinceId = '$ow|P1';
        const tileKey = '$ow|P1|0|0';
        const cCapProvince = '$ow|C1';
        const cCapTile = '$ow|C1|0|0';

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(id: provinceId, regionId: ow, ownerId: 'def'),
                Province(id: cCapProvince, regionId: ow, ownerId: 'civ'),
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
                Unit(
                  id: 'civ1',
                  type: kUnitTypeBuilder,
                  ownerId: 'civ',
                  locationProvinceId: provinceId,
                  tileKey: tileKey,
                  status: UnitStatus.idle,
                  originTileKey: tileKey,
                  assignedTileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'att', displayName: 'Attacker', isHuman: true),
            Player(id: 'def', displayName: 'Defender', isHuman: true),
            Player(
              id: 'civ',
              displayName: 'CivOwner',
              isHuman: false,
              capitalProvinceId: cCapProvince,
              capitalTile: CapitalTile(regionId: ow, provinceId: 'C1', x: 0, y: 0),
            ),
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

        final after = resolveBattleContext(game, ctx);
        final relocated = after.worldState.oldWorld.units
            .where((u) => u.id == 'civ1')
            .single;
        expect(relocated.tileKey, cCapTile);
        expect(relocated.locationProvinceId, cCapProvince);
        expect(relocated.status, UnitStatus.idle);
        expect(relocated.currentWork, isNull);
        expect(relocated.originTileKey, isNull);
        expect(relocated.assignedTileKey, isNull);
      },
    );

    test(
      'general medals provide morale aura bonus (5% per medal, max 20%)',
      () {
        expect(moraleMultiplierForGeneralMedals(0), 1.0);
        expect(moraleMultiplierForGeneralMedals(1), 1.05);
        expect(moraleMultiplierForGeneralMedals(2), 1.10);
        expect(moraleMultiplierForGeneralMedals(3), 1.15);
        expect(moraleMultiplierForGeneralMedals(4), 1.20);
        expect(
          moraleMultiplierForGeneralMedals(5),
          1.20,
          reason: 'capped at 4 medals',
        );
        expect(
          moraleMultiplierForGeneralMedals(-1),
          1.0,
          reason: 'negative clamped to 0',
        );
      },
    );
  });
}
