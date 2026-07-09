// ArmyMoveValidator armiesById equivalence assertions (Refs #2394, #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'army_move_validator_armies_by_id_fixtures.dart';

/// Pins for [armyMoveValidatorArmiesByIdScenarios] rows.
enum ArmyMoveValidatorArmiesByIdTarget {
  acceptedIdenticalWithAndWithout,
  rejectedIdenticalWithAndWithout,
  missingArmyIdRejected,
  incrementalMatchesDirectValidate,
  factionMembershipDeclareWarGuard,
}

void runArmyMoveValidatorArmiesByIdExpectation(
  ArmyMoveValidatorArmiesByIdTarget target,
) {
  final topology = amvArmiesByIdTwoProvinceTopology();
  switch (target) {
    case ArmyMoveValidatorArmiesByIdTarget.acceptedIdenticalWithAndWithout:
      final game = amvArmiesByIdSampleGame();
      final view = buildPlayerView(game, topology, 'p1');
      final armiesById = amvArmiesByIdFromGame(game);
      final order = ArmyMoveOrder(
        armyId: fieldArmyIdFor('p1', '$amvArmiesByIdOw|P1'),
        destinationProvinceId: '$amvArmiesByIdOw|P2',
      );

      final without = amvArmiesByIdValidator.validate(
        order,
        game,
        'p1',
        const [],
        view,
        topology,
      );
      final with_ = amvArmiesByIdValidator.validate(
        order,
        game,
        'p1',
        const [],
        view,
        topology,
        armiesById: armiesById,
      );

      expect(with_.status, without.status);
      expect(with_.status, OrderValidationStatus.accepted);

    case ArmyMoveValidatorArmiesByIdTarget.rejectedIdenticalWithAndWithout:
      final game = amvArmiesByIdSampleGame();
      final view = buildPlayerView(game, topology, 'p1');
      final armiesById = amvArmiesByIdFromGame(game);
      const order = ArmyMoveOrder(
        armyId: 'army_does_not_exist',
        destinationProvinceId: '$amvArmiesByIdOw|P2',
      );

      final without = amvArmiesByIdValidator.validate(
        order,
        game,
        'p1',
        const [],
        view,
        topology,
      );
      final with_ = amvArmiesByIdValidator.validate(
        order,
        game,
        'p1',
        const [],
        view,
        topology,
        armiesById: armiesById,
      );

      expect(with_.status, without.status);
      expect(with_.status, OrderValidationStatus.rejected);
      expect(with_.reason, without.reason);

    case ArmyMoveValidatorArmiesByIdTarget.missingArmyIdRejected:
      final game = amvArmiesByIdSampleGame();
      final view = buildPlayerView(game, topology, 'p1');
      final partialMap = <String, Army>{};
      final order = ArmyMoveOrder(
        armyId: fieldArmyIdFor('p1', '$amvArmiesByIdOw|P1'),
        destinationProvinceId: '$amvArmiesByIdOw|P2',
      );

      final result = amvArmiesByIdValidator.validate(
        order,
        game,
        'p1',
        const [],
        view,
        topology,
        armiesById: partialMap,
      );

      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Invalid army move');

    case ArmyMoveValidatorArmiesByIdTarget.incrementalMatchesDirectValidate:
      final game = amvArmiesByIdSampleGame();
      final view = buildPlayerView(game, topology, 'p1');
      final armiesById = amvArmiesByIdFromGame(game);
      final order = ArmyMoveOrder(
        armyId: fieldArmyIdFor('p1', '$amvArmiesByIdOw|P1'),
        destinationProvinceId: '$amvArmiesByIdOw|P2',
      );

      final incremental = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: topology,
        playerId: 'p1',
        basePrefix: const Orders(),
      );

      final directResult = amvArmiesByIdValidator.validate(
        order,
        game,
        'p1',
        const [],
        view,
        topology,
        armiesById: armiesById,
      );

      expect(incremental.isArmyMoveAccepted(order), directResult.isAccepted);
      expect(directResult.status, OrderValidationStatus.accepted);

    case ArmyMoveValidatorArmiesByIdTarget.factionMembershipDeclareWarGuard:
      final game = amvArmiesByIdTwoGpPeaceGame();
      final view = buildPlayerView(game, topology, 'p1');
      final membership = DiplomacyFactionMembership.from(game);
      final order = ArmyMoveOrder(
        armyId: fieldArmyIdFor('p1', '$amvArmiesByIdOw|P1'),
        destinationProvinceId: '$amvArmiesByIdOw|P2',
      );

      final without = amvArmiesByIdValidator.validate(
        order,
        game,
        'p1',
        const [],
        view,
        topology,
      );
      final withMembership = amvArmiesByIdValidator.validate(
        order,
        game,
        'p1',
        const [],
        view,
        topology,
        factionMembership: membership,
      );

      expect(withMembership.status, without.status);
      expect(without.status, OrderValidationStatus.rejected);
      expect(without.reason, contains('declare war'));
      expect(withMembership.reason, without.reason);
  }
}
