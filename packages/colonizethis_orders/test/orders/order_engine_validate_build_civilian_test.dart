import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_validate_build_civilian_test_support.dart';

void main() {
  group('OrderEngine', () {
    group('validateBuild (civilian)', () {
      test('rejects unknown unit type', () {
        final result = validateSingleBuildUnitOrder(
          buildCivilianValidationGame(treasury: 5000),
          BuildUnitOrder(
            unitType: 'UnknownTypeXyz',
            isMilitary:
                buildUnitCategoryForUnitType('UnknownTypeXyz') ==
                BuildUnitCategory.military,
            spawnProvinceId: '$oldWorldRegionId|P1',
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Insufficient resources');
      });

      test('rejects Builder when treasury too low', () {
        final result = validateSingleBuildUnitOrder(
          buildCivilianValidationGame(treasury: 999, paper: 5),
          BuildUnitOrder(
            unitType: kUnitTypeBuilder,
            isMilitary:
                buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                BuildUnitCategory.military,
            spawnProvinceId: '$oldWorldRegionId|P1',
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Insufficient treasury');
      });

      test('rejects Builder when paper insufficient', () {
        final result = validateSingleBuildUnitOrder(
          buildCivilianValidationGame(treasury: 2000),
          BuildUnitOrder(
            unitType: kUnitTypeBuilder,
            isMilitary:
                buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                BuildUnitCategory.military,
            spawnProvinceId: '$oldWorldRegionId|P1',
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Insufficient materials');
      });

      test('rejects Merchant when merchant_companies not unlocked', () {
        final result = validateSingleBuildUnitOrder(
          buildCivilianValidationGame(treasury: 3000, paper: 5),
          BuildUnitOrder(
            unitType: kUnitTypeMerchant,
            isMilitary:
                buildUnitCategoryForUnitType(kUnitTypeMerchant) ==
                BuildUnitCategory.military,
            spawnProvinceId: '$oldWorldRegionId|P1',
          ),
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Required technology not unlocked');
      });

      test('accepts Builder when treasury and paper sufficient', () {
        final result = validateSingleBuildUnitOrder(
          buildCivilianValidationGame(treasury: 2000, paper: 5),
          BuildUnitOrder(
            unitType: kUnitTypeBuilder,
            isMilitary:
                buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                BuildUnitCategory.military,
            spawnProvinceId: '$oldWorldRegionId|P1',
          ),
        );
        expect(result.status, OrderValidationStatus.accepted);
      });

      test('accepts Merchant when tech and resources ok', () {
        final result = validateSingleBuildUnitOrder(
          buildCivilianValidationGame(
            treasury: 3000,
            paper: 5,
            techUnlocked: const {kTechIdMerchantCompanies: true},
          ),
          BuildUnitOrder(
            unitType: kUnitTypeMerchant,
            isMilitary:
                buildUnitCategoryForUnitType(kUnitTypeMerchant) ==
                BuildUnitCategory.military,
            spawnProvinceId: '$oldWorldRegionId|P1',
          ),
        );
        expect(result.status, OrderValidationStatus.accepted);
      });

      test(
        'accepts build when spawnProvinceId is empty (falls back to capital)',
        () {
          final result = validateSingleBuildUnitOrder(
            buildCivilianValidationGame(treasury: 2000, paper: 5),
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary:
                  buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                  BuildUnitCategory.military,
              spawnProvinceId: '',
            ),
          );
          expect(result.status, OrderValidationStatus.accepted);
        },
      );

      test(
        'accepts build when spawnProvinceId is foreign (falls back to capital)',
        () {
          final result = validateSingleBuildUnitOrder(
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
            BuildUnitOrder(
              unitType: kUnitTypeBuilder,
              isMilitary:
                  buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
                  BuildUnitCategory.military,
              spawnProvinceId: '$oldWorldRegionId|P2',
            ),
          );
          expect(result.status, OrderValidationStatus.accepted);
        },
      );
    });
  });
}
