/// Direct unit tests for relation-based sub-validators
/// (`DeclareWar`, `OfferPeace`, `Alliance`) extracted under #2391 AC10.
/// SPEC/program/orders.md § Diplomatic orders.
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/alliance_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/declare_war_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/offer_peace_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_sub_validators_test_support.dart';

void main() {
  group('declareWarSubValidator', () {
    test('accepts when at peace and leaves treasury unchanged', () {
      final v = declareWarSubValidator(
        diplomaticSubValidatorContext(
          twoGpGame(state: RelationState.atPeace),
          'gp1',
        ),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp2',
        ),
        treasury: 1234,
      );
      expect(r.result.status, OrderValidationStatus.accepted);
      expect(r.treasury, 1234);
    });

    test('rejects when already at war and preserves treasury', () {
      final v = declareWarSubValidator(
        diplomaticSubValidatorContext(
          twoGpGame(state: RelationState.atWar),
          'gp1',
        ),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp2',
        ),
        treasury: 999,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('Already at war'));
      expect(r.treasury, 999);
    });
  });

  group('offerPeaceSubValidator', () {
    test('accepts when at war and leaves treasury unchanged', () {
      final v = offerPeaceSubValidator(
        diplomaticSubValidatorContext(
          twoGpGame(state: RelationState.atWar),
          'gp1',
        ),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: 'gp2',
        ),
        treasury: 0,
      );
      expect(r.result.status, OrderValidationStatus.accepted);
      expect(r.treasury, 0);
    });

    test('rejects when not at war', () {
      final v = offerPeaceSubValidator(
        diplomaticSubValidatorContext(
          twoGpGame(state: RelationState.atPeace),
          'gp1',
        ),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: 'gp2',
        ),
        treasury: 100,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('not at war'));
      expect(r.treasury, 100);
    });
  });

  group('allianceSubValidator', () {
    test('rejects when target is not a Great Power', () {
      final v = allianceSubValidator(
        diplomaticSubValidatorContext(gpMinorGame(), 'gp1'),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'minor1',
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('must be a Great Power'));
      expect(r.treasury, 5000);
    });

    test('rejects when at war with the target Great Power', () {
      final v = allianceSubValidator(
        diplomaticSubValidatorContext(
          twoGpGame(state: RelationState.atWar),
          'gp1',
        ),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('Cannot form alliance while at war'));
    });

    test('accepts when target is a Great Power and at peace', () {
      final v = allianceSubValidator(
        diplomaticSubValidatorContext(
          twoGpGame(state: RelationState.atPeace),
          'gp1',
        ),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.accepted);
      expect(r.treasury, 5000);
    });

    test('rejects a duplicate alliance when a formal alliance already exists',
        () {
      final v = allianceSubValidator(
        diplomaticSubValidatorContext(
          twoGpGame(state: RelationState.atPeace, formalAlliance: true),
          'gp1',
        ),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('Already in a formal alliance'));
      expect(r.treasury, 5000);
    });
  });
}
