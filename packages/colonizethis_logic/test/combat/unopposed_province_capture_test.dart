import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/combat/unopposed_province_capture.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _gameWithMinorProvince({
  required String provinceId,
  required String minorOwnerId,
  required List<Unit> units,
  required List<DiplomacyRelation> relations,
}) {
  return Game(
    id: 'g_unopposed',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: provinceId,
            regionId: kRegionOldWorld,
            ownerId: minorOwnerId,
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
      armies: [
        Army(
          id: 'army_gp1',
          ownerId: 'gp1',
          regionId: kRegionOldWorld,
          stationedProvinceId: provinceId,
          regimentUnitIds: const ['r1'],
        ),
      ],
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: false),
    ],
    diplomacyRelations: relations,
  );
}

void main() {
  group('applyUnopposedProvinceCaptures', () {
    test(
      'captures undefended minor province when GP army moved in at war',
      () {
        const provinceId = 'oldWorld|p22';
        final game = _gameWithMinorProvince(
          provinceId: provinceId,
          minorOwnerId: 'minor6',
          units: [
            Unit(
              id: 'r1',
              type: 'grenadiers',
              ownerId: 'gp1',
              locationProvinceId: provinceId,
            ),
          ],
          relations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor6',
              state: RelationState.atWar,
            ),
          ],
        );
        final orders = Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(
                armyId: 'army_gp1',
                destinationProvinceId: provinceId,
              ),
            ],
          },
        );

        final after = applyUnopposedProvinceCaptures(game, orders);
        expect(
          after.worldState.oldWorld.provinces.single.ownerId,
          'gp1',
        );
      },
    );

    test(
      'skips when province owner still has combat units in province',
      () {
        const provinceId = 'oldWorld|p22';
        final game = _gameWithMinorProvince(
          provinceId: provinceId,
          minorOwnerId: 'minor6',
          units: [
            Unit(
              id: 'r1',
              type: 'grenadiers',
              ownerId: 'gp1',
              locationProvinceId: provinceId,
            ),
            Unit(
              id: 'm1',
              type: 'peasant_levies',
              ownerId: 'minor6',
              locationProvinceId: provinceId,
            ),
          ],
          relations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'minor6',
              state: RelationState.atWar,
            ),
          ],
        );
        final orders = Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(
                armyId: 'army_gp1',
                destinationProvinceId: provinceId,
              ),
            ],
          },
        );

        final after = applyUnopposedProvinceCaptures(game, orders);
        expect(
          after.worldState.oldWorld.provinces.single.ownerId,
          'minor6',
        );
      },
    );

    test('skips when attacker is not at war with province owner', () {
      const provinceId = 'oldWorld|p22';
      final game = _gameWithMinorProvince(
        provinceId: provinceId,
        minorOwnerId: 'minor6',
        units: [
          Unit(
            id: 'r1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: provinceId,
          ),
        ],
        relations: const [],
      );
      final orders = Orders(
        armyMoveOrdersByPlayerId: {
          'gp1': [
            ArmyMoveOrder(
              armyId: 'army_gp1',
              destinationProvinceId: provinceId,
            ),
          ],
        },
      );

      final after = applyUnopposedProvinceCaptures(game, orders);
      expect(
        after.worldState.oldWorld.provinces.single.ownerId,
        'minor6',
      );
    });
  });
}
