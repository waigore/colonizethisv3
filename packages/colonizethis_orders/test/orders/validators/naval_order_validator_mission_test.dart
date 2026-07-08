import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/validators/naval_order_validator_test_support.dart';

void main() {
  group('NavalOrderValidator', () {
    test('validateNavalMission rejects when previousRejected', () {
      final game = navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      );
      final topology = navalOrderValidatorTestTopology(nodes: const []);
      final validator = navalOrderValidatorForTest(
        game: game,
        topology: topology,
      );
      final result = validator.validateNavalMission(
        const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        previousRejected: true,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    });

    test('validateNavalMission blockade requires target province', () {
      final topology = navalOrderValidatorTestTopology(
        nodes: [navalOrderValidatorTestSeaNode('sea1')],
      );
      final game = navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      );
      final validator = navalOrderValidatorForTest(
        game: game,
        topology: topology,
      );
      final result = validator.validateNavalMission(
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId: null,
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Blockade requires a target province');
    });

    test('validateNavalMission blockade reject when target not prefixed', () {
      final topology = navalOrderValidatorTestTopology(
        nodes: [navalOrderValidatorTestSeaNode('sea1')],
      );
      final game = navalOrderValidatorTestGame(
        fleets: [navalOrderValidatorTestFleetAtSea()],
      );
      final validator = navalOrderValidatorForTest(
        game: game,
        topology: topology,
      );
      final result = validator.validateNavalMission(
        NavalMissionOrder(
          fleetId: 'f1',
          mission: FleetMission.blockade.name,
          targetProvinceId: 'P2',
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Blockade requires a target province');
    });

    test(
      'validateNavalMission blockade reject when blockading own province',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [navalOrderValidatorTestSeaNode('sea1')],
        );
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMission(
          NavalMissionOrder(
            fleetId: 'f1',
            mission: FleetMission.blockade.name,
            targetProvinceId:
                ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
          ),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Cannot blockade own province');
      },
    );

    test(
      'validateNavalMission accept non-blockade mission when fleet at sea',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [navalOrderValidatorTestSeaNode('sea1')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMission(
          const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
      },
    );
  });
}
