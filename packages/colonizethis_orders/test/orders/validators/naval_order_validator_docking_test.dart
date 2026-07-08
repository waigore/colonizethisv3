import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/validators/naval_order_validator_test_support.dart';

void main() {
  group('NavalOrderValidator', () {
    test(
      'validateNavalMove dock accept when at sea adjacent owned province',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          NavalMoveOrder(
            fleetId: 'f1',
            destinationPortProvinceId:
                ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
          ),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
      },
    );

    test(
      'validateNavalMove dock accept when port province id is local (unprefixed)',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: 'P1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
        expect(result.reason, isNull);
      },
    );

    test('validateNavalMove dock reject when fleet in port', () {
      final topology = navalOrderValidatorTestTopology(
        nodes: [
          navalOrderValidatorTestSeaNode('sea1'),
          navalOrderValidatorTestProvinceNode('P1'),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
      );
      final game = navalOrderValidatorTestGame(
        oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
        fleets: [navalOrderValidatorTestFleetInPort()],
      );
      final validator = navalOrderValidatorForTest(
        game: game,
        topology: topology,
      );
      final result = validator.validateNavalMove(
        NavalMoveOrder(
          fleetId: 'f1',
          destinationPortProvinceId:
              ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Dock only allowed when fleet is at sea');
    });

    test('validateNavalMove dock reject when port province not owned', () {
      final topology = navalOrderValidatorTestTopology(
        nodes: [
          navalOrderValidatorTestSeaNode('sea1'),
          navalOrderValidatorTestProvinceNode('P1'),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
      );
      final game = navalOrderValidatorTestGame(
        oldWorldProvinces: [
          navalOrderValidatorTestOwnedProvince('P1', ownerId: 'p2'),
        ],
        fleets: [navalOrderValidatorTestFleetAtSea()],
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final validator = navalOrderValidatorForTest(
        game: game,
        topology: topology,
      );
      final result = validator.validateNavalMove(
        NavalMoveOrder(
          fleetId: 'f1',
          destinationPortProvinceId:
              ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Can only dock at own province');
    });

    test('validateNavalMove dock reject when port province not found', () {
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
      final result = validator.validateNavalMove(
        NavalMoveOrder(
          fleetId: 'f1',
          destinationPortProvinceId:
              ProvinceId.full(kNavalOrderValidatorTestRegionId, 'Nonexistent'),
        ),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Port province not found');
    });
  });
}
