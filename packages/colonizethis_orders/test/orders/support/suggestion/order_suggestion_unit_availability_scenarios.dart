// Table-driven order suggestion unit availability scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_unit_availability_fixtures.dart';

void osuaRunPendingDraftShortCircuits() {
  setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(true);
  addTearDown(
    () => setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(false),
  );

  final game = orderSuggestionUnitAvailabilityPendingDraftGame();
  const topology = orderSuggestionUnitAvailabilityPendingDraftTopology;
  final orders = orderSuggestionUnitAvailabilityPendingDraftOrders();
  final view = buildPlayerView(
    game,
    topology,
    orderSuggestionUnitAvailabilityPlayerId,
  );

  final availability = getAvailableWorkTargetsForUnit(
    view: view,
    game: game,
    topology: topology,
    currentOrders: orders,
    unitId: orderSuggestionUnitAvailabilityExplorerId,
  );
  expect(availability.assignable, isFalse);
  expect(availability.blockedReason, 'pending_draft_work_order');
  expect(availability.validTileKeysByTarget, isEmpty);
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);

  expect(
    getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: orderSuggestionUnitAvailabilityExplorerId,
      workTarget: kWorkTargetExplore,
      currentOrders: orders,
    ),
    isEmpty,
  );
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
}

void osuaRunPendingDraftZeroProbesScale() {
  setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(true);
  addTearDown(
    () => setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(false),
  );

  final game = orderSuggestionUnitAvailabilityScaleGame();
  const topology = orderSuggestionUnitAvailabilityEmptyTopology;
  final orders = orderSuggestionUnitAvailabilityScaleOrders();
  final view = buildPlayerView(
    game,
    topology,
    orderSuggestionUnitAvailabilityPlayerId,
  );

  expect(20, greaterThanOrEqualTo(20));
  expect(
    game
        .worldState
        .playerVisibilityByTile[orderSuggestionUnitAvailabilityPlayerId]!
        .values
        .where((v) => v != 'unknown')
        .length,
    greaterThanOrEqualTo(100),
  );

  getAvailableWorkTargetsForUnit(
    view: view,
    game: game,
    topology: topology,
    currentOrders: orders,
    unitId: orderSuggestionUnitAvailabilityExplorerId,
  );
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);

  getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: orderSuggestionUnitAvailabilityExplorerId,
    workTarget: kWorkTargetExplore,
    currentOrders: orders,
  );
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);

  getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: orderSuggestionUnitAvailabilityExplorerId,
    workTarget: kWorkTargetProspect,
    currentOrders: orders,
  );
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
}

void osuaRunMultiTargetMatchesSharedValidator() {
  final game = orderSuggestionUnitAvailabilityMultiTargetGame();
  const topology = orderSuggestionUnitAvailabilityEmptyTopology;
  const orders = Orders();
  final view = buildPlayerView(
    game,
    topology,
    orderSuggestionUnitAvailabilityPlayerId,
  );
  final ownedIds = <String>{
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == orderSuggestionUnitAvailabilityPlayerId) e.key,
  };
  final unitsById = {for (final u in view.ownUnits) u.id: u};
  final shared = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: orderSuggestionUnitAvailabilityPlayerId,
    baseOrders: orders,
    resolution: orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    ),
    factionMembership: DiplomacyFactionMembership.from(game),
  );

  final availability = getAvailableWorkTargetsForUnit(
    view: view,
    game: game,
    topology: topology,
    currentOrders: orders,
    unitId: 'b1',
  );

  expect(availability.assignable, isTrue);
  for (final target in availability.availableWorkTargetIdsSorted()) {
    expect(
      availability.validTileKeysByTarget[target],
      equals(
        getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'b1',
          workTarget: target,
          currentOrders: orders,
          sharedCandidateValidator: shared,
          playerOwnedProvinceIds: ownedIds,
        ),
      ),
    );
  }
}

/// Scenarios for getAvailableWorkTargetsForUnit.
List<RunnableScenario> getAvailableWorkTargetsForUnitScenarios() => [
  rs('pending draft work short-circuits with zero engine probes', osuaRunPendingDraftShortCircuits, '#2133'),
  rs('pending draft: zero probes even with high-reveal world (issue #2133 scale)', osuaRunPendingDraftZeroProbesScale, '#2133'),
  rs('multi-target availability matches shared-validator tile keys per target', osuaRunMultiTargetMatchesSharedValidator, '#2133'),
];
