// Compact grantAid / setSubsidy sub-validator assertions (Refs #3949 wave 3).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/grant_aid_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/set_subsidy_validator.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomatic_sub_validators_test_support.dart';

/// Pins for [diplomaticSubValidatorsAidScenarios] rows.
enum DiplomaticSubValidatorsAidTarget {
  grantAidRejectsNonPositiveAmount,
  grantAidRejectsAmountBelowStep,
  grantAidRejectsAmountNotMultipleOfStep,
  grantAidRejectsWithoutEmbassy,
  grantAidRejectsTreasuryBelowAmount,
  grantAidAcceptsAndDebitsTreasury,
  setSubsidyRejectsZeroPercent,
  setSubsidyRejectsPercentNotMultipleOfStep,
  setSubsidyRejectsPercentAboveMaximum,
  setSubsidyRejectsWithoutOverture,
  setSubsidyRejectsTradeConsulateOnly,
  setSubsidyAcceptsWithEmbassyLeavesTreasuryUnchanged,
  setSubsidyAcceptsWithEmbassyEvenWhenTreasuryLow,
}

void runDiplomaticSubValidatorsAidExpectation(
  DiplomaticSubValidatorsAidTarget target,
) {
  switch (target) {
    case DiplomaticSubValidatorsAidTarget.grantAidRejectsNonPositiveAmount:
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

    case DiplomaticSubValidatorsAidTarget.grantAidRejectsAmountBelowStep:
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

    case DiplomaticSubValidatorsAidTarget.grantAidRejectsAmountNotMultipleOfStep:
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

    case DiplomaticSubValidatorsAidTarget.grantAidRejectsWithoutEmbassy:
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

    case DiplomaticSubValidatorsAidTarget.grantAidRejectsTreasuryBelowAmount:
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

    case DiplomaticSubValidatorsAidTarget.grantAidAcceptsAndDebitsTreasury:
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

    case DiplomaticSubValidatorsAidTarget.setSubsidyRejectsZeroPercent:
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

    case DiplomaticSubValidatorsAidTarget.setSubsidyRejectsPercentNotMultipleOfStep:
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

    case DiplomaticSubValidatorsAidTarget.setSubsidyRejectsPercentAboveMaximum:
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

    case DiplomaticSubValidatorsAidTarget.setSubsidyRejectsWithoutOverture:
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

    case DiplomaticSubValidatorsAidTarget.setSubsidyRejectsTradeConsulateOnly:
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

    case DiplomaticSubValidatorsAidTarget
        .setSubsidyAcceptsWithEmbassyLeavesTreasuryUnchanged:
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

    case DiplomaticSubValidatorsAidTarget.setSubsidyAcceptsWithEmbassyEvenWhenTreasuryLow:
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
}
