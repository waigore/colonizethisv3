// Compact NavalOrderValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'naval_order_validator_test_support.dart';
import 'naval_order_validator_fixtures.dart';
import 'naval_order_validator_expectation_shorthand.dart';

import 'naval_order_validator_expectation_shorthand.dart';

/// Pins for [navalOrderValidatorScenarios] rows.
enum NavalOrderValidatorTarget {
  moveRejectsWhenPreviousRejected,
  moveRejectsWhenFleetNotFound,
  moveRejectsWhenFleetNotOwnedByPlayer,
  moveRejectsWhenHomeFleet,
  moveAcceptAdjacentSeaZoneWhenAtSea,
  moveRejectNonAdjacentSeaZone,
  moveDockRejectWhenSeaZoneNotAdjacentToProvince,
  moveAcceptUndockFromPortToAdjacentSeaZone,
  moveAtSeaRejectsProvinceIdAsDestinationSeaZoneId,
  moveInPortAcceptsAnySeaWithDirectPsEdgeToPort,
  moveInPortRejectsSeaOnlyReachableViaSsFromPortSea,
  moveRejectWhenInPortButInPortAtProvinceIdNull,
  moveDockAcceptWhenAtSeaAdjacentOwnedProvince,
  moveDockAcceptWhenPortProvinceIdIsLocalUnprefixed,
  moveDockRejectWhenFleetInPort,
  moveDockRejectWhenPortProvinceNotOwned,
  moveDockRejectWhenPortProvinceNotFound,
  missionRejectsWhenPreviousRejected,
  missionBlockadeRequiresTargetProvince,
  missionBlockadeRejectWhenTargetNotPrefixed,
  missionBlockadeRejectWhenBlockadingOwnProvince,
  missionAcceptNonBlockadeMissionWhenFleetAtSea,
}

void runNavalOrderValidatorExpectation(NavalOrderValidatorTarget target) {
  switch (target) {
    case NavalOrderValidatorTarget.moveRejectsWhenPreviousRejected:
        novExpectAtSeaMove(
          topology: novTwoAdjacentSeas(),
          destSea: 'sea2',
          previousRejected: true,
          status: OrderValidationStatus.rejected,
          reasonExact: 'Previous invalid',
        );
    case NavalOrderValidatorTarget.moveRejectsWhenFleetNotFound:
        novExpectAtSeaMove(
          topology: novSingleSea(),
          destSea: 'sea1',
          status: OrderValidationStatus.rejected,
          reasonExact: 'Fleet not found',
          fleets: const [],
        );
    case NavalOrderValidatorTarget.moveRejectsWhenFleetNotOwnedByPlayer:
        novExpectAtSeaMove(
          topology: novSingleSea(),
          destSea: 'sea1',
          status: OrderValidationStatus.rejected,
          reasonExact: 'Invalid naval move',
          fleets: [navalOrderValidatorTestFleetAtSea(ownerId: 'p2')],
          players: novTwoHumanPlayers,
        );
    case NavalOrderValidatorTarget.moveRejectsWhenHomeFleet:
        novExpectAtSeaMove(
          topology: novTwoAdjacentSeas(),
          destSea: 'sea2',
          fleetId: 'fleet_p1',
          status: OrderValidationStatus.rejected,
          reasonExact: 'Invalid naval move',
          fleets: [navalOrderValidatorTestFleetAtSea(fleetId: 'fleet_p1')],
        );
    case NavalOrderValidatorTarget.moveAcceptAdjacentSeaZoneWhenAtSea:
        novExpectAtSeaMove(
          topology: novTwoAdjacentSeas(),
          destSea: 'sea2',
          status: OrderValidationStatus.accepted,
          reasonIsNull: true,
        );
    case NavalOrderValidatorTarget.moveRejectNonAdjacentSeaZone:
        novExpectAtSeaMove(
          topology: novThreeSeasLinear(),
          destSea: 'sea3',
          status: OrderValidationStatus.rejected,
          reasonExact: 'Invalid naval move',
        );
    case NavalOrderValidatorTarget.moveDockRejectWhenSeaZoneNotAdjacentToProvince:
        novExpectDockMove(
          topology: novTwoSeasProvinceDockMismatch(),
          status: OrderValidationStatus.rejected,
          reasonExact: 'Invalid naval move',
        );
    case NavalOrderValidatorTarget.moveAcceptUndockFromPortToAdjacentSeaZone:
        novExpectInPortMove(
          topology: novSeaProvinceAdjacent(),
          destSea: 'sea1',
          status: OrderValidationStatus.accepted,
          reasonIsNull: true,
        );
    case NavalOrderValidatorTarget.moveAtSeaRejectsProvinceIdAsDestinationSeaZoneId:
        novExpectAtSeaMove(
          topology: novSeaProvinceAdjacent(),
          destSea: 'P1',
          status: OrderValidationStatus.rejected,
          reasonExact: 'Invalid naval move',
        );
    case NavalOrderValidatorTarget.moveInPortAcceptsAnySeaWithDirectPsEdgeToPort:
        final validator = novValidatorInPort(topology: novPortDualSea());
        novExpectNavalMove(
          validator: validator,
          order: novSeaMove('f1', 'sea2'),
          status: OrderValidationStatus.accepted,
        );
    case NavalOrderValidatorTarget.moveInPortRejectsSeaOnlyReachableViaSsFromPortSea:
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
    case NavalOrderValidatorTarget.moveRejectWhenInPortButInPortAtProvinceIdNull:
        novExpectInPortMove(
          topology: novSingleSea(),
          destSea: 'sea1',
          status: OrderValidationStatus.rejected,
          reasonExact: 'Invalid naval move',
          fleets: [navalOrderValidatorTestFleetBrokenInPort()],
        );
    case NavalOrderValidatorTarget.moveDockAcceptWhenAtSeaAdjacentOwnedProvince:
        novExpectDockMove(
          topology: novSeaProvinceAdjacent(),
          status: OrderValidationStatus.accepted,
          reasonIsNull: true,
        );
    case NavalOrderValidatorTarget.moveDockAcceptWhenPortProvinceIdIsLocalUnprefixed:
        novExpectDockMove(
          topology: novSeaProvinceAdjacent(),
          status: OrderValidationStatus.accepted,
          reasonIsNull: true,
          order: NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: 'P1'),
        );
    case NavalOrderValidatorTarget.moveDockRejectWhenFleetInPort:
        novExpectDockMove(
          topology: novSeaProvinceAdjacent(),
          status: OrderValidationStatus.rejected,
          reasonExact: 'Dock only allowed when fleet is at sea',
          fleets: [navalOrderValidatorTestFleetInPort()],
        );
    case NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotOwned:
        novExpectDockMove(
          topology: novSeaProvinceAdjacent(),
          status: OrderValidationStatus.rejected,
          reasonExact: 'Can only dock at own province',
          oldWorldProvinces: [
            navalOrderValidatorTestOwnedProvince('P1', ownerId: 'p2'),
          ],
          players: novTwoHumanPlayers,
        );
    case NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotFound:
        novExpectDockMove(
          topology: novSingleSea(),
          status: OrderValidationStatus.rejected,
          reasonExact: 'Port province not found',
          order: novDockMove('f1', 'Nonexistent'),
        );
    case NavalOrderValidatorTarget.missionRejectsWhenPreviousRejected:
        novExpectNavalMission(
          validator: novAtSeaMissionValidator(),
          order: const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
          previousRejected: true,
          status: OrderValidationStatus.rejected,
          reasonExact: 'Previous invalid',
        );
    case NavalOrderValidatorTarget.missionBlockadeRequiresTargetProvince:
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
    case NavalOrderValidatorTarget.missionBlockadeRejectWhenTargetNotPrefixed:
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
    case NavalOrderValidatorTarget.missionBlockadeRejectWhenBlockadingOwnProvince:
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
    case NavalOrderValidatorTarget.missionAcceptNonBlockadeMissionWhenFleetAtSea:
        novExpectNavalMission(
          validator: novAtSeaMissionValidator(),
          order: const NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
          status: OrderValidationStatus.accepted,
          reasonIsNull: true,
        );
  }
}
