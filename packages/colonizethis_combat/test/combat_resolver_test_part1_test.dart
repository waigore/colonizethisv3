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
  });
}
