// Table-driven faction-membership diplomatic sub-validator scenarios (Refs #3949 wave 3).

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/alliance_validator.dart';
import 'package:colonizethis_orders/src/orders/validators/diplomatic/establish_overture_validator.dart';
import 'package:colonizethis_test/test.dart';
import '../../scenario_runner.dart';

import 'diplomatic_sub_validators_test_support.dart';

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

void dsfmRunAllianceAcceptsKnownGpIdenticallyWithAndWithoutSnapshot() {
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
    diplomaticSubValidatorContext(game, 'gp1', factionMembership: membership),
  ).validate(order: order, treasury: 0);

  expect(withoutSnapshot.result.status, OrderValidationStatus.accepted);
  expect(withSnapshot.result.status, OrderValidationStatus.accepted);
  expect(withSnapshot.treasury, withoutSnapshot.treasury);
}

void dsfmRunAllianceRejectsNonGpTargetIdenticallyWithSnapshot() {
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
    diplomaticSubValidatorContext(game, 'gp1', factionMembership: membership),
  ).validate(order: order, treasury: 0);

  expect(withoutSnapshot.result.status, OrderValidationStatus.rejected);
  expect(withSnapshot.result.status, OrderValidationStatus.rejected);
  expect(withSnapshot.result.reason, withoutSnapshot.result.reason);
}

void dsfmRunAllianceSnapshotRejectsTargetListedOnlyInGamePlayers() {
  final game = twoGpGame();
  final r =
      allianceSubValidator(
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
}

void
dsfmRunEstablishOvertureAcceptsTradeConsulateTowardMinorIdenticallyWithSnapshot() {
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
    diplomaticSubValidatorContext(game, 'gp1', factionMembership: membership),
  ).validate(order: order, treasury: initialTreasury);

  expect(withoutSnapshot.result.status, OrderValidationStatus.accepted);
  expect(withSnapshot.result.status, OrderValidationStatus.accepted);
  expect(withSnapshot.treasury, withoutSnapshot.treasury);
}

void dsfmRunEstablishOvertureSnapshotRejectsTargetAbsentFromSnapshot() {
  final game = gpMinorGame(overtureStage: OvertureStage.none);
  final r =
      establishOvertureSubValidator(
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
  expect(r.result.reason, contains('Minor Nations, Tribes, or Great Powers'));
  expect(r.treasury, overtureConsulateCost + 5);
}

void dsfmRunParentValidatorAcceptsEquivalentClassificationWithSnapshot() {
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
}

void dsfmRunParentValidatorSnapshotRejectsUnknownTargetId() {
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

List<RunnableScenario>
allianceSubValidatorFactionMembershipScenarios() => const [
  RunnableScenario(
    label: 'accepts known GP target identically with and without snapshot',
    run: dsfmRunAllianceAcceptsKnownGpIdenticallyWithAndWithoutSnapshot,
    refs: '#2394',
  ),
  RunnableScenario(
    label:
        'rejects non-GP target identically when snapshot has no GP membership',
    run: dsfmRunAllianceRejectsNonGpTargetIdenticallyWithSnapshot,
    refs: '#2394',
  ),
  RunnableScenario(
    label:
        'snapshot is consulted on active path: rejects target listed only in Game.players',
    run: dsfmRunAllianceSnapshotRejectsTargetListedOnlyInGamePlayers,
    refs: '#2394',
  ),
];

List<RunnableScenario>
establishOvertureSubValidatorFactionMembershipScenarios() => const [
  RunnableScenario(
    label: 'accepts Trade Consulate toward Minor identically with snapshot',
    run:
        dsfmRunEstablishOvertureAcceptsTradeConsulateTowardMinorIdenticallyWithSnapshot,
    refs: '#2394',
  ),
  RunnableScenario(
    label:
        'snapshot is consulted: rejects overture toward target absent from snapshot',
    run: dsfmRunEstablishOvertureSnapshotRejectsTargetAbsentFromSnapshot,
    refs: '#2394',
  ),
];

List<RunnableScenario>
diplomaticOrderValidatorFactionMembershipScenarios() => const [
  RunnableScenario(
    label: 'accepts equivalent classification with snapshot snapshot present',
    run: dsfmRunParentValidatorAcceptsEquivalentClassificationWithSnapshot,
    refs: '#2394',
  ),
  RunnableScenario(
    label: 'snapshot is consulted on active path: rejects unknown target id',
    run: dsfmRunParentValidatorSnapshotRejectsUnknownTargetId,
    refs: '#2394',
  ),
];

/// All faction-membership diplomatic sub-validator scenarios (union of families).
List<RunnableScenario> diplomaticSubValidatorsFactionMembershipScenarios() => [
  ...allianceSubValidatorFactionMembershipScenarios(),
  ...establishOvertureSubValidatorFactionMembershipScenarios(),
  ...diplomaticOrderValidatorFactionMembershipScenarios(),
];
