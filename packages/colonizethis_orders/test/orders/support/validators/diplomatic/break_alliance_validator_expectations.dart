// Compact breakAlliance validator assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/break_alliance_validator.dart';
import 'package:colonizethis_test/test.dart';

import 'break_alliance_validator_fixtures.dart';
import 'diplomatic_sub_validators_test_support.dart';

/// Pins for [breakAllianceValidatorScenarios] rows.
enum BreakAllianceValidatorTarget {
  acceptsFormalAllianceWithGpTarget,
  rejectsWhileAtWar,
  rejectsNoFormalAlliance,
  rejectsNonGpTarget,
  parentValidatorAcceptsValidBreakAlliance,
}

void runBreakAllianceValidatorExpectation(BreakAllianceValidatorTarget target) {
  switch (target) {
    case BreakAllianceValidatorTarget.acceptsFormalAllianceWithGpTarget:
      final game = breakAllianceValidatorTwoGpAllianceGame();
      final r =
          breakAllianceSubValidator(
            diplomaticSubValidatorContext(game, 'gp1'),
          ).validate(
            order: const DiplomaticOrder(
              type: DiplomaticOrderType.breakAlliance,
              targetFactionId: 'gp2',
            ),
            treasury: 0,
          );
      expect(r.result.status, OrderValidationStatus.accepted);
      expect(r.treasury, 0);

    case BreakAllianceValidatorTarget.rejectsWhileAtWar:
      final game = breakAllianceValidatorTwoGpAllianceGame(
        formalAlliance: false,
        state: RelationState.atWar,
      );
      final r =
          breakAllianceSubValidator(
            diplomaticSubValidatorContext(game, 'gp1'),
          ).validate(
            order: const DiplomaticOrder(
              type: DiplomaticOrderType.breakAlliance,
              targetFactionId: 'gp2',
            ),
            treasury: 0,
          );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('formal alliance'));

    case BreakAllianceValidatorTarget.rejectsNoFormalAlliance:
      final game = breakAllianceValidatorTwoGpAllianceGame(formalAlliance: false);
      final r =
          breakAllianceSubValidator(
            diplomaticSubValidatorContext(game, 'gp1'),
          ).validate(
            order: const DiplomaticOrder(
              type: DiplomaticOrderType.breakAlliance,
              targetFactionId: 'gp2',
            ),
            treasury: 0,
          );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('formal alliance'));

    case BreakAllianceValidatorTarget.rejectsNonGpTarget:
      final game = breakAllianceValidatorTwoGpAllianceGame();
      final r =
          breakAllianceSubValidator(
            diplomaticSubValidatorContext(game, 'gp1'),
          ).validate(
            order: const DiplomaticOrder(
              type: DiplomaticOrderType.breakAlliance,
              targetFactionId: 'minor1',
            ),
            treasury: 0,
          );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('Great Power'));

    case BreakAllianceValidatorTarget.parentValidatorAcceptsValidBreakAlliance:
      final game = breakAllianceValidatorTwoGpAllianceGame();
      final validator = DiplomaticOrderValidator(
        game: game,
        playerId: 'gp1',
        initialTreasury: 0,
      );
      final r = validator.validate(
        const DiplomaticOrder(
          type: DiplomaticOrderType.breakAlliance,
          targetFactionId: 'gp2',
        ),
        previousRejected: false,
      );
      expect(r.result.status, OrderValidationStatus.accepted);
  }
}
