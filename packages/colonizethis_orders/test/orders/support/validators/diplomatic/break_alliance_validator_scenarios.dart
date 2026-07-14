// Table-driven breakAlliance validator scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/break_alliance_validator.dart';
import 'package:colonizethis_test/test.dart';
import '../../scenario_runner.dart';

import 'break_alliance_validator_fixtures.dart';
import 'diplomatic_sub_validators_test_support.dart';
// dart format off

void balRunAcceptsFormalAllianceWithGpTarget() {final game = breakAllianceValidatorTwoGpAllianceGame(); final r = breakAllianceSubValidator(diplomaticSubValidatorContext(game,'gp1'),).validate(order: const DiplomaticOrder(type: DiplomaticOrderType.breakAlliance,targetFactionId: 'gp2',),treasury: 0,); expect(r.result.status,OrderValidationStatus.accepted); expect(r.treasury,0);}

void balRunRejectsWhileAtWar() {final game = breakAllianceValidatorTwoGpAllianceGame(formalAlliance: false,state: RelationState.atWar,); final r = breakAllianceSubValidator(diplomaticSubValidatorContext(game,'gp1'),).validate(order: const DiplomaticOrder(type: DiplomaticOrderType.breakAlliance,targetFactionId: 'gp2',),treasury: 0,); expect(r.result.status,OrderValidationStatus.rejected); expect(r.result.reason,contains('formal alliance'));}

void balRunRejectsNoFormalAlliance() {final game = breakAllianceValidatorTwoGpAllianceGame(formalAlliance: false); final r = breakAllianceSubValidator(diplomaticSubValidatorContext(game,'gp1'),).validate(order: const DiplomaticOrder(type: DiplomaticOrderType.breakAlliance,targetFactionId: 'gp2',),treasury: 0,); expect(r.result.status,OrderValidationStatus.rejected); expect(r.result.reason,contains('formal alliance'));}

void balRunRejectsNonGpTarget() {final game = breakAllianceValidatorTwoGpAllianceGame(); final r = breakAllianceSubValidator(diplomaticSubValidatorContext(game,'gp1'),).validate(order: const DiplomaticOrder(type: DiplomaticOrderType.breakAlliance,targetFactionId: 'minor1',),treasury: 0,); expect(r.result.status,OrderValidationStatus.rejected); expect(r.result.reason,contains('Great Power'));}

void balRunParentValidatorAcceptsValidBreakAlliance() {final game = breakAllianceValidatorTwoGpAllianceGame(); final validator = DiplomaticOrderValidator(game: game,playerId: 'gp1',initialTreasury: 0,); final r = validator.validate(const DiplomaticOrder(type: DiplomaticOrderType.breakAlliance,targetFactionId: 'gp2',),previousRejected: false,); expect(r.result.status,OrderValidationStatus.accepted);}

/// One row in breakAlliance validator scenario tables.

List<RunnableScenario> breakAllianceSubValidatorScenarios() => [
  rs('accepts when a formal alliance exists with the GP target', balRunAcceptsFormalAllianceWithGpTarget, '#3753 R11'),
  rs('rejects while at war (war invariant cleared the alliance)', balRunRejectsWhileAtWar, '#3753 R11'),
  rs('rejects when no formal alliance exists with the target', balRunRejectsNoFormalAlliance, '#3753 R11'),
  rs('rejects a non-Great-Power target', balRunRejectsNonGpTarget, '#3753 R11'),
];

List<RunnableScenario> diplomaticOrderValidatorBreakAllianceScenarios() =>
    [
      rs('accepts a valid breakAlliance order through the parent validator', balRunParentValidatorAcceptsValidBreakAlliance, '#3753 R11'),
    ];

/// All breakAlliance validator scenarios (union of behavior-family tables).
List<RunnableScenario> breakAllianceValidatorScenarios() => [
  ...breakAllianceSubValidatorScenarios(),
  ...diplomaticOrderValidatorBreakAllianceScenarios(),
];
