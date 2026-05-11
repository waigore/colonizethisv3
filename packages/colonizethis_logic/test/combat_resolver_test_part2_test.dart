import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveEngagement', () {
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
}
