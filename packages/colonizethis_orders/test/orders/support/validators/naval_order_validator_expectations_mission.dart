part of 'naval_order_validator_expectations.dart';

void _navalmissionRejectsWhenPreviousRejected() {
  novExpectMissionPreviousRejected();
}

void _navalmissionBlockadeRequiresTargetProvince() {
  novExpectBlockadeNoTarget();
}

void _navalmissionBlockadeRejectWhenTargetNotPrefixed() {
  novExpectBlockadeUnprefixedTarget();
}

void _navalmissionBlockadeRejectWhenBlockadingOwnProvince() {
  novExpectBlockadeOwnProvince();
}

void _navalmissionAcceptNonBlockadeMissionWhenFleetAtSea() {
  novExpectPatrolAcceptedAtSea();
}
