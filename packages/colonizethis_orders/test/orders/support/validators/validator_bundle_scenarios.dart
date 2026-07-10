// Table-driven validator-bundle scenarios (Refs #3949 wave 3).

import 'package:colonizethis_orders/src/orders/validators/army_move_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/build_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/move_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/naval_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/recruit_worker_order_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/work_order_validator.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'validator_bundle_fixtures.dart';
// dart format off

void vbRunCreateOrderValidatorsReturnsWiredValidators() {final ctx = vbDefaultScenarioContext(); expect(ctx.workContext.playerId,ctx.playerId); expect(ctx.bundle.moveValidator,isA<MoveValidator>()); expect(ctx.bundle.armyMoveValidator,isA<ArmyMoveValidator>()); expect(ctx.bundle.recruitWorkerValidator,isA<RecruitWorkerOrderValidator>()); expect(ctx.bundle.buildValidator,isA<BuildOrderValidator>()); expect(ctx.bundle.workValidator,isA<WorkOrderValidator>()); expect(ctx.bundle.diplomaticValidator,isA<DiplomaticOrderValidator>()); expect(ctx.bundle.navalValidator,isA<NavalOrderValidator>());}

/// Canonical scenarios for validator_bundle family tests.
List<RunnableScenario> validatorBundleScenarios() => [
  rs('createOrderValidators returns wired validators (Refs #2391 AC6)', vbRunCreateOrderValidatorsReturnsWiredValidators, '#2391 AC6'),
];
