/// Direct unit tests for `EstablishOvertureSubValidator` extracted under
/// #2391 AC10. Covers each per-stage rule and the treasury-debit/preserve
/// contract on accept and reject.
/// SPEC/program/orders.md § Diplomatic orders / overtures.
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/orders/validators/diplomatic/establish_overture_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_sub_validators_test_support.dart';

void main() {
  group('EstablishOvertureSubValidator', () {
    test('rejects when stage is missing', () {
      final v = EstablishOvertureSubValidator(
        context: diplomaticSubValidatorContext(gpMinorGame(), 'gp1'),
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
    });

    test('trade consulate debits treasury on accept', () {
      final v = EstablishOvertureSubValidator(
        context: diplomaticSubValidatorContext(
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
    });

    test('trade consulate rejects without diplomatic_expertise', () {
      final v = EstablishOvertureSubValidator(
        context: diplomaticSubValidatorContext(
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
    });

    test('trade consulate rejects when treasury too low (no debit)', () {
      final v = EstablishOvertureSubValidator(
        context: diplomaticSubValidatorContext(gpMinorGame(), 'gp1'),
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
    });

    test('embassy requires existing trade consulate', () {
      final v = EstablishOvertureSubValidator(
        context: diplomaticSubValidatorContext(
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
    });

    test('embassy accepts and debits treasury when consulate exists', () {
      final v = EstablishOvertureSubValidator(
        context: diplomaticSubValidatorContext(
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
    });

    test('nap requires existing embassy and does not debit treasury', () {
      final v = EstablishOvertureSubValidator(
        context: diplomaticSubValidatorContext(
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
    });

    test('joinEmpire rejects when relations below friendly threshold', () {
      final v = EstablishOvertureSubValidator(
        context: diplomaticSubValidatorContext(
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
    });
  });
}
