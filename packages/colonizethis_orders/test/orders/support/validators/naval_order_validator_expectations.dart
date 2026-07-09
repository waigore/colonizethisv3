// Compact NavalOrderValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/order_validation_result.dart';

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
      novExpectMovePreviousRejected();
    case NavalOrderValidatorTarget.moveRejectsWhenFleetNotFound:
      novExpectFleetNotFound();
    case NavalOrderValidatorTarget.moveRejectsWhenFleetNotOwnedByPlayer:
      novExpectFleetNotOwned();
    case NavalOrderValidatorTarget.moveRejectsWhenHomeFleet:
      novExpectHomeFleetRejected();
    case NavalOrderValidatorTarget.moveAcceptAdjacentSeaZoneWhenAtSea:
      novExpectAdjacentSeaAccepted();
    case NavalOrderValidatorTarget.moveRejectNonAdjacentSeaZone:
      novExpectNonAdjacentSeaRejected();
    case NavalOrderValidatorTarget.moveDockRejectWhenSeaZoneNotAdjacentToProvince:
      novExpectDockSeaNotAdjacent();
    case NavalOrderValidatorTarget.moveAcceptUndockFromPortToAdjacentSeaZone:
      novExpectUndockAccepted();
    case NavalOrderValidatorTarget.moveAtSeaRejectsProvinceIdAsDestinationSeaZoneId:
      novExpectProvinceAsSeaRejected();
    case NavalOrderValidatorTarget.moveInPortAcceptsAnySeaWithDirectPsEdgeToPort:
      novExpectInPortDirectPsEdgeAccepted();
    case NavalOrderValidatorTarget.moveInPortRejectsSeaOnlyReachableViaSsFromPortSea:
      novExpectInPortSsOnlyReachability();
    case NavalOrderValidatorTarget.moveRejectWhenInPortButInPortAtProvinceIdNull:
      novExpectBrokenInPortRejected();
    case NavalOrderValidatorTarget.moveDockAcceptWhenAtSeaAdjacentOwnedProvince:
      novExpectDockAdjacentOwnedAccepted();
    case NavalOrderValidatorTarget.moveDockAcceptWhenPortProvinceIdIsLocalUnprefixed:
      novExpectDockLocalPortIdAccepted();
    case NavalOrderValidatorTarget.moveDockRejectWhenFleetInPort:
      novExpectDockFleetInPortRejected();
    case NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotOwned:
      novExpectDockNotOwnedRejected();
    case NavalOrderValidatorTarget.moveDockRejectWhenPortProvinceNotFound:
      novExpectDockPortNotFoundRejected();
    case NavalOrderValidatorTarget.missionRejectsWhenPreviousRejected:
      novExpectMissionPreviousRejected();
    case NavalOrderValidatorTarget.missionBlockadeRequiresTargetProvince:
      novExpectBlockadeNoTarget();
    case NavalOrderValidatorTarget.missionBlockadeRejectWhenTargetNotPrefixed:
      novExpectBlockadeUnprefixedTarget();
    case NavalOrderValidatorTarget.missionBlockadeRejectWhenBlockadingOwnProvince:
      novExpectBlockadeOwnProvince();
    case NavalOrderValidatorTarget.missionAcceptNonBlockadeMissionWhenFleetAtSea:
      novExpectPatrolAcceptedAtSea();
  }
}
