// Table-driven NavalOrderValidator scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import '../scenario_runner.dart';

import 'naval_order_validator_expectation_shorthand.dart';
import 'naval_order_validator_fixtures.dart';
import 'naval_order_validator_test_support.dart';

void novRunValidateNavalMoveRejectsWhenPreviousRejected() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void novRunValidateNavalMoveRejectsWhenFleetNotFound() {
  novExpectAtSeaMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Fleet not found',
    fleets: const [],
  );
}

void novRunValidateNavalMoveRejectsWhenFleetNotOwnedByPlayer() {
  novExpectAtSeaMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetAtSea(ownerId: 'p2')],
    players: novTwoHumanPlayers,
  );
}

void novRunValidateNavalMoveRejectsWhenHomeFleet() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    fleetId: 'fleet_p1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetAtSea(fleetId: 'fleet_p1')],
  );
}

void novRunValidateNavalMoveAcceptMoveToAdjacentSeaZoneWhenAtSea() {
  novExpectAtSeaMove(
    topology: novTwoAdjacentSeas(),
    destSea: 'sea2',
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void novRunValidateNavalMoveRejectMoveToNonAdjacentSeaZone() {
  novExpectAtSeaMove(
    topology: novThreeSeasLinear(),
    destSea: 'sea3',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void novRunValidateNavalMoveDockRejectWhenSeaZoneNotAdjacentToProvince() {
  novExpectDockMove(
    topology: novTwoSeasProvinceDockMismatch(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void novRunValidateNavalMoveAcceptUndockFromPortToAdjacentSeaZone() {
  novExpectInPortMove(
    topology: novSeaProvinceAdjacent(),
    destSea: 'sea1',
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void novRunValidateNavalMoveAtSeaRejectsProvinceIdAsDestinationSeaZoneId() {
  novExpectAtSeaMove(
    topology: novSeaProvinceAdjacent(),
    destSea: 'P1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
  );
}

void novRunValidateNavalMoveInPortAcceptsAnySeaWithDirectPsEdgeToPort() {
  final validator = novValidatorInPort(topology: novPortDualSea());
  novExpectNavalMove(
    validator: validator,
    order: novSeaMove('f1', 'sea2'),
    status: OrderValidationStatus.accepted,
  );
}

void novRunValidateNavalMoveInPortRejectsSeaOnlyReachableViaSsFromPortSea() {
  final validator = novValidatorInPort(topology: novPortSeaChain());
  novExpectNavalMove(
    validator: validator,
    order: novSeaMove('f1', 'sea2'),
    status: OrderValidationStatus.rejected,
  );
  novExpectNavalMove(
    validator: validator,
    order: novSeaMove('f1', 'sea1'),
    status: OrderValidationStatus.accepted,
  );
}

void novRunValidateNavalMoveRejectWhenInPortButInPortAtProvinceIdNull() {
  novExpectInPortMove(
    topology: novSingleSea(),
    destSea: 'sea1',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid naval move',
    fleets: [navalOrderValidatorTestFleetBrokenInPort()],
  );
}

void novRunValidateNavalMoveDockAcceptWhenAtSeaAdjacentOwnedProvince() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

void novRunValidateNavalMoveDockAcceptWhenPortProvinceIdIsLocalUnprefixed() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
    order: NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: 'P1'),
  );
}

void novRunValidateNavalMoveDockRejectWhenFleetInPort() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Dock only allowed when fleet is at sea',
    fleets: [navalOrderValidatorTestFleetInPort()],
  );
}

void novRunValidateNavalMoveDockRejectWhenPortProvinceNotOwned() {
  novExpectDockMove(
    topology: novSeaProvinceAdjacent(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Can only dock at own province',
    oldWorldProvinces: [
      navalOrderValidatorTestOwnedProvince('P1', ownerId: 'p2'),
    ],
    players: novTwoHumanPlayers,
  );
}

void novRunValidateNavalMoveDockRejectWhenPortProvinceNotFound() {
  novExpectDockMove(
    topology: novSingleSea(),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Port province not found',
    order: NavalMoveOrder(
      fleetId: 'f1',
      destinationPortProvinceId: ProvinceId.full(
        kNavalOrderValidatorTestRegionId,
        'Nonexistent',
      ),
    ),
  );
}

void novRunValidateNavalMissionRejectsWhenPreviousRejected() {
  novExpectNavalMission(
    validator: novAtSeaMissionValidator(),
    order: const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void novRunValidateNavalMissionBlockadeRequiresTargetProvince() {
  novExpectNavalMission(
    validator: novAtSeaMissionValidator(),
    order: NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: null,
    ),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Blockade requires a target province',
  );
}

void novRunValidateNavalMissionBlockadeRejectWhenTargetNotPrefixed() {
  novExpectNavalMission(
    validator: novAtSeaMissionValidator(),
    order: NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: 'P2',
    ),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Blockade requires a target province',
  );
}

void novRunValidateNavalMissionBlockadeRejectWhenBlockadingOwnProvince() {
  novExpectNavalMission(
    validator: novAtSeaMissionValidator(
      oldWorldProvinces: [navalOrderValidatorTestOwnedProvince('P1')],
    ),
    order: NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: ProvinceId.full(kNavalOrderValidatorTestRegionId, 'P1'),
    ),
    status: OrderValidationStatus.rejected,
    reasonExact: 'Cannot blockade own province',
  );
}

void novRunValidateNavalMissionAcceptNonBlockadeMissionWhenFleetAtSea() {
  novExpectNavalMission(
    validator: novAtSeaMissionValidator(),
    order: const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
    status: OrderValidationStatus.accepted,
    reasonIsNull: true,
  );
}

/// One row in [navalMoveValidatorScenarios] / [navalMissionValidatorScenarios].

/// Canonical scenarios for `validateNavalMove` family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] (single-line `label:` for CI).
List<RunnableScenario> navalMoveValidatorScenarios() => [
  RunnableScenario(
    label: 'validateNavalMove rejects when previousRejected',
    run: novRunValidateNavalMoveRejectsWhenPreviousRejected,
  ),
  RunnableScenario(
    label: 'validateNavalMove rejects when fleet not found',
    run: novRunValidateNavalMoveRejectsWhenFleetNotFound,
  ),
  RunnableScenario(
    label: 'validateNavalMove rejects when fleet not owned by player',
    run: novRunValidateNavalMoveRejectsWhenFleetNotOwnedByPlayer,
  ),
  RunnableScenario(
    label: 'validateNavalMove rejects when home fleet',
    run: novRunValidateNavalMoveRejectsWhenHomeFleet,
  ),
  RunnableScenario(
    label: 'validateNavalMove accept move to adjacent sea zone when at sea',
    run: novRunValidateNavalMoveAcceptMoveToAdjacentSeaZoneWhenAtSea,
  ),
  RunnableScenario(
    label: 'validateNavalMove reject move to non-adjacent sea zone',
    run: novRunValidateNavalMoveRejectMoveToNonAdjacentSeaZone,
  ),
  RunnableScenario(
    label:
        'validateNavalMove dock reject when sea zone not adjacent to province',
    run: novRunValidateNavalMoveDockRejectWhenSeaZoneNotAdjacentToProvince,
  ),
  RunnableScenario(
    label: 'validateNavalMove accept undock from port to adjacent sea zone',
    run: novRunValidateNavalMoveAcceptUndockFromPortToAdjacentSeaZone,
  ),
  RunnableScenario(
    label:
        'validateNavalMove at sea rejects province id as destinationSeaZoneId',
    run: novRunValidateNavalMoveAtSeaRejectsProvinceIdAsDestinationSeaZoneId,
  ),
  RunnableScenario(
    label:
        'validateNavalMove in-port accepts any sea with direct P–S edge to port',
    run: novRunValidateNavalMoveInPortAcceptsAnySeaWithDirectPsEdgeToPort,
  ),
  RunnableScenario(
    label:
        'validateNavalMove in-port rejects sea only reachable via S–S from port sea',
    run: novRunValidateNavalMoveInPortRejectsSeaOnlyReachableViaSsFromPortSea,
  ),
  RunnableScenario(
    label: 'validateNavalMove reject when in port but inPortAtProvinceId null',
    run: novRunValidateNavalMoveRejectWhenInPortButInPortAtProvinceIdNull,
  ),
  RunnableScenario(
    label: 'validateNavalMove dock accept when at sea adjacent owned province',
    run: novRunValidateNavalMoveDockAcceptWhenAtSeaAdjacentOwnedProvince,
  ),
  RunnableScenario(
    label:
        'validateNavalMove dock accept when port province id is local (unprefixed)',
    run: novRunValidateNavalMoveDockAcceptWhenPortProvinceIdIsLocalUnprefixed,
  ),
  RunnableScenario(
    label: 'validateNavalMove dock reject when fleet in port',
    run: novRunValidateNavalMoveDockRejectWhenFleetInPort,
  ),
  RunnableScenario(
    label: 'validateNavalMove dock reject when port province not owned',
    run: novRunValidateNavalMoveDockRejectWhenPortProvinceNotOwned,
  ),
  RunnableScenario(
    label: 'validateNavalMove dock reject when port province not found',
    run: novRunValidateNavalMoveDockRejectWhenPortProvinceNotFound,
  ),
];

/// Canonical scenarios for `validateNavalMission` family tests.
List<RunnableScenario> navalMissionValidatorScenarios() => [
  RunnableScenario(
    label: 'validateNavalMission rejects when previousRejected',
    run: novRunValidateNavalMissionRejectsWhenPreviousRejected,
  ),
  RunnableScenario(
    label: 'validateNavalMission blockade requires target province',
    run: novRunValidateNavalMissionBlockadeRequiresTargetProvince,
  ),
  RunnableScenario(
    label: 'validateNavalMission blockade reject when target not prefixed',
    run: novRunValidateNavalMissionBlockadeRejectWhenTargetNotPrefixed,
  ),
  RunnableScenario(
    label: 'validateNavalMission blockade reject when blockading own province',
    run: novRunValidateNavalMissionBlockadeRejectWhenBlockadingOwnProvince,
  ),
  RunnableScenario(
    label: 'validateNavalMission accept non-blockade mission when fleet at sea',
    run: novRunValidateNavalMissionAcceptNonBlockadeMissionWhenFleetAtSea,
  ),
];
