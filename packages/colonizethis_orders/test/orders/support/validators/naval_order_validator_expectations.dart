// Compact NavalOrderValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_order_validator_test_support.dart';

/// Pins for [navalOrderValidatorScenarios] rows.
part 'naval_order_validator_expectations_move.dart';
part 'naval_order_validator_expectations_move_b.dart';
part 'naval_order_validator_expectations_mission.dart';

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
      _navalmoveRejectsWhenPreviousRejected();
    case NavalOrderValidatorTarget.moveRejectsWhenFleetNotFound:
      _navalmoveRejectsWhenFleetNotFound();
    case NavalOrderValidatorTarget.moveRejectsWhenFleetNotOwnedByPlayer:
      _navalmoveRejectsWhenFleetNotOwnedByPlayer();
    case NavalOrderValidatorTarget.moveRejectsWhenHomeFleet:
      _navalmoveRejectsWhenHomeFleet();
    case NavalOrderValidatorTarget.moveAcceptAdjacentSeaZoneWhenAtSea:
      _navalmoveAcceptAdjacentSeaZoneWhenAtSea();
    case NavalOrderValidatorTarget.moveRejectNonAdjacentSeaZone:
      _navalmoveRejectNonAdjacentSeaZone();
    case NavalOrderValidatorTarget.moveDockRejectWhenSeaZoneNotAdjacentToProvince:
      _navalmoveDockRejectWhenSeaZoneNotAdjacentToProvince();
    case NavalOrderValidatorTarget.moveAcceptUndockFromPortToAdjacentSeaZone:
      _navalmoveAcceptUndockFromPortToAdjacentSeaZone();
    case NavalOrderValidatorTarget.moveAtSeaRejectsProvinceIdAsDestinationSeaZoneId:
      _navalmoveAtSeaRejectsProvinceIdAsDestinationSeaZoneId();
    case NavalOrderValidatorTarget.moveInPortAcceptsAnySeaWithDirectPsEdgeToPort:
      _navalmoveInPortAcceptsAnySeaWithDirectPsEdgeToPort();
    case NavalOrderValidatorTarget.moveInPortRejectsSeaOnlyReachableViaSsFromPortSea:
      _navalmoveInPortRejectsSeaOnlyReachableViaSsFromPortSea();
    case NavalOrderValidatorTarget.moveRejectWhenInPortButInPortAtProvinceIdNull:
      _navalmoveRejectWhenInPortButInPortAtProvinceIdNull();
    case NavalOrderValidatorTarget.moveDockAcceptWhenAtSeaAdjacentOwnedProvince:
      _navalmoveDockAcceptWhenAtSeaAdjacentOwnedProvince();
    case NavalOrderValidatorTarget.moveDockAcceptWhenPortProvinceIdIsLocalUnprefixed:
      _navalmoveDockAcceptWhenPortProvinceIdIsLocalUnprefixed();
    case NavalOrderValidatorTarget.moveDockRejectWhenFleetInPort:
      _navalmoveDockRejectWhenFleetInPort();
    case NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotOwned:
      _navalmoveDockRejectWhenPortProvinceNotOwned();
    case NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotFound:
      _navalmoveDockRejectWhenPortProvinceNotFound();
    case NavalOrderValidatorTarget.missionRejectsWhenPreviousRejected:
      _navalmissionRejectsWhenPreviousRejected();
    case NavalOrderValidatorTarget.missionBlockadeRequiresTargetProvince:
      _navalmissionBlockadeRequiresTargetProvince();
    case NavalOrderValidatorTarget.missionBlockadeRejectWhenTargetNotPrefixed:
      _navalmissionBlockadeRejectWhenTargetNotPrefixed();
    case NavalOrderValidatorTarget.missionBlockadeRejectWhenBlockadingOwnProvince:
      _navalmissionBlockadeRejectWhenBlockadingOwnProvince();
    case NavalOrderValidatorTarget.missionAcceptNonBlockadeMissionWhenFleetAtSea:
      _navalmissionAcceptNonBlockadeMissionWhenFleetAtSea();
  }
}


