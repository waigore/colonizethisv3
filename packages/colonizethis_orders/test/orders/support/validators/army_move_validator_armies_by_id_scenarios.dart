// Table-driven ArmyMoveValidator armiesById scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'army_move_validator_armies_by_id_fixtures.dart';
// dart format off

void amvabiRunAcceptedIdenticalWithAndWithout() {final topology = amvArmiesByIdTwoProvinceTopology(); final game = amvArmiesByIdSampleGame(); final view = buildPlayerView(game,topology,'p1'); final armiesById = amvArmiesByIdFromGame(game); final order = ArmyMoveOrder(armyId: fieldArmyIdFor('p1','$amvArmiesByIdOw|P1'),destinationProvinceId: '$amvArmiesByIdOw|P2',); final without = amvArmiesByIdValidator.validate(order,game,'p1',const [],view,topology,); final with_ = amvArmiesByIdValidator.validate(order,game,'p1',const [],view,topology,armiesById: armiesById,); expect(with_.status,without.status); expect(with_.status,OrderValidationStatus.accepted);}

void amvabiRunRejectedIdenticalWithAndWithout() {final topology = amvArmiesByIdTwoProvinceTopology(); final game = amvArmiesByIdSampleGame(); final view = buildPlayerView(game,topology,'p1'); final armiesById = amvArmiesByIdFromGame(game); const order = ArmyMoveOrder(armyId: 'army_does_not_exist',destinationProvinceId: '$amvArmiesByIdOw|P2',); final without = amvArmiesByIdValidator.validate(order,game,'p1',const [],view,topology,); final with_ = amvArmiesByIdValidator.validate(order,game,'p1',const [],view,topology,armiesById: armiesById,); expect(with_.status,without.status); expect(with_.status,OrderValidationStatus.rejected); expect(with_.reason,without.reason);}

void amvabiRunMissingArmyIdRejected() {final topology = amvArmiesByIdTwoProvinceTopology(); final game = amvArmiesByIdSampleGame(); final view = buildPlayerView(game,topology,'p1'); final partialMap = <String,Army>{}; final order = ArmyMoveOrder(armyId: fieldArmyIdFor('p1','$amvArmiesByIdOw|P1'),destinationProvinceId: '$amvArmiesByIdOw|P2',); final result = amvArmiesByIdValidator.validate(order,game,'p1',const [],view,topology,armiesById: partialMap,); expect(result.status,OrderValidationStatus.rejected); expect(result.reason,'Invalid army move');}

void amvabiRunIncrementalMatchesDirectValidate() {final topology = amvArmiesByIdTwoProvinceTopology(); final game = amvArmiesByIdSampleGame(); final view = buildPlayerView(game,topology,'p1'); final armiesById = amvArmiesByIdFromGame(game); final order = ArmyMoveOrder(armyId: fieldArmyIdFor('p1','$amvArmiesByIdOw|P1'),destinationProvinceId: '$amvArmiesByIdOw|P2',); final incremental = IncrementalCandidateValidator.forPlayer(game: game,topology: topology,playerId: 'p1',basePrefix: const Orders(),); final directResult = amvArmiesByIdValidator.validate(order,game,'p1',const [],view,topology,armiesById: armiesById,); expect(incremental.isArmyMoveAccepted(order),directResult.isAccepted); expect(directResult.status,OrderValidationStatus.accepted);}

void amvabiRunFactionMembershipDeclareWarGuard() {final topology = amvArmiesByIdTwoProvinceTopology(); final game = amvArmiesByIdTwoGpPeaceGame(); final view = buildPlayerView(game,topology,'p1'); final membership = DiplomacyFactionMembership.from(game); final order = ArmyMoveOrder(armyId: fieldArmyIdFor('p1','$amvArmiesByIdOw|P1'),destinationProvinceId: '$amvArmiesByIdOw|P2',); final without = amvArmiesByIdValidator.validate(order,game,'p1',const [],view,topology,); final withMembership = amvArmiesByIdValidator.validate(order,game,'p1',const [],view,topology,factionMembership: membership,); expect(withMembership.status,without.status); expect(without.status,OrderValidationStatus.rejected); expect(without.reason,contains('declare war')); expect(withMembership.reason,without.reason);}

List<RunnableScenario> armyMoveValidatorArmiesByIdScenarios() => [
  rs('accepted result is identical with and without supplied armiesById', amvabiRunAcceptedIdenticalWithAndWithout, '#2394'),
  rs('rejected result is identical with and without supplied armiesById', amvabiRunRejectedIdenticalWithAndWithout, '#2394'),
  rs('armiesById missing the target army id is rejected as Invalid army move', amvabiRunMissingArmyIdRejected, '#2394'),
  rs('IncrementalCandidateValidator.isArmyMoveAccepted matches ArmyMoveValidator.validate (Refs #2394 incremental hot path)', amvabiRunIncrementalMatchesDirectValidate, '#2394'),
  rs('factionMembership path matches legacy GP declare-war guard (Refs #2394)', amvabiRunFactionMembershipDeclareWarGuard, '#2394'),
];
