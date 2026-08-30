// Case bodies for `develop_phase_planner_test.dart` (Refs #4291 Slice D).
// Registered from the thin contract; pin coverage preserved 1:1.

import 'package:colonizethis_ai/src/planning/develop_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'develop_phase_planner_civilian_pairing_support.dart';
import 'develop_phase_planner_support.dart';

void registerDevelopPhasePlannerCivilianPairingCases() {
  group('planDevelopCivilian', () {
    test('determinism: identical inputs yield identical orders', () {
      final game = developPhaseCivilianPairingGame(
        provinces: const [
          Province(
            id: kDevelopPhaseCivilianPairingOwProv1,
            regionId: kOldWorldRegionId,
            ownerId: kDevelopPhaseGp1,
            townTileKey: kDevelopPhaseCivilianPairingOwTileTown,
          ),
          Province(
            id: kDevelopPhaseCivilianPairingNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kDevelopPhaseGp1,
          ),
        ],
        owUnits: [
          developPhaseIdleBuilder('b2'),
          developPhaseIdleBuilder('b1'),
        ],
        nwUnits: [
          developPhaseIdleBuilder('b3', regionId: kNewWorldRegionId),
        ],
        resourceByTileKey: const {
          kDevelopPhaseCivilianPairingOwTileA: 'grain',
          kDevelopPhaseCivilianPairingOwTileB: 'iron',
          kDevelopPhaseCivilianPairingOwTileTown: 'grain',
          kDevelopPhaseCivilianPairingNwTileA: 'spices',
        },
      );
      final snapshot = developPhaseCivilianPairingSnapshot();
      final first = planDevelopCivilian(game: game, snapshot: snapshot);
      final second = planDevelopCivilian(game: game, snapshot: snapshot);
      expect(
        first.map((o) => '${o.unitId}->${o.targetTileKey}').toList(),
        const [
          'b3->newWorld|p_gamma|1|1',
          'b1->oldWorld|p_alpha|1|1',
          'b2->oldWorld|p_alpha|2|2',
        ],
      );
      expect(second, first);
    });

    test('cross-region NW tile is skipped when only OW Builders exist', () {
      final game = developPhaseCivilianPairingGame(
        provinces: const [
          Province(
            id: kDevelopPhaseCivilianPairingOwProv1,
            regionId: kOldWorldRegionId,
            ownerId: kDevelopPhaseGp1,
          ),
          Province(
            id: kDevelopPhaseCivilianPairingNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kDevelopPhaseGp1,
          ),
        ],
        owUnits: [developPhaseIdleBuilder('b1')],
        resourceByTileKey: const {
          kDevelopPhaseCivilianPairingOwTileA: 'grain',
          kDevelopPhaseCivilianPairingNwTileA: 'spices',
        },
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: developPhaseCivilianPairingSnapshot(),
      );
      expect(
        orders.map((o) => o.targetTileKey).toList(),
        const [kDevelopPhaseCivilianPairingOwTileA],
      );
      expect(orders.single.unitId, 'b1');
    });

    test(
      'closer same-region Builder wins over farther same-region Builder',
      () {
        final farBuilder = Unit(
          id: 'b_far',
          type: kUnitTypeBuilder,
          ownerId: kDevelopPhaseGp1,
          locationProvinceId: kDevelopPhaseCivilianPairingOwProv1,
          tileKey: '${kDevelopPhaseCivilianPairingOwProv1}|10|10',
        );
        final nearBuilder = Unit(
          id: 'b_near',
          type: kUnitTypeBuilder,
          ownerId: kDevelopPhaseGp1,
          locationProvinceId: kDevelopPhaseCivilianPairingOwProv1,
          tileKey: '${kDevelopPhaseCivilianPairingOwProv1}|1|1',
        );
        final game = developPhaseCivilianPairingGame(
          provinces: const [
            Province(
              id: kDevelopPhaseCivilianPairingOwProv1,
              regionId: kOldWorldRegionId,
              ownerId: kDevelopPhaseGp1,
            ),
          ],
          owUnits: [farBuilder, nearBuilder],
          resourceByTileKey: const {
            kDevelopPhaseCivilianPairingOwTileB: 'grain',
          },
        );
        final orders = planDevelopCivilian(
          game: game,
          snapshot: developPhaseCivilianPairingSnapshot(),
        );
        expect(orders.length, 1);
        expect(orders.single.unitId, 'b_near');
        expect(orders.single.targetTileKey, kDevelopPhaseCivilianPairingOwTileB);
      },
    );

    test('equal-distance Builders tiebreak by ascending Builder id', () {
      final game = developPhaseCivilianPairingGame(
        provinces: const [
          Province(
            id: kDevelopPhaseCivilianPairingOwProv1,
            regionId: kOldWorldRegionId,
            ownerId: kDevelopPhaseGp1,
          ),
        ],
        owUnits: [
          developPhaseIdleBuilder('b2'),
          developPhaseIdleBuilder('b1'),
        ],
        resourceByTileKey: const {
          kDevelopPhaseCivilianPairingOwTileA: 'grain',
        },
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: developPhaseCivilianPairingSnapshot(),
      );
      expect(orders.length, 1);
      expect(orders.single.unitId, 'b1');
      expect(orders.single.targetTileKey, kDevelopPhaseCivilianPairingOwTileA);
    });

    test('distance pairing across two tiles re-optimizes vs index-pairing', () {
      final b1 = Unit(
        id: 'b1',
        type: kUnitTypeBuilder,
        ownerId: kDevelopPhaseGp1,
        locationProvinceId: kDevelopPhaseCivilianPairingOwProv1,
        tileKey: '${kDevelopPhaseCivilianPairingOwProv1}|0|0',
      );
      final b2 = Unit(
        id: 'b2',
        type: kUnitTypeBuilder,
        ownerId: kDevelopPhaseGp1,
        locationProvinceId: kDevelopPhaseCivilianPairingOwProv1,
        tileKey: '${kDevelopPhaseCivilianPairingOwProv1}|5|5',
      );
      final game = developPhaseCivilianPairingGame(
        provinces: const [
          Province(
            id: kDevelopPhaseCivilianPairingOwProv1,
            regionId: kOldWorldRegionId,
            ownerId: kDevelopPhaseGp1,
          ),
        ],
        owUnits: [b1, b2],
        resourceByTileKey: const {
          'oldWorld|p_alpha|4|4': 'grain',
          'oldWorld|p_alpha|1|1': 'iron',
        },
      );
      final orders = planDevelopCivilian(
        game: game,
        snapshot: developPhaseCivilianPairingSnapshot(),
      );
      expect(orders.length, 2);
      expect(orders[0].targetTileKey, 'oldWorld|p_alpha|1|1');
      expect(orders[0].unitId, 'b1');
      expect(orders[1].targetTileKey, 'oldWorld|p_alpha|4|4');
      expect(orders[1].unitId, 'b2');
    });
  });
}
