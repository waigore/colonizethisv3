// Scenario run tear-offs for naval order validator family (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_test/test.dart';

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
