import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'draft_orders_mutations.dart';
import 'incremental_candidate_validator.dart';
import 'order_engine.dart';
import 'order_validators.dart';
import 'unit_type_helpers.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';

final orderSuggestionLog = packageLogger('order_suggestion');

bool _orderSuggestionTrackWorkOrderAcceptanceProbes = false;
int _orderSuggestionWorkOrderAcceptanceProbeCount = 0;

/// Test hook: enable counting of order-engine work-order acceptance probes.
void setOrderSuggestionWorkOrderAcceptanceProbeTrackingForTests(bool enabled) {
  _orderSuggestionTrackWorkOrderAcceptanceProbes = enabled;
  _orderSuggestionWorkOrderAcceptanceProbeCount = 0;
}

/// Test hook: probes counted while tracking is enabled (Refs #2133).
int get orderSuggestionWorkOrderAcceptanceProbeCountForTests =>
    _orderSuggestionWorkOrderAcceptanceProbeCount;

void bumpOrderSuggestionWorkOrderAcceptanceProbeIfTracking() {
  if (_orderSuggestionTrackWorkOrderAcceptanceProbes) {
    _orderSuggestionWorkOrderAcceptanceProbeCount++;
  }
}

bool _hasNoPlayerOrders(Orders orders, String playerId) =>
    (orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[]).isEmpty &&
    (orders.armyMoveOrdersByPlayerId[playerId] ?? const <ArmyMoveOrder>[])
        .isEmpty &&
    (orders.buildUnitOrdersByPlayerId[playerId] ?? const <BuildUnitOrder>[])
        .isEmpty &&
    (orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[]).isEmpty &&
    (orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[])
        .isEmpty &&
    (orders.navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[])
        .isEmpty &&
    (orders.navalMissionOrdersByPlayerId[playerId] ??
            const <NavalMissionOrder>[])
        .isEmpty;

bool isMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  MoveOrder candidate,
) {
  // Stateless candidate-probe path: validate the candidate against an
  // already-accepted [baseOrders] without re-running full-pass
  // [validatePlayerOrdersWithContext]. SPEC/program/order-suggestions.md
  // § Incremental candidate validation; SPEC/program/order-engine.md
  // § Validation (candidate-probe context). Refs #2237.
  final validator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: baseOrders,
  );
  return validator.isMoveAccepted(candidate);
}

bool isArmyMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  ArmyMoveOrder candidate,
) {
  // Stateless candidate-probe path: validate the candidate against
  // [baseOrders]'s diplomatic context without re-running full-pass
  // [validatePlayerOrdersWithContext]. SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  final validator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: baseOrders,
  );
  return validator.isArmyMoveAccepted(candidate);
}

bool isWorkOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  WorkOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  bumpOrderSuggestionWorkOrderAcceptanceProbeIfTracking();
  if (_hasNoPlayerOrders(baseOrders, playerId)) {
    final player = game.playerById(playerId);
    if (player == null) return false;
    final view = buildPlayerView(game, topology, playerId);
    final unitsById = Map<String, Unit>.from(
      unitsByIdFromWorld(game.worldState),
    );
    final validator = WorkOrderValidator(
      context: WorkOrderValidationContext(
        game: game,
        player: player,
        playerId: playerId,
        view: view,
        unitsById: unitsById,
        devExclusiveTiles: devExclusiveTilesFromWorld(
          game.worldState,
          playerId,
        ),
        tileMapByRegion: tileMapByRegion,
        civilianDraftMoveUnitIds: const <String>{},
        diplomaticOrders: const <DiplomaticOrder>[],
        topology: topology,
      ),
      stockpile: player.stockpile,
      treasury: player.treasury,
    );
    final result = validator.validate(candidate, previousRejected: false);
    return result.isAccepted;
  }
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addWorkOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
    tileMapByRegion: tileMapByRegion,
  );
  return result.isAccepted;
}

bool isBuildOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  BuildUnitOrder candidate,
) {
  if (_hasNoPlayerOrders(baseOrders, playerId)) {
    final player = game.playerById(playerId);
    if (player == null) return false;
    final result = BuildOrderValidator(
      game: game,
      player: player,
    ).validate(candidate, previousRejected: false);
    return result.isAccepted;
  }
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addBuildOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
  );
  return result.isAccepted;
}

bool isNavalMoveOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  NavalMoveOrder candidate,
) {
  // Stateless candidate-probe path. SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  final validator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: baseOrders,
  );
  return validator.isNavalMoveAccepted(candidate);
}

bool isNavalMissionOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  NavalMissionOrder candidate,
) {
  // Stateless candidate-probe path. SPEC/program/order-suggestions.md
  // § Incremental candidate validation. Refs #2237.
  final validator = IncrementalCandidateValidator.forPlayer(
    game: game,
    topology: topology,
    playerId: playerId,
    basePrefix: baseOrders,
  );
  return validator.isNavalMissionAccepted(candidate);
}

bool isDiplomaticOrderAccepted(
  Game game,
  MapTopology topology,
  String playerId,
  Orders baseOrders,
  DiplomaticOrder candidate, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (_hasNoPlayerOrders(baseOrders, playerId)) {
    final player = game.playerById(playerId);
    if (player == null) return false;
    final validator = DiplomaticOrderValidator(
      game: game,
      playerId: playerId,
      initialTreasury: player.treasury,
    );
    final result = validator.validate(candidate, previousRejected: false);
    return result.result.isAccepted;
  }
  final engine = OrderEngine(initialOrders: baseOrders);
  final result = engine.addDiplomaticOrderWithContext(
    game,
    topology,
    playerId,
    candidate,
    tileMapByRegion: tileMapByRegion,
  );
  return result.isAccepted;
}

Orders appendDiplomaticOrderForTrial(
  Orders orders,
  String playerId,
  DiplomaticOrder order,
) {
  final prev =
      orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
  return orders.copyWith(
    diplomaticOrdersByPlayerId: {
      ...orders.diplomaticOrdersByPlayerId,
      playerId: [...prev, order],
    },
  );
}

OvertureStage? nextOvertureStage(OvertureStage current) {
  switch (current) {
    case OvertureStage.none:
      return OvertureStage.tradeConsulate;
    case OvertureStage.tradeConsulate:
      return OvertureStage.embassy;
    case OvertureStage.embassy:
      return OvertureStage.nap;
    case OvertureStage.nap:
      return OvertureStage.joinEmpire;
    case OvertureStage.joinEmpire:
      return null;
  }
}
