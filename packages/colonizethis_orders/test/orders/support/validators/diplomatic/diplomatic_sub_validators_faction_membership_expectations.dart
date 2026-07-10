// Compact faction-membership diplomatic sub-validator assertions (Refs #3949 wave 3).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/alliance_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_overture_validator.dart';
import 'package:colonizethis_test/test.dart';

import 'diplomatic_sub_validators_test_support.dart';

/// Pins for [diplomaticSubValidatorsFactionMembershipScenarios] rows.
enum DiplomaticSubValidatorsFactionMembershipTarget {
  allianceAcceptsKnownGpIdenticallyWithAndWithoutSnapshot,
  allianceRejectsNonGpTargetIdenticallyWithSnapshot,
  allianceSnapshotRejectsTargetListedOnlyInGamePlayers,
  establishOvertureAcceptsTradeConsulateTowardMinorIdenticallyWithSnapshot,
  establishOvertureSnapshotRejectsTargetAbsentFromSnapshot,
  parentValidatorAcceptsEquivalentClassificationWithSnapshot,
  parentValidatorSnapshotRejectsUnknownTargetId,
}

DiplomacyFactionMembership _emptyFactionMembership() =>
    DiplomacyFactionMembership.from(
      Game(
        id: 'empty',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [],
      ),
    );

void runDiplomaticSubValidatorsFactionMembershipExpectation(
  DiplomaticSubValidatorsFactionMembershipTarget target,
) {
  switch (target) {
    case DiplomaticSubValidatorsFactionMembershipTarget
        .allianceAcceptsKnownGpIdenticallyWithAndWithoutSnapshot:
      final game = twoGpGame();
      final membership = DiplomacyFactionMembership.from(game);
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'gp2',
      );

      final withoutSnapshot = allianceSubValidator(
        diplomaticSubValidatorContext(game, 'gp1'),
      ).validate(order: order, treasury: 0);
      final withSnapshot = allianceSubValidator(
        diplomaticSubValidatorContext(
          game,
          'gp1',
          factionMembership: membership,
        ),
      ).validate(order: order, treasury: 0);

      expect(withoutSnapshot.result.status, OrderValidationStatus.accepted);
      expect(withSnapshot.result.status, OrderValidationStatus.accepted);
      expect(withSnapshot.treasury, withoutSnapshot.treasury);

    case DiplomaticSubValidatorsFactionMembershipTarget
        .allianceRejectsNonGpTargetIdenticallyWithSnapshot:
      final game = gpMinorGame();
      final membership = DiplomacyFactionMembership.from(game);
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.alliance,
        targetFactionId: 'minor1',
      );

      final withoutSnapshot = allianceSubValidator(
        diplomaticSubValidatorContext(game, 'gp1'),
      ).validate(order: order, treasury: 0);
      final withSnapshot = allianceSubValidator(
        diplomaticSubValidatorContext(
          game,
          'gp1',
          factionMembership: membership,
        ),
      ).validate(order: order, treasury: 0);

      expect(withoutSnapshot.result.status, OrderValidationStatus.rejected);
      expect(withSnapshot.result.status, OrderValidationStatus.rejected);
      expect(withSnapshot.result.reason, withoutSnapshot.result.reason);

    case DiplomaticSubValidatorsFactionMembershipTarget
        .allianceSnapshotRejectsTargetListedOnlyInGamePlayers:
      final game = twoGpGame();
      final r = allianceSubValidator(
        diplomaticSubValidatorContext(
          game,
          'gp1',
          factionMembership: _emptyFactionMembership(),
        ),
      ).validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.alliance,
          targetFactionId: 'gp2',
        ),
        treasury: 0,
      );

      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('Great Power'));

    case DiplomaticSubValidatorsFactionMembershipTarget
        .establishOvertureAcceptsTradeConsulateTowardMinorIdenticallyWithSnapshot:
      final game = gpMinorGame(overtureStage: OvertureStage.none);
      final membership = DiplomacyFactionMembership.from(game);
      const order = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'minor1',
        overtureStage: OvertureStage.tradeConsulate,
      );
      final initialTreasury = overtureConsulateCost + 5;

      final withoutSnapshot = establishOvertureSubValidator(
        diplomaticSubValidatorContext(game, 'gp1'),
      ).validate(order: order, treasury: initialTreasury);
      final withSnapshot = establishOvertureSubValidator(
        diplomaticSubValidatorContext(
          game,
          'gp1',
          factionMembership: membership,
        ),
      ).validate(order: order, treasury: initialTreasury);

      expect(withoutSnapshot.result.status, OrderValidationStatus.accepted);
      expect(withSnapshot.result.status, OrderValidationStatus.accepted);
      expect(withSnapshot.treasury, withoutSnapshot.treasury);

    case DiplomaticSubValidatorsFactionMembershipTarget
        .establishOvertureSnapshotRejectsTargetAbsentFromSnapshot:
      final game = gpMinorGame(overtureStage: OvertureStage.none);
      final r = establishOvertureSubValidator(
        diplomaticSubValidatorContext(
          game,
          'gp1',
          factionMembership: _emptyFactionMembership(),
        ),
      ).validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
        treasury: overtureConsulateCost + 5,
      );

      expect(r.result.status, OrderValidationStatus.rejected);
      expect(
        r.result.reason,
        contains('Minor Nations, Tribes, or Great Powers'),
      );
      expect(r.treasury, overtureConsulateCost + 5);

    case DiplomaticSubValidatorsFactionMembershipTarget
        .parentValidatorAcceptsEquivalentClassificationWithSnapshot:
      final game = gpMinorGame();
      final membership = DiplomacyFactionMembership.from(game);
      final withoutSnapshot = DiplomaticOrderValidator(
        game: game,
        playerId: 'gp1',
        initialTreasury: overtureConsulateCost + 1000,
      );
      final withSnapshot = DiplomaticOrderValidator(
        game: game,
        playerId: 'gp1',
        initialTreasury: overtureConsulateCost + 1000,
        factionMembership: membership,
      );

      const order = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'minor1',
        overtureStage: OvertureStage.tradeConsulate,
      );

      final a = withoutSnapshot.validate(order, previousRejected: false);
      final b = withSnapshot.validate(order, previousRejected: false);
      expect(b.result.status, a.result.status);
      expect(b.treasury, a.treasury);

    case DiplomaticSubValidatorsFactionMembershipTarget
        .parentValidatorSnapshotRejectsUnknownTargetId:
      final game = gpMinorGame();
      final validator = DiplomaticOrderValidator(
        game: game,
        playerId: 'gp1',
        initialTreasury: overtureConsulateCost + 1000,
        factionMembership: _emptyFactionMembership(),
      );

      final r = validator.validate(
        const DiplomaticOrder(
          type: DiplomaticOrderType.establishOverture,
          targetFactionId: 'minor1',
          overtureStage: OvertureStage.tradeConsulate,
        ),
        previousRejected: false,
      );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('Target faction not found'));
  }
}
