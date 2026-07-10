// Table-driven order suggestion context helper scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_resolution_context.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../scenario_runner.dart';
import 'order_suggestion_context_helpers_fixtures.dart';

void oschRunAppendDiplomaticOrderForTrialExisting() {
  const existing = DiplomaticOrder(
    type: DiplomaticOrderType.offerPeace,
    targetFactionId: 'minorA',
  );
  const added = DiplomaticOrder(
    type: DiplomaticOrderType.declareWar,
    targetFactionId: 'minorB',
  );
  final orders = Orders(
    diplomaticOrdersByPlayerId: {
      'gp1': [existing],
    },
  );

  final updated = appendDiplomaticOrderForTrial(orders, 'gp1', added);

  expect(updated.diplomaticOrdersByPlayerId['gp1'], [existing, added]);
  expect(orders.diplomaticOrdersByPlayerId['gp1'], [existing]);
}

void oschRunAppendDiplomaticOrderForTrialAbsent() {
  const added = DiplomaticOrder(
    type: DiplomaticOrderType.alliance,
    targetFactionId: 'gp2',
  );
  const orders = Orders();

  final updated = appendDiplomaticOrderForTrial(orders, 'gp9', added);

  expect(updated.diplomaticOrdersByPlayerId['gp9'], [added]);
  expect(orders.diplomaticOrdersByPlayerId.containsKey('gp9'), isFalse);
}

void oschRunOvertureNextProgression() {
  expect(OvertureStage.none.next, OvertureStage.tradeConsulate);
  expect(OvertureStage.tradeConsulate.next, OvertureStage.embassy);
  expect(OvertureStage.embassy.next, OvertureStage.nap);
  expect(OvertureStage.nap.next, OvertureStage.joinEmpire);
}

void oschRunOvertureNextFinalNull() {
  expect(OvertureStage.joinEmpire.next, isNull);
}

void oschRunOverturePreviousLeftInverse() {
  for (final stage in OvertureStage.values) {
    final forward = stage.next;
    if (forward == null) {
      continue;
    }
    expect(forward.previous, stage);
  }
}

void oschRunOverturePreviousThenNext() {
  for (final stage in OvertureStage.values) {
    if (stage == OvertureStage.none) {
      continue;
    }
    expect(stage.previous.next, stage);
  }
}

void oschRunOverturePreviousReversesNext() {
  for (final stage in [
    OvertureStage.none,
    OvertureStage.tradeConsulate,
    OvertureStage.embassy,
    OvertureStage.nap,
  ]) {
    final forward = stage.next!;
    expect(forward.previous, stage);
  }
}

void oschRunOverturePreviousNoneSelf() {
  expect(OvertureStage.none.previous, OvertureStage.none);
}

void oschRunOverturePreviousJoinEmpireNap() {
  expect(OvertureStage.joinEmpire.previous, OvertureStage.nap);
}

void oschRunNavalMoveAcceptedBoolean() {
  final accepted = isNavalMoveOrderAccepted(
    oschMinimalGame,
    oschEmptyTopology,
    'gp1',
    const Orders(),
    const NavalMoveOrder(fleetId: 'fleet1', destinationSeaZoneId: 'sea1'),
  );
  expect(accepted, isFalse);
}

void oschRunNavalMissionAcceptedBoolean() {
  final accepted = isNavalMissionOrderAccepted(
    oschMinimalGame,
    oschEmptyTopology,
    'gp1',
    const Orders(),
    const NavalMissionOrder(fleetId: 'fleet1', mission: 'patrol'),
  );
  expect(accepted, isFalse);
}

void oschRunDiplomaticAcceptedBoolean() {
  final accepted = isDiplomaticOrderAccepted(
    oschMinimalGame,
    oschEmptyTopology,
    'gp1',
    const Orders(),
    const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: 'minor1',
    ),
  );
  expect(accepted, isFalse);
}

void oschRunDiplomaticAcceptedMatchesDefaultPath() {
  final game = oschDiplomacyGame();
  const candidate = oschAllianceCandidate;
  final sharedView = buildPlayerView(game, oschEmptyTopology, 'gp1');
  final sharedUnits = unitsByIdFromWorld(game.worldState);
  final defaultPath = isDiplomaticOrderAccepted(
    game,
    oschEmptyTopology,
    'gp1',
    const Orders(),
    candidate,
  );
  final sharedPath = isDiplomaticOrderAccepted(
    game,
    oschEmptyTopology,
    'gp1',
    const Orders(),
    candidate,
    resolution: orderResolutionContextFromView(
      sharedView,
      game,
      unitsById: sharedUnits,
    ),
  );
  expect(sharedPath, defaultPath);
  expect(defaultPath, isTrue);
}

void oschRunStatelessAcceptHelpersReuseValidator() {
  final game = oschDiplomacyGame();
  const topology = oschEmptyTopology;
  const baseOrders = Orders();
  final sharedView = buildPlayerView(game, topology, 'gp1');
  final sharedUnits = unitsByIdFromWorld(game.worldState);
  resetIncrementalCandidateValidatorBuildCountForTests();
  final sharedValidator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: 'gp1',
    baseOrders: baseOrders,
    resolution: orderResolutionContextFromView(
      sharedView,
      game,
      unitsById: sharedUnits,
    ),
  );
  expect(incrementalCandidateValidatorBuildCountForTests, 1);

  const candidate = oschAllianceCandidate;
  for (var i = 0; i < 5; i++) {
    isDiplomaticOrderAccepted(
      game,
      topology,
      'gp1',
      baseOrders,
      candidate,
      sharedCandidateValidator: sharedValidator,
    );
    isMoveOrderAccepted(
      game,
      topology,
      'gp1',
      baseOrders,
      const MoveOrder(unitId: 'u1', destinationTileKey: 't'),
      sharedCandidateValidator: sharedValidator,
    );
  }
  expect(
    incrementalCandidateValidatorBuildCountForTests,
    1,
    reason:
        'shared validator path must not call buildIncrementalCandidateValidator '
        'per probe (Refs #2394)',
  );
}

void oschRunDiplomaticAcceptedWithValidatorMatches() {
  final game = oschDiplomacyGame();
  const topology = oschEmptyTopology;
  const candidate = oschAllianceCandidate;
  const baseOrders = Orders();
  final sharedView = buildPlayerView(game, topology, 'gp1');
  final sharedUnits = unitsByIdFromWorld(game.worldState);
  final validator = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: 'gp1',
    baseOrders: baseOrders,
    resolution: orderResolutionContextFromView(
      sharedView,
      game,
      unitsById: sharedUnits,
    ),
  );
  expect(
    isDiplomaticOrderAcceptedWithValidator(validator, candidate),
    isDiplomaticOrderAccepted(
      game,
      topology,
      'gp1',
      baseOrders,
      candidate,
      resolution: orderResolutionContextFromView(
        sharedView,
        game,
        unitsById: sharedUnits,
      ),
    ),
  );
}

/// Scenarios for appendDiplomaticOrderForTrial.
List<RunnableScenario> appendDiplomaticOrderForTrialScenarios() => const [
  rs('appends order for existing player list', oschRunAppendDiplomaticOrderForTrialExisting),
  rs('creates new player list when absent', oschRunAppendDiplomaticOrderForTrialAbsent),
];

/// Scenarios for OvertureStageChain.next.
List<RunnableScenario> overtureStageChainNextScenarios() => const [
  rs('follows expected progression', oschRunOvertureNextProgression),
  rs('returns null when already at final stage', oschRunOvertureNextFinalNull),
];

/// Scenarios for OvertureStageChain.previous.
List<RunnableScenario> overtureStageChainPreviousScenarios() => const [
  rs('next is left inverse of previous for every non-terminal stage', oschRunOverturePreviousLeftInverse),
  rs('previous then next restores stage for every stage past none', oschRunOverturePreviousThenNext),
  rs('reverses next for progression chain', oschRunOverturePreviousReversesNext),
  rs('none maps to itself', oschRunOverturePreviousNoneSelf),
  rs('joinEmpire previous is nap', oschRunOverturePreviousJoinEmpireNap),
];

/// Scenarios for acceptance wrapper helpers.
List<RunnableScenario>
orderSuggestionContextAcceptanceWrapperScenarios() => const [
  rs('isNavalMoveOrderAccepted returns a boolean result', oschRunNavalMoveAcceptedBoolean),
  rs('isNavalMissionOrderAccepted returns a boolean result', oschRunNavalMissionAcceptedBoolean),
  rs('isDiplomaticOrderAccepted returns a boolean result', oschRunDiplomaticAcceptedBoolean),
  rs('isDiplomaticOrderAccepted matches default path when view/units shared', oschRunDiplomaticAcceptedMatchesDefaultPath),
  rs('stateless accept helpers reuse sharedCandidateValidator without rebuild', oschRunStatelessAcceptHelpersReuseValidator, '#2394'),
  rs('isDiplomaticOrderAcceptedWithValidator matches isDiplomaticOrderAccepted', oschRunDiplomaticAcceptedWithValidatorMatches),
];
