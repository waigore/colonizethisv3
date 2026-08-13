import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../projections/order_projections.dart';
import 'turn_order_acceptance.dart';
import 'turn_resolution_result.dart';
import 'turn_resolver.dart';

/// Resolves turn using OrderEngine output. Merges human + AI orders (AI optional).
/// SPEC/program/order-engine.md: merge at turn resolution.
/// Returns [TurnResolutionResult]; may be [TurnResolutionPendingOvertures] when a
/// human must accept/reject an overture.
TurnResolutionResult resolveTurnForGameFromOrderEngine({
  required Game game,
  required MapTopology topology,
  required OrderEngine orderEngine,
  Orders? aiOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  TurnEventSink? eventSink,
  void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase,
  TurnTraceRuntime? turnTraceRuntime,
}) {
  final merged = mergeOrderLists(
    humanOrders: orderEngine.orders,
    aiOrders: aiOrders,
  );
  return validateOrdersAndResolveTurn(
    game: game,
    topology: topology,
    orders: merged,
    eventSink: eventSink,
    tileMapByRegion: tileMapByRegion,
    topologyByRegion: topologyByRegion,
    extractedByPlayerId: extractedByPlayerId,
    defaultAssignments: defaultAssignments,
    defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
    onTurnTracePhase: onTurnTracePhase,
    turnTraceRuntime: turnTraceRuntime,
  );
}

/// Validates orders and resolves the turn. Returns [TurnResolutionResult];
/// may be [TurnResolutionPendingOvertures] when a human must accept/reject an overture.
///
/// **Untrusted entry point.** Runs [filterAcceptedOrdersForAllPlayers] over
/// the supplied [orders] before applying so any rejected orders are stripped
/// from each per-player list. Required for callers whose order sources are not
/// pre-validated (scenario runners, ad-hoc test orders, manual JSON-loaded
/// orders, future external/manual sources).
///
/// Use [validateOrdersAndResolveTurnFromTrustedOrders] when every order has
/// already passed OrderEngine validation (human draft) or the order suggestion
/// API guarantee (AI orders). Both entry points return the same resulting
/// [WorldState] for inputs whose orders all pass validation.
///
/// SPEC: `SPEC/program/order-engine.md` § Turn Resolution Integration §
/// Trusted-source resolution.
TurnResolutionResult validateOrdersAndResolveTurn({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  TurnEventSink? eventSink,
  void Function(TurnPhase phase, TurnPhaseProgressMarker marker)?
  onPhaseProgress,
  void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase,
  TurnTraceRuntime? turnTraceRuntime,
}) {
  final engine = OrderEngine(
    initialOrders: orders,
    projector: projectOrderEffects,
  );
  final filtered = filterAcceptedOrdersForAllPlayers(
    engine: engine,
    game: game,
    topology: topology,
    sink: eventSink ?? const TurnEventSink(),
    tileMapByRegion: tileMapByRegion,
  );
  return resolveTurnForGameWithConfig(
    game: game,
    config: TurnResolverConfig(
      topology: topology,
      orders: filtered,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      extractedByPlayerId: extractedByPlayerId,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      eventSink: eventSink ?? const TurnEventSink(),
      onPhaseProgress: onPhaseProgress,
      onTurnTracePhase: onTurnTracePhase,
      turnTraceRuntime: turnTraceRuntime,
    ),
  );
}

/// Resolves the turn using [orders] without running the per-player pre-apply
/// validation pass.
///
/// **Trusted entry point.** Skips [filterAcceptedOrdersForAllPlayers] and
/// dispatches straight to [resolveTurnForGameWithConfig]. Caller contract: every
/// order in [orders] must already have been accepted by either:
///
/// 1. [OrderEngine.addXxxOrderWithContext] (human draft orders), or
/// 2. the order suggestion API guarantee (AI-generated orders) — see
///    `SPEC/program/order-suggestions.md` § Guarantees.
///
/// Use this entry point only when the order sources are auditable as
/// pre-validated. Mixing untrusted orders breaks the contract; for any other
/// source use [validateOrdersAndResolveTurn] instead.
///
/// A separate function name (not a flag on [Orders]) is the chosen mechanism
/// so trust does not propagate silently through copies or future refactors.
///
/// SPEC: `SPEC/program/order-engine.md` § Turn Resolution Integration §
/// Trusted-source resolution.
TurnResolutionResult validateOrdersAndResolveTurnFromTrustedOrders({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  Map<String, Map<CommodityId, int>> extractedByPlayerId = const {},
  List<AssignedRecipe> defaultAssignments = const [],
  Map<String, List<AssignedRecipe>>? defaultAssignmentsByPlayerId,
  TurnEventSink? eventSink,
  void Function(Map<String, Map<String, int>> productionByRecipeByPlayerId)?
  onProductionComplete,
  void Function(TurnPhase phase, TurnPhaseProgressMarker marker)?
  onPhaseProgress,
  void Function(TurnTracePhaseTrace phaseTrace)? onTurnTracePhase,
  TurnTraceRuntime? turnTraceRuntime,
}) {
  return resolveTurnForGameWithConfig(
    game: game,
    config: TurnResolverConfig(
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      extractedByPlayerId: extractedByPlayerId,
      defaultAssignments: defaultAssignments,
      defaultAssignmentsByPlayerId: defaultAssignmentsByPlayerId,
      eventSink: eventSink ?? const TurnEventSink(),
      onProductionComplete: onProductionComplete,
      onPhaseProgress: onPhaseProgress,
      onTurnTracePhase: onTurnTracePhase,
      turnTraceRuntime: turnTraceRuntime,
    ),
  );
}
