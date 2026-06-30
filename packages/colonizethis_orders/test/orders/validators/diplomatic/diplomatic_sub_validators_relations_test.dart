/// Direct unit tests for relation-based sub-validators
/// (`DeclareWar`, `OfferPeace`, `Alliance`) extracted under #2391 AC10.
/// SPEC/program/orders.md § Diplomatic orders.
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/alliance_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/declare_war_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_ftp_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_overture_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/grant_aid_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/offer_peace_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/set_subsidy_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';

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

  group('post-break bilateral cooldown (Refs #3811 AC10)', () {
    Game cooldownGame() => twoGpGame(
      turnNumber: 3,
      allianceBreakCooldowns: const [
        AllianceBreakCooldownState(
          factionId1: 'gp1',
          factionId2: 'gp2',
          sinceTurn: 3,
        ),
      ],
    );

    test('blocks alliance toward the cooled-down GP', () {
      final v = allianceSubValidator(
        diplomaticSubValidatorContext(cooldownGame(), 'gp1'),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, kAllianceBreakCooldownRejectionReason);
    });

    test('blocks establishOverture toward the cooled-down GP', () {
      final v = establishOvertureSubValidator(
        diplomaticSubValidatorContext(cooldownGame(), 'gp1'),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'gp2',
          overtureStage: OvertureStage.tradeConsulate,
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, kAllianceBreakCooldownRejectionReason);
    });

    test('blocks establishFtp toward the cooled-down GP', () {
      final v = establishFtpSubValidator(
        diplomaticSubValidatorContext(cooldownGame(), 'gp1'),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishFtp,
          targetFactionId: 'gp2',
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, kAllianceBreakCooldownRejectionReason);
    });

    test('blocks grantAid toward the cooled-down GP', () {
      final v = grantAidSubValidator(
        diplomaticSubValidatorContext(cooldownGame(), 'gp1'),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: 'gp2',
          amount: grantAidAmountStep,
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, kAllianceBreakCooldownRejectionReason);
    });

    test('blocks setSubsidy toward the cooled-down GP', () {
      final v = setSubsidySubValidator(
        diplomaticSubValidatorContext(cooldownGame(), 'gp1'),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'gp2',
          amount: 10,
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, kAllianceBreakCooldownRejectionReason);
    });

    test('declareWar remains allowed during cooldown', () {
      final v = declareWarSubValidator(
        diplomaticSubValidatorContext(cooldownGame(), 'gp1'),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp2',
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.accepted);
    });
  });
}
