// Table-driven boycott / revokeBoycott validator scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/boycott_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/revoke_boycott_validator.dart';
import 'package:colonizethis_test/test.dart';
import '../../scenario_runner.dart';

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
  final game = boycottValidatorColonyHolderGame(state: RelationState.atWar);
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
  final r =
      revokeBoycottSubValidator(
        diplomaticSubValidatorContext(game, 'gp1'),
      ).validate(
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
  final r =
      revokeBoycottSubValidator(
        diplomaticSubValidatorContext(game, 'gp1'),
      ).validate(
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

/// One row in boycott validator scenario tables.

List<RunnableScenario> boycottSubValidatorScenarios() => const [
  RunnableScenario(
    label: 'accepts when issuer holds a colony and target GP is at peace',
    run: bctRunBoycottAcceptsColonyHolderAtPeace,
    refs: '#3753 R6',
  ),
  RunnableScenario(
    label: 'rejects when the issuer holds no colony',
    run: bctRunBoycottRejectsNoColony,
    refs: '#3753 R6',
  ),
  RunnableScenario(
    label: 'rejects when at war with the target GP',
    run: bctRunBoycottRejectsAtWar,
    refs: '#3753 R6',
  ),
  RunnableScenario(
    label: 'rejects a duplicate boycott for the same pair',
    run: bctRunBoycottRejectsDuplicate,
    refs: '#3753 R6',
  ),
  RunnableScenario(
    label: 'rejects a non-Great-Power target',
    run: bctRunBoycottRejectsNonGpTarget,
    refs: '#3753 R6',
  ),
];

List<RunnableScenario> revokeBoycottSubValidatorScenarios() => const [
  RunnableScenario(
    label: 'accepts when an active boycott exists for the pair',
    run: bctRunRevokeAcceptsActiveBoycott,
    refs: '#3753 R6',
  ),
  RunnableScenario(
    label: 'rejects when no active boycott exists for the pair',
    run: bctRunRevokeRejectsNoActiveBoycott,
    refs: '#3753 R6',
  ),
];

List<RunnableScenario> diplomaticOrderValidatorBoycottScenarios() => const [
  RunnableScenario(
    label: 'accepts a valid boycott order through the parent validator',
    run: bctRunParentValidatorAcceptsValidBoycott,
    refs: '#3753 R6',
  ),
];

/// All boycott validator scenarios (union of behavior-family tables).
List<RunnableScenario> boycottValidatorScenarios() => [
  ...boycottSubValidatorScenarios(),
  ...revokeBoycottSubValidatorScenarios(),
  ...diplomaticOrderValidatorBoycottScenarios(),
];
