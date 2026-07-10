// Compact validator-bundle assertions (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/order_validators.dart';
import 'package:colonizethis_orders/src/orders/validators/army_move_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/build_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/move_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/recruit_worker_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_validator.dart';
import 'package:colonizethis_test/test.dart';

import 'validator_bundle_fixtures.dart';

/// Pins for [validatorBundleScenarios] rows.
enum ValidatorBundleTarget {
  createOrderValidatorsReturnsWiredValidators,
}

void runValidatorBundleExpectation(ValidatorBundleTarget target) {
  switch (target) {
    case ValidatorBundleTarget.createOrderValidatorsReturnsWiredValidators:
      final ctx = vbDefaultScenarioContext();
      expect(ctx.workContext.playerId, ctx.playerId);
      expect(ctx.bundle.moveValidator, isA<MoveValidator>());
      expect(ctx.bundle.armyMoveValidator, isA<ArmyMoveValidator>());
      expect(
        ctx.bundle.recruitWorkerValidator,
        isA<RecruitWorkerOrderValidator>(),
      );
      expect(ctx.bundle.buildValidator, isA<BuildOrderValidator>());
      expect(ctx.bundle.workValidator, isA<WorkOrderValidator>());
      expect(ctx.bundle.diplomaticValidator, isA<DiplomaticOrderValidator>());
      expect(ctx.bundle.navalValidator, isA<NavalOrderValidator>());
  }
}
