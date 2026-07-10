// Compact establishOverture sub-validator assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_overture_validator.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomatic_sub_validators_test_support.dart';

/// Pins for [establishOvertureSubValidatorScenarios] rows.
enum EstablishOvertureSubValidatorTarget {
  rejectsWhenStageMissing,
  tradeConsulateDebitsTreasuryOnAccept,
  tradeConsulateRejectsWithoutDiplomaticExpertise,
  tradeConsulateRejectsTreasuryTooLow,
  embassyRequiresExistingTradeConsulate,
  embassyAcceptsAndDebitsWhenConsulateExists,
  napRequiresExistingEmbassyNoDebit,
  joinEmpireRejectsRelationsBelowFriendly,
}

void runEstablishOvertureSubValidatorExpectation(
  EstablishOvertureSubValidatorTarget target,
) {
  switch (target) {
    case EstablishOvertureSubValidatorTarget.rejectsWhenStageMissing:
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

    case EstablishOvertureSubValidatorTarget.tradeConsulateDebitsTreasuryOnAccept:
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

    case EstablishOvertureSubValidatorTarget
        .tradeConsulateRejectsWithoutDiplomaticExpertise:
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

    case EstablishOvertureSubValidatorTarget.tradeConsulateRejectsTreasuryTooLow:
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

    case EstablishOvertureSubValidatorTarget.embassyRequiresExistingTradeConsulate:
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

    case EstablishOvertureSubValidatorTarget.embassyAcceptsAndDebitsWhenConsulateExists:
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

    case EstablishOvertureSubValidatorTarget.napRequiresExistingEmbassyNoDebit:
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

    case EstablishOvertureSubValidatorTarget.joinEmpireRejectsRelationsBelowFriendly:
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
}
