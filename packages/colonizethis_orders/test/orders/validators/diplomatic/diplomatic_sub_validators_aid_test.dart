/// Direct unit tests for the economic sub-validators (`GrantAid`,
/// `SetSubsidy`) extracted under #2391 AC10. Covers amount-step rules,
/// embassy/consulate gating, treasury insufficiency, and the
/// debit-on-accept / preserve-on-reject contract.
/// SPEC/program/orders.md § Diplomatic orders / aid and subsidy.
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/grant_aid_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/set_subsidy_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_sub_validators_test_support.dart';

void main() {
  group('grantAidSubValidator', () {
    test('rejects non-positive amount', () {
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
    });

    test('rejects when amount is below the step', () {
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
    });

    test('rejects amount that is not a multiple of the step', () {
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
    });

    test('rejects without embassy', () {
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
    });

    test('rejects when treasury below amount and preserves treasury', () {
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
    });

    test('accepts and debits treasury by the amount', () {
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
    });
  });

  group('setSubsidySubValidator (percent model, Refs #3753 R3)', () {
    test('rejects a zero percent', () {
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
    });

    test('rejects a percent not a multiple of the step', () {
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
    });

    test('rejects a percent above the maximum', () {
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
    });

    test('rejects without any overture', () {
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
    });

    test('rejects with a Trade Consulate only (Refs #3753 R2)', () {
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
    });

    test('accepts with an embassy and leaves treasury unchanged', () {
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
      // Percent subsidies charge no upfront cost.
      expect(r.treasury, 5000);
    });

    test('accepts with an embassy even when treasury is low (no upfront cost)',
        () {
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
    });
  });
}
