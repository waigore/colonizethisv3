// Compact NavalOrderValidator expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/src/orders/order_validation_result.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_order_validator_test_support.dart';

NavalOrderValidator novValidator({
  required Game game,
  required MapTopology topology,
}) =>
    navalOrderValidatorForTest(game: game, topology: topology);

void novExpectNavalMove({
  required NavalOrderValidator validator,
  required NavalMoveOrder order,
  bool previousRejected = false,
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
  bool reasonIsNull = false,
}) {
  final result = validator.validateNavalMove(order, previousRejected: previousRejected);
  expect(result.status, status);
  if (reasonExact != null) {
    expect(result.reason, reasonExact);
  }
  if (reasonContains != null) {
    expect(result.reason, reasonContains);
  }
  if (reasonIsNull) {
    expect(result.reason, isNull);
  }
}

void novExpectNavalMission({
  required NavalOrderValidator validator,
  required NavalMissionOrder order,
  bool previousRejected = false,
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
  bool reasonIsNull = false,
}) {
  final result = validator.validateNavalMission(order, previousRejected: previousRejected);
  expect(result.status, status);
  if (reasonExact != null) {
    expect(result.reason, reasonExact);
  }
  if (reasonContains != null) {
    expect(result.reason, reasonContains);
  }
  if (reasonIsNull) {
    expect(result.reason, isNull);
  }
}

NavalMoveOrder novSeaMove(String fleetId, String seaZoneId) =>
    NavalMoveOrder(fleetId: fleetId, destinationSeaZoneId: seaZoneId);

NavalMoveOrder novDockMove(String fleetId, String localProvinceId) =>
    NavalMoveOrder(
      fleetId: fleetId,
      destinationPortProvinceId:
          ProvinceId.full(kNavalOrderValidatorTestRegionId, localProvinceId),
    );
