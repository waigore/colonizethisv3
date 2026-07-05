import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_order_validator_test_support.dart';

void main() {
  group('NavalOrderValidator', () {
    test(
      'validateNavalMove dock reject when sea zone not adjacent to province',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestSeaNode('sea2'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
            TopologyEdge(id1: 'sea2', id2: 'P1'),
          ],
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
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
      },
    );

    test('validateNavalMove accept undock from port to adjacent sea zone', () {
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
        const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.accepted);
      expect(result.reason, isNull);
    });

    test(
      'validateNavalMove at sea rejects province id as destinationSeaZoneId',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetAtSea()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'P1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
      },
    );

    test(
      'validateNavalMove in-port accepts any sea with direct P–S edge to port',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestSeaNode('sea2'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [
            TopologyEdge(id1: 'P1', id2: 'sea1'),
            TopologyEdge(id1: 'P1', id2: 'sea2'),
          ],
        );
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
          fleets: [navalOrderValidatorTestFleetInPort()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final toSea2 = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          previousRejected: false,
        );
        expect(toSea2.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'validateNavalMove in-port rejects sea only reachable via S–S from port sea',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [
            navalOrderValidatorTestSeaNode('sea1'),
            navalOrderValidatorTestSeaNode('sea2'),
            navalOrderValidatorTestProvinceNode('P1'),
          ],
          edges: const [
            TopologyEdge(id1: 'P1', id2: 'sea1'),
            TopologyEdge(id1: 'sea1', id2: 'sea2'),
          ],
        );
        final game = navalOrderValidatorTestGame(
          oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
          fleets: [navalOrderValidatorTestFleetInPort()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final toSea2 = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          previousRejected: false,
        );
        expect(toSea2.status, OrderValidationStatus.rejected);
        final toSea1 = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          previousRejected: false,
        );
        expect(toSea1.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'validateNavalMove reject when in port but inPortAtProvinceId null',
      () {
        final topology = navalOrderValidatorTestTopology(
          nodes: [navalOrderValidatorTestSeaNode('sea1')],
        );
        final game = navalOrderValidatorTestGame(
          fleets: [navalOrderValidatorTestFleetBrokenInPort()],
        );
        final validator = navalOrderValidatorForTest(
          game: game,
          topology: topology,
        );
        final result = validator.validateNavalMove(
          const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid naval move');
      },
    );
  });
}
