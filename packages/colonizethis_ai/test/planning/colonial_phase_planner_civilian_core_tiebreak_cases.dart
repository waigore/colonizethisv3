// Tie-break and builder-roster pins for `colonial_phase_planner_civilian_test.dart`.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';
import 'colonial_phase_planner_civilian_core_support.dart';

void registerColonialPhasePlannerCivilianCoreTiebreakCases() {
  group('planColonialCivilian', () {
    test('multiple eligible NW tiles tie-break ascending by tile key', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
          Province(
            id: kColonialCivilianNwProv2,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        owUnits: [
          colonialCivilianIdleBuilder('b2'),
          colonialCivilianIdleBuilder('b1'),
        ],
        resourceByTileKey: const {
          kColonialCivilianNwTileC: 'sugar',
          kColonialCivilianNwTileB: 'tobacco',
          kColonialCivilianNwTileA: 'tobacco',
        },
      );
      final orders = planColonialCivilian(
        game: game,
        snapshot: buildColonialCivilianSnapshot(),
      );
      expect(orders.length, 2);
      expect(orders[0].unitId, 'b1');
      expect(orders[0].targetTileKey, kColonialCivilianNwTileC);
      expect(orders[1].unitId, 'b2');
      expect(orders[1].targetTileKey, kColonialCivilianNwTileA);
      expect(
        orders.every((o) => o.target == kWorkTargetBuildImprovement),
        isTrue,
        reason: 'Every emitted order must target build_improvement.',
      );
    });

    test('working builders and non-Builder units excluded', () {
      final game = buildColonialCivilianGame(
        provinces: const [
          Province(
            id: kColonialCivilianNwProv1,
            regionId: kNewWorldRegionId,
            ownerId: kColonialPhaseGp1,
          ),
        ],
        nwUnits: [
          Unit(
            id: 'b_busy',
            type: kUnitTypeBuilder,
            ownerId: kColonialPhaseGp1,
            locationProvinceId: kColonialCivilianNwProv1,
            tileKey: '${kColonialCivilianNwProv1}|7|7',
            status: UnitStatus.working,
          ),
          Unit(
            id: 'merchant1',
            type: kUnitTypeMerchant,
            ownerId: kColonialPhaseGp1,
            locationProvinceId: kColonialCivilianNwProv1,
            tileKey: '${kColonialCivilianNwProv1}|6|6',
          ),
        ],
        owUnits: const [],
        resourceByTileKey: const {kColonialCivilianNwTileA: 'tobacco'},
      );
      expect(
        planColonialCivilian(
          game: game,
          snapshot: buildColonialCivilianSnapshot(),
        ),
        isEmpty,
        reason:
            'Working builders + non-Builder civilians are filtered out; '
            'with no idle Builder present the planner returns empty.',
      );
    });
  });
}
