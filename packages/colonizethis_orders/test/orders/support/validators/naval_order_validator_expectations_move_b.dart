part of 'naval_order_validator_expectations.dart';

void _navalmoveInPortRejectsSeaOnlyReachableViaSsFromPortSea() {
  novExpectInPortSsOnlyReachability();
}

void _navalmoveRejectWhenInPortButInPortAtProvinceIdNull() {
  novExpectBrokenInPortRejected();
}

void _navalmoveDockAcceptWhenAtSeaAdjacentOwnedProvince() {
  novExpectDockAdjacentOwnedAccepted();
}

void _navalmoveDockAcceptWhenPortProvinceIdIsLocalUnprefixed() {
  novExpectDockLocalPortIdAccepted();
}

void _navalmoveDockRejectWhenFleetInPort() {
  novExpectDockFleetInPortRejected();
}

void _navalmoveDockRejectWhenPortProvinceNotOwned() {
  novExpectDockNotOwnedRejected();
}

void _navalmoveDockRejectWhenPortProvinceNotFound() {
  novExpectDockPortNotFoundRejected();
}
