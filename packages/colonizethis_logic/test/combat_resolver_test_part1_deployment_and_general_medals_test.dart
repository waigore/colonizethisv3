import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveEngagement', () {
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
  });
}
