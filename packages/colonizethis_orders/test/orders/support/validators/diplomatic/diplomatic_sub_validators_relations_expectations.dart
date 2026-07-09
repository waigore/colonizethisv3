// Compact relation-based diplomatic sub-validator assertions (Refs #3949 wave 3).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/alliance_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/declare_war_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_ftp_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_overture_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/grant_aid_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/offer_peace_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/set_subsidy_validator.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomatic_sub_validators_test_support.dart';

/// Pins for [diplomaticSubValidatorsRelationsScenarios] rows.
enum DiplomaticSubValidatorsRelationsTarget {
  declareWarAcceptsAtPeace,
  declareWarRejectsAlreadyAtWar,
  offerPeaceAcceptsAtWar,
  offerPeaceRejectsNotAtWar,
  allianceRejectsNonGpTarget,
  allianceRejectsAtWarWithTarget,
  allianceAcceptsGpAtPeace,
  allianceRejectsDuplicateFormalAlliance,
  cooldownBlocksAlliance,
  cooldownBlocksEstablishOverture,
  cooldownBlocksEstablishFtp,
  cooldownBlocksGrantAid,
  cooldownBlocksSetSubsidy,
  cooldownDeclareWarRemainsAllowed,
}

Game _cooldownGame() => twoGpGame(
      turnNumber: 3,
      allianceBreakCooldowns: const [
        AllianceBreakCooldownState(
          factionId1: 'gp1',
          factionId2: 'gp2',
          sinceTurn: 3,
        ),
      ],
    );

void runDiplomaticSubValidatorsRelationsExpectation(
  DiplomaticSubValidatorsRelationsTarget target,
) {
  switch (target) {
    case DiplomaticSubValidatorsRelationsTarget.declareWarAcceptsAtPeace:
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

    case DiplomaticSubValidatorsRelationsTarget.declareWarRejectsAlreadyAtWar:
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

    case DiplomaticSubValidatorsRelationsTarget.offerPeaceAcceptsAtWar:
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

    case DiplomaticSubValidatorsRelationsTarget.offerPeaceRejectsNotAtWar:
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

    case DiplomaticSubValidatorsRelationsTarget.allianceRejectsNonGpTarget:
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

    case DiplomaticSubValidatorsRelationsTarget.allianceRejectsAtWarWithTarget:
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

    case DiplomaticSubValidatorsRelationsTarget.allianceAcceptsGpAtPeace:
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

    case DiplomaticSubValidatorsRelationsTarget.allianceRejectsDuplicateFormalAlliance:
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

    case DiplomaticSubValidatorsRelationsTarget.cooldownBlocksAlliance:
      final v = allianceSubValidator(
        diplomaticSubValidatorContext(_cooldownGame(), 'gp1'),
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

    case DiplomaticSubValidatorsRelationsTarget.cooldownBlocksEstablishOverture:
      final v = establishOvertureSubValidator(
        diplomaticSubValidatorContext(_cooldownGame(), 'gp1'),
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

    case DiplomaticSubValidatorsRelationsTarget.cooldownBlocksEstablishFtp:
      final v = establishFtpSubValidator(
        diplomaticSubValidatorContext(_cooldownGame(), 'gp1'),
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

    case DiplomaticSubValidatorsRelationsTarget.cooldownBlocksGrantAid:
      final v = grantAidSubValidator(
        diplomaticSubValidatorContext(_cooldownGame(), 'gp1'),
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

    case DiplomaticSubValidatorsRelationsTarget.cooldownBlocksSetSubsidy:
      final v = setSubsidySubValidator(
        diplomaticSubValidatorContext(_cooldownGame(), 'gp1'),
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

    case DiplomaticSubValidatorsRelationsTarget.cooldownDeclareWarRemainsAllowed:
      final v = declareWarSubValidator(
        diplomaticSubValidatorContext(_cooldownGame(), 'gp1'),
      );
      final r = v.validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.declareWar,
          targetFactionId: 'gp2',
        ),
        treasury: 5000,
      );
      expect(r.result.status, OrderValidationStatus.accepted);
  }
}
