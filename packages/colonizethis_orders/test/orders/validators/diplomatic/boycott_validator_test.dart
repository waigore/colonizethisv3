/// Tests for the `boycott` / `revokeBoycott` diplomatic sub-validators
/// (Refs #3753 R6). SPEC/program/orders.md § Diplomatic orders;
/// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
library;

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/boycott_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/revoke_boycott_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomatic_sub_validators_test_support.dart';

Game _colonyHolderGame({
  bool holdsColony = true,
  RelationState state = RelationState.atPeace,
  List<BoycottState> boycotts = const [],
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'gp1', displayName: 'GP1', isHuman: true),
      Player(id: 'gp2', displayName: 'GP2', isHuman: false),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    diplomacyRelations: [
      DiplomacyRelation(factionId1: 'gp1', factionId2: 'gp2', state: state),
    ],
    colonyStates: holdsColony
        ? const [
            ColonyState(tribeId: 'tribe1', colonyOfGpId: 'gp1', sinceTurn: 1),
          ]
        : const [],
    boycottStates: boycotts,
  );
}

void main() {
  group('boycottSubValidator', () {
    test('accepts when issuer holds a colony and target GP is at peace', () {
      final game = _colonyHolderGame();
      final r =
          boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
              .validate(
                order: const DiplomaticOrder(
                  type: DiplomaticOrderType.boycott,
                  targetFactionId: 'gp2',
                ),
                treasury: 100,
              );
      expect(r.result.status, OrderValidationStatus.accepted);
      expect(r.treasury, 100); // no treasury cost
    });

    test('rejects when the issuer holds no colony', () {
      final game = _colonyHolderGame(holdsColony: false);
      final r =
          boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
              .validate(
                order: const DiplomaticOrder(
                  type: DiplomaticOrderType.boycott,
                  targetFactionId: 'gp2',
                ),
                treasury: 0,
              );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('colony'));
    });

    test('rejects when at war with the target GP', () {
      final game = _colonyHolderGame(state: RelationState.atWar);
      final r =
          boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
              .validate(
                order: const DiplomaticOrder(
                  type: DiplomaticOrderType.boycott,
                  targetFactionId: 'gp2',
                ),
                treasury: 0,
              );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('war'));
    });

    test('rejects a duplicate boycott for the same pair', () {
      final game = _colonyHolderGame(
        boycotts: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 2),
        ],
      );
      final r =
          boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
              .validate(
                order: const DiplomaticOrder(
                  type: DiplomaticOrderType.boycott,
                  targetFactionId: 'gp2',
                ),
                treasury: 0,
              );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('already exists'));
    });

    test('rejects a non-Great-Power target', () {
      final game = _colonyHolderGame();
      final r =
          boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
              .validate(
                order: const DiplomaticOrder(
                  type: DiplomaticOrderType.boycott,
                  targetFactionId: 'minor1',
                ),
                treasury: 0,
              );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('Great Power'));
    });
  });

  group('revokeBoycottSubValidator', () {
    test('accepts when an active boycott exists for the pair', () {
      final game = _colonyHolderGame(
        boycotts: const [
          BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 2),
        ],
      );
      final r =
          revokeBoycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
              .validate(
                order: const DiplomaticOrder(
                  type: DiplomaticOrderType.revokeBoycott,
                  targetFactionId: 'gp2',
                ),
                treasury: 0,
              );
      expect(r.result.status, OrderValidationStatus.accepted);
    });

    test('rejects when no active boycott exists for the pair', () {
      final game = _colonyHolderGame();
      final r =
          revokeBoycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
              .validate(
                order: const DiplomaticOrder(
                  type: DiplomaticOrderType.revokeBoycott,
                  targetFactionId: 'gp2',
                ),
                treasury: 0,
              );
      expect(r.result.status, OrderValidationStatus.rejected);
      expect(r.result.reason, contains('active boycott'));
    });
  });

  group('DiplomaticOrderValidator boycott dispatch', () {
    test('accepts a valid boycott order through the parent validator', () {
      final game = _colonyHolderGame();
      final validator = DiplomaticOrderValidator(
        game: game,
        playerId: 'gp1',
        initialTreasury: 0,
      );
      final r = validator.validate(
        const DiplomaticOrder(
          type: DiplomaticOrderType.boycott,
          targetFactionId: 'gp2',
        ),
        previousRejected: false,
      );
      expect(r.result.status, OrderValidationStatus.accepted);
    });
  });
}
