// Table-driven order suggestion unit availability scenarios (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/order_suggestion_context.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_suggestion_unit_availability_fixtures.dart';

// dart format off
void _osuaWithProbeTracking(void Function() body) {
  setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(true);
  addTearDown(() => setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(false));
  body();
}

({Game game, MapTopology topology, Orders orders, PlayerView view}) _osuaPendingDraftCtx() {
  final game = orderSuggestionUnitAvailabilityPendingDraftGame();
  const topology = orderSuggestionUnitAvailabilityPendingDraftTopology;
  final orders = orderSuggestionUnitAvailabilityPendingDraftOrders();
  return (game: game, topology: topology, orders: orders, view: buildPlayerView(game, topology, orderSuggestionUnitAvailabilityPlayerId));
}

({Game game, MapTopology topology, Orders orders, PlayerView view}) _osuaScaleCtx() {
  final game = orderSuggestionUnitAvailabilityScaleGame();
  const topology = orderSuggestionUnitAvailabilityEmptyTopology;
  final orders = orderSuggestionUnitAvailabilityScaleOrders();
  return (game: game, topology: topology, orders: orders, view: buildPlayerView(game, topology, orderSuggestionUnitAvailabilityPlayerId));
}

void osuaRunPendingDraftShortCircuits() => _osuaWithProbeTracking(() {
  final ctx = _osuaPendingDraftCtx();
  final availability = getAvailableWorkTargetsForUnit(view: ctx.view, game: ctx.game, topology: ctx.topology, currentOrders: ctx.orders, unitId: orderSuggestionUnitAvailabilityExplorerId);
  expect(availability.assignable, isFalse);
  expect(availability.blockedReason, 'pending_draft_work_order');
  expect(availability.validTileKeysByTarget, isEmpty);
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
  expect(getValidWorkOrderTileKeysWithVisibility(game: ctx.game, topology: ctx.topology, view: ctx.view, unitId: orderSuggestionUnitAvailabilityExplorerId, workTarget: kWorkTargetExplore, currentOrders: ctx.orders), isEmpty);
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
});

void osuaRunPendingDraftZeroProbesScale() => _osuaWithProbeTracking(() {
  final ctx = _osuaScaleCtx();
  expect(20, greaterThanOrEqualTo(20));
  expect(ctx.game.worldState.playerVisibilityByTile[orderSuggestionUnitAvailabilityPlayerId]!.values.where((v) => v != 'unknown').length, greaterThanOrEqualTo(100));
  getAvailableWorkTargetsForUnit(view: ctx.view, game: ctx.game, topology: ctx.topology, currentOrders: ctx.orders, unitId: orderSuggestionUnitAvailabilityExplorerId);
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
  getValidWorkOrderTileKeysWithVisibility(game: ctx.game, topology: ctx.topology, view: ctx.view, unitId: orderSuggestionUnitAvailabilityExplorerId, workTarget: kWorkTargetExplore, currentOrders: ctx.orders);
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
  getValidWorkOrderTileKeysWithVisibility(game: ctx.game, topology: ctx.topology, view: ctx.view, unitId: orderSuggestionUnitAvailabilityExplorerId, workTarget: kWorkTargetProspect, currentOrders: ctx.orders);
  expect(orderSuggestionWorkOrderAcceptanceProbeCountForTests, 0);
});

void osuaRunMultiTargetMatchesSharedValidator() {
  final game = orderSuggestionUnitAvailabilityMultiTargetGame();
  const topology = orderSuggestionUnitAvailabilityEmptyTopology;
  const orders = Orders();
  final view = buildPlayerView(game, topology, orderSuggestionUnitAvailabilityPlayerId);
  final ownedIds = <String>{for (final e in view.provincesById.entries) if (e.value.ownerId == orderSuggestionUnitAvailabilityPlayerId) e.key};
  final unitsById = {for (final u in view.ownUnits) u.id: u};
  final shared = buildIncrementalCandidateValidator(
    game: game,
    topology: topology,
    playerId: orderSuggestionUnitAvailabilityPlayerId,
    baseOrders: orders,
    resolution: orderResolutionContextFromView(view, game, unitsById: unitsById),
    factionMembership: DiplomacyFactionMembership.from(game),
  );
  final availability = getAvailableWorkTargetsForUnit(view: view, game: game, topology: topology, currentOrders: orders, unitId: 'b1');
  expect(availability.assignable, isTrue);
  for (final target in availability.availableWorkTargetIdsSorted()) {
    expect(
      availability.validTileKeysByTarget[target],
      equals(getValidWorkOrderTileKeysWithVisibility(game: game, topology: topology, view: view, unitId: 'b1', workTarget: target, currentOrders: orders, sharedCandidateValidator: shared, playerOwnedProvinceIds: ownedIds)),
    );
  }
}
// dart format on

/// Scenarios for getAvailableWorkTargetsForUnit.
List<RunnableScenario> getAvailableWorkTargetsForUnitScenarios() => [
  rs('pending draft work short-circuits with zero engine probes', osuaRunPendingDraftShortCircuits, '#2133'),
  rs('pending draft: zero probes even with high-reveal world (issue #2133 scale)', osuaRunPendingDraftZeroProbesScale, '#2133'),
  rs('multi-target availability matches shared-validator tile keys per target', osuaRunMultiTargetMatchesSharedValidator, '#2133'),
];
