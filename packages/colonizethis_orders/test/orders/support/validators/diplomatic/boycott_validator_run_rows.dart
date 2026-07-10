// Scenario run tear-offs for boycott / revokeBoycott validators (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/boycott_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/revoke_boycott_validator.dart';
import 'package:colonizethis_test/test.dart';

import 'boycott_validator_fixtures.dart';
import 'diplomatic_sub_validators_test_support.dart';

void bctRunBoycottAcceptsColonyHolderAtPeace() {
  final game = boycottValidatorColonyHolderGame();
  final r = boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
      .validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.boycott,
          targetFactionId: 'gp2',
        ),
        treasury: 100,
      );
  expect(r.result.status, OrderValidationStatus.accepted);
  expect(r.treasury, 100);
}

void bctRunBoycottRejectsNoColony() {
  final game = boycottValidatorColonyHolderGame(holdsColony: false);
  final r = boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
      .validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.boycott,
          targetFactionId: 'gp2',
        ),
        treasury: 0,
      );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('colony'));
}

void bctRunBoycottRejectsAtWar() {
  final game = boycottValidatorColonyHolderGame(
    state: RelationState.atWar,
  );
  final r = boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
      .validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.boycott,
          targetFactionId: 'gp2',
        ),
        treasury: 0,
      );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('war'));
}

void bctRunBoycottRejectsDuplicate() {
  final game = boycottValidatorColonyHolderGame(
    boycotts: const [
      BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 2),
    ],
  );
  final r = boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
      .validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.boycott,
          targetFactionId: 'gp2',
        ),
        treasury: 0,
      );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('already exists'));
}

void bctRunBoycottRejectsNonGpTarget() {
  final game = boycottValidatorColonyHolderGame();
  final r = boycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
      .validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.boycott,
          targetFactionId: 'minor1',
        ),
        treasury: 0,
      );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('Great Power'));
}

void bctRunRevokeAcceptsActiveBoycott() {
  final game = boycottValidatorColonyHolderGame(
    boycotts: const [
      BoycottState(gpId: 'gp1', targetGpId: 'gp2', sinceTurn: 2),
    ],
  );
  final r = revokeBoycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
      .validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.revokeBoycott,
          targetFactionId: 'gp2',
        ),
        treasury: 0,
      );
  expect(r.result.status, OrderValidationStatus.accepted);
}

void bctRunRevokeRejectsNoActiveBoycott() {
  final game = boycottValidatorColonyHolderGame();
  final r = revokeBoycottSubValidator(diplomaticSubValidatorContext(game, 'gp1'))
      .validate(
        order: const DiplomaticOrder(
          type: DiplomaticOrderType.revokeBoycott,
          targetFactionId: 'gp2',
        ),
        treasury: 0,
      );
  expect(r.result.status, OrderValidationStatus.rejected);
  expect(r.result.reason, contains('active boycott'));
}

void bctRunParentValidatorAcceptsValidBoycott() {
  final game = boycottValidatorColonyHolderGame();
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
}
