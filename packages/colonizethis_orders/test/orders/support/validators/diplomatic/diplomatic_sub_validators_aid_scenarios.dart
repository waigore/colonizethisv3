// Table-driven grantAid / setSubsidy sub-validator scenarios (Refs #3949 wave 3).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/grant_aid_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/set_subsidy_validator.dart';
import 'package:colonizethis_test/test.dart';
import '../../scenario_runner.dart';

import 'diplomatic_sub_validators_test_support.dart';

void dsaRunGrantAidRejectsNonPositiveAmount() {
  final v = grantAidSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 0,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('must be positive'));
  expect(r.treasury, 5000);
}

void dsaRunGrantAidRejectsAmountBelowStep() {
  final v = grantAidSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: grantAidAmountStep - 1,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('at least'));
}

void dsaRunGrantAidRejectsAmountNotMultipleOfStep() {
  final v = grantAidSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: grantAidAmountStep + 1,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('multiple of'));
}

void dsaRunGrantAidRejectsWithoutEmbassy() {
  final v = grantAidSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.tradeConsulate),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Embassy required'));
}

void dsaRunGrantAidRejectsTreasuryBelowAmount() {
  final v = grantAidSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
    treasury: 500,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Insufficient treasury'));
  expect(r.treasury, 500);
}

void dsaRunGrantAidAcceptsAndDebitsTreasury() {
  final v = grantAidSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.accepted);
  expect(r.treasury, 4000);
}

void dsaRunSetSubsidyRejectsZeroPercent() {
  final v = setSubsidySubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 0,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('steps of'));
}

void dsaRunSetSubsidyRejectsPercentNotMultipleOfStep() {
  final v = setSubsidySubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: kSubsidyPercentStep + 1,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('steps of'));
}

void dsaRunSetSubsidyRejectsPercentAboveMaximum() {
  final v = setSubsidySubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: kSubsidyPercentMax + kSubsidyPercentStep,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('steps of'));
}

void dsaRunSetSubsidyRejectsWithoutOverture() {
  final v = setSubsidySubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.none),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 10,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Embassy required'));
}

void dsaRunSetSubsidyRejectsTradeConsulateOnly() {
  final v = setSubsidySubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.tradeConsulate),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 10,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Embassy required'));
}

void dsaRunSetSubsidyAcceptsWithEmbassyLeavesTreasuryUnchanged() {
  final v = setSubsidySubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 10,
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.accepted);
  expect(r.treasury, 5000);
}

void dsaRunSetSubsidyAcceptsWithEmbassyEvenWhenTreasuryLow() {
  final v = setSubsidySubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 20,
    ),
    treasury: 50,
  );
  expect(r.result.status, OrderValidationStatus.accepted);
  expect(r.treasury, 50);
}

List<RunnableScenario> grantAidSubValidatorScenarios() => const [
  rs('rejects non-positive amount', dsaRunGrantAidRejectsNonPositiveAmount, '#2391 AC10'),
  rs('rejects when amount is below the step', dsaRunGrantAidRejectsAmountBelowStep, '#2391 AC10'),
  rs('rejects amount that is not a multiple of the step', dsaRunGrantAidRejectsAmountNotMultipleOfStep, '#2391 AC10'),
  rs('rejects without embassy', dsaRunGrantAidRejectsWithoutEmbassy, '#2391 AC10'),
  rs('rejects when treasury below amount and preserves treasury', dsaRunGrantAidRejectsTreasuryBelowAmount, '#2391 AC10'),
  rs('accepts and debits treasury by the amount', dsaRunGrantAidAcceptsAndDebitsTreasury, '#2391 AC10'),
];

List<RunnableScenario> setSubsidySubValidatorScenarios() => const [
  rs('rejects a zero percent', dsaRunSetSubsidyRejectsZeroPercent, '#3753 R3'),
  rs('rejects a percent not a multiple of the step', dsaRunSetSubsidyRejectsPercentNotMultipleOfStep, '#3753 R3'),
  rs('rejects a percent above the maximum', dsaRunSetSubsidyRejectsPercentAboveMaximum, '#3753 R3'),
  rs('rejects without any overture', dsaRunSetSubsidyRejectsWithoutOverture, '#3753 R3'),
  rs('rejects with a Trade Consulate only (Refs #3753 R2)', dsaRunSetSubsidyRejectsTradeConsulateOnly, '#3753 R2'),
  rs('accepts with an embassy and leaves treasury unchanged', dsaRunSetSubsidyAcceptsWithEmbassyLeavesTreasuryUnchanged, '#3753 R3'),
  rs('accepts with an embassy even when treasury is low (no upfront cost)', dsaRunSetSubsidyAcceptsWithEmbassyEvenWhenTreasuryLow, '#3753 R3'),
];

/// All grantAid / setSubsidy sub-validator scenarios (union of behavior families).
List<RunnableScenario> diplomaticSubValidatorsAidScenarios() => [
  ...grantAidSubValidatorScenarios(),
  ...setSubsidySubValidatorScenarios(),
];
