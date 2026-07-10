// Scenario run tear-offs for establishOverture sub-validator (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_overture_validator.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomatic_sub_validators_test_support.dart';

void eosvRunRejectsWhenStageMissing() {
  final v = establishOvertureSubValidator(
    diplomaticSubValidatorContext(gpMinorGame(), 'gp1'),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
    ),
    treasury: 5000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Overture stage is required'));
}

void eosvRunTradeConsulateDebitsTreasuryOnAccept() {
  final v = establishOvertureSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.none),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.tradeConsulate,
    ),
    treasury: overtureConsulateCost + 100,
  );
  expect(r.result.status, OrderValidationStatus.accepted);
  expect(r.treasury, 100);
}

void eosvRunTradeConsulateRejectsWithoutDiplomaticExpertise() {
  final v = establishOvertureSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(techUnlocked: const {}),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.tradeConsulate,
    ),
    treasury: overtureConsulateCost + 100,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Diplomatic Expertise'));
  expect(r.treasury, overtureConsulateCost + 100);
}

void eosvRunTradeConsulateRejectsTreasuryTooLow() {
  final v = establishOvertureSubValidator(
    diplomaticSubValidatorContext(gpMinorGame(), 'gp1'),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.tradeConsulate,
    ),
    treasury: overtureConsulateCost - 1,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Insufficient treasury'));
  expect(r.treasury, overtureConsulateCost - 1);
}

void eosvRunEmbassyRequiresExistingTradeConsulate() {
  final v = establishOvertureSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.none),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.embassy,
    ),
    treasury: overtureEmbassyCost + 1000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('requires existing Trade Consulate'));
}

void eosvRunEmbassyAcceptsAndDebitsWhenConsulateExists() {
  final v = establishOvertureSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.tradeConsulate),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.embassy,
    ),
    treasury: overtureEmbassyCost + 50,
  );
  expect(r.result.status, OrderValidationStatus.accepted);
  expect(r.treasury, 50);
}

void eosvRunNapRequiresExistingEmbassyNoDebit() {
  final v = establishOvertureSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(overtureStage: OvertureStage.embassy),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.nap,
    ),
    treasury: 1234,
  );
  expect(r.result.status, OrderValidationStatus.accepted);
  expect(r.treasury, 1234);
}

void eosvRunJoinEmpireRejectsRelationsBelowFriendly() {
  final v = establishOvertureSubValidator(
    diplomaticSubValidatorContext(
      gpMinorGame(
        overtureStage: OvertureStage.nap,
        relationScore: relationScoreNeutral,
      ),
      'gp1',
    ),
  );
  final r = v.validate(
    order: const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.joinEmpire,
    ),
    treasury: 100000,
  );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Friendly relations'));
}
