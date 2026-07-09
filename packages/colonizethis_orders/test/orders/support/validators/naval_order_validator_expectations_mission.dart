part of 'naval_order_validator_expectations.dart';

void _navalmissionRejectsWhenPreviousRejected() {
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
}

void _navalmissionBlockadeRequiresTargetProvince() {
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
}

void _navalmissionBlockadeRejectWhenTargetNotPrefixed() {
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
}

void _navalmissionBlockadeRejectWhenBlockadingOwnProvince() {
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
}

void _navalmissionAcceptNonBlockadeMissionWhenFleetAtSea() {
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
}

