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

void vbcExpectUnknownUnitTypeRejected() {
  vbcExpectRejected(
    buildCivilianValidationGame(treasury: 5000),
    'UnknownTypeXyz',
    reason: 'Insufficient resources',
  );
}

void vbcExpectBuilderRejectedLowTreasury() {
  vbcExpectRejected(
    buildCivilianValidationGame(treasury: 999, paper: 5),
    kUnitTypeBuilder,
    reason: 'Insufficient treasury',
  );
}

void vbcExpectBuilderRejectedInsufficientPaper() {
  vbcExpectRejected(
    buildCivilianValidationGame(treasury: 2000),
    kUnitTypeBuilder,
    reason: 'Insufficient materials',
  );
}

void vbcExpectMerchantRejectedNoTech() {
  vbcExpectRejected(
    buildCivilianValidationGame(treasury: 3000, paper: 5),
    kUnitTypeMerchant,
    reason: 'Required technology not unlocked',
  );
}

void vbcExpectBuilderAcceptedDefaultSpawn() {
  vbcExpectAccepted(
    buildCivilianValidationGame(treasury: 2000, paper: 5),
    kUnitTypeBuilder,
  );
}

void vbcExpectMerchantAcceptedWithTech() {
  vbcExpectAccepted(
    buildCivilianValidationGame(
      treasury: 3000,
      paper: 5,
      techUnlocked: const {kTechIdMerchantCompanies: true},
    ),
    kUnitTypeMerchant,
  );
}

void vbcExpectBuilderAcceptedEmptySpawnProvince() {
  vbcExpectAccepted(
    buildCivilianValidationGame(treasury: 2000, paper: 5),
    kUnitTypeBuilder,
    spawnProvinceId: '',
  );
}

void vbcExpectBuilderAcceptedForeignSpawnFallsBackToCapital() {
  vbcExpectAccepted(
    buildCivilianValidationGame(
      treasury: 2000,
      paper: 5,
      provinces: const [
        Province(
          id: '$oldWorldRegionId|P1',
          regionId: oldWorldRegionId,
          ownerId: 'p1',
        ),
        Province(
          id: '$oldWorldRegionId|P2',
          regionId: oldWorldRegionId,
          ownerId: 'p2',
        ),
      ],
    ),
    kUnitTypeBuilder,
    spawnProvinceId: '$oldWorldRegionId|P2',
  );
}
