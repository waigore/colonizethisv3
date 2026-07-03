/// Tests for the `breakAlliance` diplomatic sub-validator (R11).
/// SPEC/program/orders.md § Diplomatic orders / break alliance.
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/break_alliance_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_sub_validators_test_support.dart';

Game _twoGpAllianceGame({
  bool formalAlliance = true,
  RelationState state = RelationState.atPeace,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: true),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    diplomacyRelations: [
      DiplomacyRelation(
        factionId1: 'gp1',
        factionId2: 'gp2',
        score: 80,
        level: RelationLevel.allied,
        state: state,
        formalAlliance: formalAlliance,
      ),
    ],
  );
}

void main() {
  group('breakAllianceSubValidator', () {
    test('accepts when a formal alliance exists with the GP target', () {
      final game = _twoGpAllianceGame();
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
      expect(r.treasury, 0); // no treasury cost
    });

    test('rejects while at war (war invariant cleared the alliance)', () {
      // Under the war invariant (SPEC/game/diplomacy.md § Alliances), an at-war
      // pair never holds a formal alliance, so Break Alliance is rejected:
      // there is no treaty to break.
      final game = _twoGpAllianceGame(
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
    });

    test('rejects when no formal alliance exists with the target', () {
      final game = _twoGpAllianceGame(formalAlliance: false);
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
    });

    test('rejects a non-Great-Power target', () {
      final game = _twoGpAllianceGame();
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
    });
  });

  group('DiplomaticOrderValidator breakAlliance dispatch', () {
    test(
      'accepts a valid breakAlliance order through the parent validator',
      () {
        final game = _twoGpAllianceGame();
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
      },
    );
  });
}
