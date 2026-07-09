// Compact order-engine validateBuild(civilian) expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_validate_build_civilian_test_support.dart';

BuildUnitOrder vbcOrder(
  String unitType, {
  String spawnProvinceId = '$oldWorldRegionId|P1',
}) =>
    BuildUnitOrder(
      unitType: unitType,
      isMilitary:
          buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military,
      spawnProvinceId: spawnProvinceId,
    );

void vbcExpectRejected(
  Game game,
  String unitType, {
  String? reason,
  String? spawnProvinceId,
}) {
  final result = validateSingleBuildUnitOrder(
    game,
    vbcOrder(
      unitType,
      spawnProvinceId: spawnProvinceId ?? '$oldWorldRegionId|P1',
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  if (reason != null) {
    expect(result.reason, reason);
  }
}

void vbcExpectAccepted(
  Game game,
  String unitType, {
  String? spawnProvinceId,
}) {
  final result = validateSingleBuildUnitOrder(
    game,
    vbcOrder(
      unitType,
      spawnProvinceId: spawnProvinceId ?? '$oldWorldRegionId|P1',
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}








