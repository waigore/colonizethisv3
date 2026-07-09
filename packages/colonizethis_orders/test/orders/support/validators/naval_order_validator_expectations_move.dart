part of 'naval_order_validator_expectations.dart';

void _navalmoveRejectsWhenPreviousRejected() {
  novExpectMovePreviousRejected();
}

void _navalmoveRejectsWhenFleetNotFound() {
  novExpectFleetNotFound();
}

void _navalmoveRejectsWhenFleetNotOwnedByPlayer() {
  novExpectFleetNotOwned();
}

void _navalmoveRejectsWhenHomeFleet() {
  novExpectHomeFleetRejected();
}

void _navalmoveAcceptAdjacentSeaZoneWhenAtSea() {
  novExpectAdjacentSeaAccepted();
}

void _navalmoveRejectNonAdjacentSeaZone() {
  novExpectNonAdjacentSeaRejected();
}

void _navalmoveDockRejectWhenSeaZoneNotAdjacentToProvince() {
  novExpectDockSeaNotAdjacent();
}

void _navalmoveAcceptUndockFromPortToAdjacentSeaZone() {
  novExpectUndockAccepted();
}

void _navalmoveAtSeaRejectsProvinceIdAsDestinationSeaZoneId() {
  novExpectProvinceAsSeaRejected();
}

void _navalmoveInPortAcceptsAnySeaWithDirectPsEdgeToPort() {
  novExpectInPortDirectPsEdgeAccepted();
}
