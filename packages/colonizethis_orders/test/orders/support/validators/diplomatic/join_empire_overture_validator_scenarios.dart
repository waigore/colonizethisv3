// Table-driven validateJoinEmpireOverture scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/join_empire_validator.dart';
import 'package:colonizethis_test/test.dart';
import '../../scenario_runner.dart';

import 'diplomatic_sub_validators_test_support.dart';
// dart format off

void jeeRunRejectsWhenNotNap() {final ctx = diplomaticSubValidatorContext(gpMinorGame(overtureStage: OvertureStage.embassy),'gp1',); final r = validateJoinEmpireOverture(ctx: ctx,targetId: 'minor1',rel: const DiplomacyRelation(factionId1: 'gp1',factionId2: 'minor1',state: RelationState.atPeace,score: relationScoreMinFriendly,),currentStage: OvertureStage.embassy,treasury: 99999,); expect(r.result.status,OrderValidationStatus.rejected); expect(r.result.reason,contains('Non-Aggression Pact')); expect(r.treasury,99999,reason: 'reject must not debit treasury');}

void jeeRunRejectsWhenScoreBelowFriendly() {final ctx = diplomaticSubValidatorContext(gpMinorGame(overtureStage: OvertureStage.nap,relationScore: relationScoreNeutral,),'gp1',); final r = validateJoinEmpireOverture(ctx: ctx,targetId: 'minor1',rel: const DiplomacyRelation(factionId1: 'gp1',factionId2: 'minor1',state: RelationState.atPeace,score: relationScoreNeutral,),currentStage: OvertureStage.nap,treasury: 99999,); expect(r.result.status,OrderValidationStatus.rejected); expect(r.result.reason,contains('Friendly relations')); expect(r.treasury,99999);}

void jeeRunAcceptsMinorWithFunds() {final ctx = diplomaticSubValidatorContext(gpMinorGame(overtureStage: OvertureStage.nap,relationScore: relationScoreMinFriendly,),'gp1',); final r = validateJoinEmpireOverture(ctx: ctx,targetId: 'minor1',rel: const DiplomacyRelation(factionId1: 'gp1',factionId2: 'minor1',state: RelationState.atPeace,score: relationScoreMinFriendly,),currentStage: OvertureStage.nap,treasury: 1000000,); expect(r.result.status,OrderValidationStatus.accepted); expect(r.treasury,1000000,reason: 'joinEmpire toward minor does not debit on accept',);}

void jeeRunRejectsGpWithoutEmpireBuilding() {final ctx = diplomaticSubValidatorContext(twoGpGame(state: RelationState.atPeace),'gp1',); final r = validateJoinEmpireOverture(ctx: ctx,targetId: 'gp2',rel: const DiplomacyRelation(factionId1: 'gp1',factionId2: 'gp2',state: RelationState.atPeace,score: relationScoreMinFriendly,),currentStage: OvertureStage.nap,treasury: 99999,); expect(r.result.status,OrderValidationStatus.rejected); expect(r.result.reason,contains('Empire Building')); expect(r.treasury,99999);}

List<RunnableScenario> joinEmpireOvertureValidatorScenarios() => [
  rs('rejects when current stage is not NAP and preserves treasury (negative)', jeeRunRejectsWhenNotNap),
  rs('rejects when score below friendly threshold and preserves treasury (negative)', jeeRunRejectsWhenScoreBelowFriendly),
  rs('accepts minor target with funds at or above scaled cost and preserves treasury (positive)', jeeRunAcceptsMinorWithFunds),
  rs('rejects join empire toward GP without Empire Building tech (negative)', jeeRunRejectsGpWithoutEmpireBuilding),
];
