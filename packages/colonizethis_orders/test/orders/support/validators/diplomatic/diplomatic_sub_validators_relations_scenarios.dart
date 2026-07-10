// Table-driven relation-based diplomatic sub-validator scenarios (Refs #3949 wave 3).

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
import '../../scenario_runner.dart';

import 'diplomatic_sub_validators_test_support.dart';

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

void dsrRunDeclareWarAcceptsAtPeace() {
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
}

void dsrRunDeclareWarRejectsAlreadyAtWar() {
  final v = declareWarSubValidator(
    diplomaticSubValidatorContext(twoGpGame(state: RelationState.atWar), 'gp1'),
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
}

void dsrRunOfferPeaceAcceptsAtWar() {
  final v = offerPeaceSubValidator(
    diplomaticSubValidatorContext(twoGpGame(state: RelationState.atWar), 'gp1'),
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
}

void dsrRunOfferPeaceRejectsNotAtWar() {
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
}

void dsrRunAllianceRejectsNonGpTarget() {
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
}

void dsrRunAllianceRejectsAtWarWithTarget() {
  final v = allianceSubValidator(
    diplomaticSubValidatorContext(twoGpGame(state: RelationState.atWar), 'gp1'),
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
}

void dsrRunAllianceAcceptsGpAtPeace() {
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
}

void dsrRunAllianceRejectsDuplicateFormalAlliance() {
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
}

void dsrRunCooldownBlocksAlliance() {
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
}

void dsrRunCooldownBlocksEstablishOverture() {
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
}

void dsrRunCooldownBlocksEstablishFtp() {
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
}

void dsrRunCooldownBlocksGrantAid() {
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
}

void dsrRunCooldownBlocksSetSubsidy() {
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
}

void dsrRunCooldownDeclareWarRemainsAllowed() {
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

List<RunnableScenario> declareWarSubValidatorScenarios() => const [
  RunnableScenario(
    label: 'accepts when at peace and leaves treasury unchanged',
    run: dsrRunDeclareWarAcceptsAtPeace,
    refs: '#2391 AC10',
  ),
  RunnableScenario(
    label: 'rejects when already at war and preserves treasury',
    run: dsrRunDeclareWarRejectsAlreadyAtWar,
    refs: '#2391 AC10',
  ),
];

List<RunnableScenario> offerPeaceSubValidatorScenarios() => const [
  RunnableScenario(
    label: 'accepts when at war and leaves treasury unchanged',
    run: dsrRunOfferPeaceAcceptsAtWar,
    refs: '#2391 AC10',
  ),
  RunnableScenario(
    label: 'rejects when not at war',
    run: dsrRunOfferPeaceRejectsNotAtWar,
    refs: '#2391 AC10',
  ),
];

List<RunnableScenario> allianceSubValidatorScenarios() => const [
  RunnableScenario(
    label: 'rejects when target is not a Great Power',
    run: dsrRunAllianceRejectsNonGpTarget,
    refs: '#2391 AC10',
  ),
  RunnableScenario(
    label: 'rejects when at war with the target Great Power',
    run: dsrRunAllianceRejectsAtWarWithTarget,
    refs: '#2391 AC10',
  ),
  RunnableScenario(
    label: 'accepts when target is a Great Power and at peace',
    run: dsrRunAllianceAcceptsGpAtPeace,
    refs: '#2391 AC10',
  ),
  RunnableScenario(
    label: 'rejects a duplicate alliance when a formal alliance already exists',
    run: dsrRunAllianceRejectsDuplicateFormalAlliance,
    refs: '#2391 AC10',
  ),
];

List<RunnableScenario> postBreakBilateralCooldownScenarios() => const [
  RunnableScenario(
    label: 'blocks alliance toward the cooled-down GP',
    run: dsrRunCooldownBlocksAlliance,
    refs: '#3811 AC10',
  ),
  RunnableScenario(
    label: 'blocks establishOverture toward the cooled-down GP',
    run: dsrRunCooldownBlocksEstablishOverture,
    refs: '#3811 AC10',
  ),
  RunnableScenario(
    label: 'blocks establishFtp toward the cooled-down GP',
    run: dsrRunCooldownBlocksEstablishFtp,
    refs: '#3811 AC10',
  ),
  RunnableScenario(
    label: 'blocks grantAid toward the cooled-down GP',
    run: dsrRunCooldownBlocksGrantAid,
    refs: '#3811 AC10',
  ),
  RunnableScenario(
    label: 'blocks setSubsidy toward the cooled-down GP',
    run: dsrRunCooldownBlocksSetSubsidy,
    refs: '#3811 AC10',
  ),
  RunnableScenario(
    label: 'declareWar remains allowed during cooldown',
    run: dsrRunCooldownDeclareWarRemainsAllowed,
    refs: '#3811 AC10',
  ),
];

/// All relation-based diplomatic sub-validator scenarios (union of families).
List<RunnableScenario> diplomaticSubValidatorsRelationsScenarios() => [
  ...declareWarSubValidatorScenarios(),
  ...offerPeaceSubValidatorScenarios(),
  ...allianceSubValidatorScenarios(),
  ...postBreakBilateralCooldownScenarios(),
];
