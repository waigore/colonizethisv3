import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Regression: battle defender may differ from province owner when the owner has
/// no combat units in-province (conflict_detection.dart). Ownership transfer must
/// use the pre-battle province owner, not [BattleContext.defenderFactionId].
void main() {
  group('resolveBattleContext province ownership transfer', () {
    test(
      'transfers from province owner when battle defender is another occupant',
      () {
        const provinceId = 'p59';
        final attackerUnits = [
          for (var i = 0; i < 4; i++)
            Unit(
              id: 'a$i',
              type: 'grenadiers',
              ownerId: 'gp5',
              locationProvinceId: provinceId,
              medals: 4,
            ),
        ];
        final defenderUnits = [
          Unit(
            id: 'd1',
            type: 'peasant_levies',
            ownerId: 'gp3',
            locationProvinceId: provinceId,
            medals: 0,
          ),
        ];
        final game = Game(
          id: 'g_owner_transfer',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 24),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'p59',
                  regionId: kRegionOldWorld,
                  ownerId: 'minor2',
                ),
              ],
              units: [...attackerUnits, ...defenderUnits],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp5', displayName: 'GP5', isHuman: false),
            Player(id: 'gp3', displayName: 'GP3', isHuman: false),
          ],
        );
        const ctx = BattleContext(
          provinceId: provinceId,
          regionId: kRegionOldWorld,
          defenderFactionId: 'gp3',
          defenderUnitIds: ['d1'],
          attackers: [
            AttackingSide(
              factionId: 'gp5',
              unitIds: ['a0', 'a1', 'a2', 'a3'],
            ),
          ],
          fortLevel: 0,
          terrain: 'plains',
        );

        final after = resolveBattleContext(game, ctx);
        expect(
          after.worldState.oldWorld.provinces.single.ownerId,
          'gp5',
        );
      },
    );
  });
}
