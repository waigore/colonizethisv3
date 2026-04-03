import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../economy/economy_production.dart';
import 'order_projections.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import '../constants.dart';
import 'projected_effects.dart';
import 'order_validation_result.dart';
export 'order_validation_result.dart';
import 'validators/move_validator.dart';
import 'validators/army_move_validator.dart';
import 'validators/diplomatic_order_validator.dart';
import 'validators/build_order_validator.dart';
import 'validators/work_order_validator.dart';
import 'validators/naval_order_validator.dart';
import 'unit_type_helpers.dart';

final _log = logicLogger();

/// Order engine: current-turn orders per player, validation, projected effects.
/// SPEC/program/order-engine.md. Does not mutate world state.

/// Order engine: holds per-player orders, validates in submission order,
/// exposes projected effects. No world state mutation.

/// Appends one [OrderValidationResult] per order; short-circuits when [rejected].
/// Returns the new rejected flag (true if any result was rejected).
bool _appendValidationResults<T>(
  List<OrderValidationResult> results,
  List<T> orders,
  bool rejected,
  OrderValidationResult Function(T order, bool previousRejected) validate,
) {
  var r = rejected;
  for (final o in orders) {
    final res = validate(o, r);
    results.add(res);
    if (!res.isAccepted) r = true;
  }
  return r;
}

/// Like [_appendValidationResults] for validators that also return updated state (e.g. treasury).
/// Appends each result to [results], propagates [rejected], and returns (rejected, finalState).
({bool rejected, S state}) _appendValidationResultsWithState<T, S>(
  List<OrderValidationResult> results,
  List<T> orders,
  bool rejected,
  S initialState,
  ({OrderValidationResult result, S state}) Function(
    T order,
    bool previousRejected,
  )
  validate,
) {
  var r = rejected;
  var s = initialState;
  for (final o in orders) {
    final res = validate(o, r);
    results.add(res.result);
    if (!res.result.isAccepted) r = true;
    s = res.state;
  }
  return (rejected: r, state: s);
}

/// Deep-copy of order maps: new map and new list per player. Used by constructor and _copyOrders.
Map<String, List<T>> _copyMapOfOrderLists<T>(Map<String, List<T>> map) =>
    Map.from(map)..updateAll((_, v) => List<T>.from(v));

class _OrderSlot<T> {
  const _OrderSlot({
    required this.getter,
    required this.updater,
    required this.label,
  });

  final Map<String, List<T>> Function(Orders) getter;
  final Orders Function(Orders, Map<String, List<T>>) updater;
  final String label;
}

class OrderEngine {
  OrderEngine({Orders initialOrders = const Orders()})
    : _orders = Orders(
        moveOrdersByPlayerId: _copyMapOfOrderLists(
          initialOrders.moveOrdersByPlayerId,
        ),
        armyMoveOrdersByPlayerId: _copyMapOfOrderLists(
          initialOrders.armyMoveOrdersByPlayerId,
        ),
        buildUnitOrdersByPlayerId: _copyMapOfOrderLists(
          initialOrders.buildUnitOrdersByPlayerId,
        ),
        workOrdersByPlayerId: _copyMapOfOrderLists(
          initialOrders.workOrdersByPlayerId,
        ),
        diplomaticOrdersByPlayerId: _copyMapOfOrderLists(
          initialOrders.diplomaticOrdersByPlayerId,
        ),
        researchOrdersByPlayerId: _copyMapOfOrderLists(
          initialOrders.researchOrdersByPlayerId,
        ),
        navalMoveOrdersByPlayerId: _copyMapOfOrderLists(
          initialOrders.navalMoveOrdersByPlayerId,
        ),
        navalMissionOrdersByPlayerId: _copyMapOfOrderLists(
          initialOrders.navalMissionOrdersByPlayerId,
        ),
      );

  Orders _orders;

  Orders get orders => _copyOrders(_orders);

  Orders _copyOrders(Orders o) => Orders(
    moveOrdersByPlayerId: _copyMapOfOrderLists(o.moveOrdersByPlayerId),
    armyMoveOrdersByPlayerId:
        _copyMapOfOrderLists(o.armyMoveOrdersByPlayerId),
    buildUnitOrdersByPlayerId: _copyMapOfOrderLists(
      o.buildUnitOrdersByPlayerId,
    ),
    workOrdersByPlayerId: _copyMapOfOrderLists(o.workOrdersByPlayerId),
    diplomaticOrdersByPlayerId: _copyMapOfOrderLists(
      o.diplomaticOrdersByPlayerId,
    ),
    researchOrdersByPlayerId: _copyMapOfOrderLists(o.researchOrdersByPlayerId),
    navalMoveOrdersByPlayerId: _copyMapOfOrderLists(
      o.navalMoveOrdersByPlayerId,
    ),
    navalMissionOrdersByPlayerId: _copyMapOfOrderLists(
      o.navalMissionOrdersByPlayerId,
    ),
  );

  // -- Generic helpers for add/remove --

  void _appendOrder<T>(
    String playerId,
    T order,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
  ) {
    final list = getter(_orders)[playerId] ?? [];
    _orders = updater(_orders, {
      ...getter(_orders),
      playerId: [...list, order],
    });
  }

  OrderValidationResult _addOrderWithContext<T>(
    Game game,
    MapTopology topology,
    String playerId,
    T order,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
    String orderLabel, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    _appendOrder(playerId, order, getter, updater);
    _log.d('validating orders with context player=$playerId');
    final results = validatePlayerOrdersWithContext(
      game,
      topology,
      playerId,
      tileMapByRegion: tileMapByRegion,
    );
    if (results.isEmpty) {
      return OrderValidationResult.accepted();
    }
    final r = results.last;
    if (!r.isAccepted)
      _log.w(
        '$orderLabel order rejected player=$playerId reason=${r.reason}',
      );
    return r;
  }

  void _removeOrderAt<T>(
    String playerId,
    int index,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
  ) {
    final list = List<T>.from(getter(_orders)[playerId] ?? []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      _orders = updater(_orders, {...getter(_orders), playerId: list});
    }
  }

  // -- Field accessors for Orders --

  static Map<String, List<MoveOrder>> _moveOrders(Orders o) =>
      o.moveOrdersByPlayerId;
  static Orders _withMoveOrders(Orders o, Map<String, List<MoveOrder>> m) =>
      o.copyWith(moveOrdersByPlayerId: m);

  static Map<String, List<ArmyMoveOrder>> _armyMoveOrders(Orders o) =>
      o.armyMoveOrdersByPlayerId;
  static Orders _withArmyMoveOrders(
    Orders o,
    Map<String, List<ArmyMoveOrder>> m,
  ) =>
      o.copyWith(armyMoveOrdersByPlayerId: m);

  static Map<String, List<BuildUnitOrder>> _buildOrders(Orders o) =>
      o.buildUnitOrdersByPlayerId;
  static Orders _withBuildOrders(
    Orders o,
    Map<String, List<BuildUnitOrder>> m,
  ) => o.copyWith(buildUnitOrdersByPlayerId: m);

  static Map<String, List<WorkOrder>> _workOrders(Orders o) =>
      o.workOrdersByPlayerId;
  static Orders _withWorkOrders(Orders o, Map<String, List<WorkOrder>> m) =>
      o.copyWith(workOrdersByPlayerId: m);

  static Map<String, List<DiplomaticOrder>> _diplomaticOrders(Orders o) =>
      o.diplomaticOrdersByPlayerId;
  static Orders _withDiplomaticOrders(
    Orders o,
    Map<String, List<DiplomaticOrder>> m,
  ) => o.copyWith(diplomaticOrdersByPlayerId: m);

  static Map<String, List<NavalMoveOrder>> _navalMoveOrders(Orders o) =>
      o.navalMoveOrdersByPlayerId;
  static Orders _withNavalMoveOrders(
    Orders o,
    Map<String, List<NavalMoveOrder>> m,
  ) => o.copyWith(navalMoveOrdersByPlayerId: m);

  static Map<String, List<NavalMissionOrder>> _navalMissionOrders(Orders o) =>
      o.navalMissionOrdersByPlayerId;
  static Orders _withNavalMissionOrders(
    Orders o,
    Map<String, List<NavalMissionOrder>> m,
  ) => o.copyWith(navalMissionOrdersByPlayerId: m);

  // -- Public add/remove methods --

  static const _OrderSlot<MoveOrder> _moveSlot = _OrderSlot<MoveOrder>(
    getter: _moveOrders,
    updater: _withMoveOrders,
    label: 'move',
  );

  static const _OrderSlot<ArmyMoveOrder> _armyMoveSlot =
      _OrderSlot<ArmyMoveOrder>(
    getter: _armyMoveOrders,
    updater: _withArmyMoveOrders,
    label: 'army move',
  );

  static const _OrderSlot<BuildUnitOrder> _buildSlot =
      _OrderSlot<BuildUnitOrder>(
        getter: _buildOrders,
        updater: _withBuildOrders,
        label: 'build',
      );

  static const _OrderSlot<WorkOrder> _workSlot = _OrderSlot<WorkOrder>(
    getter: _workOrders,
    updater: _withWorkOrders,
    label: 'work',
  );

  static const _OrderSlot<DiplomaticOrder> _diplomaticSlot =
      _OrderSlot<DiplomaticOrder>(
        getter: _diplomaticOrders,
        updater: _withDiplomaticOrders,
        label: 'diplomatic',
      );

  static const _OrderSlot<NavalMoveOrder> _navalMoveSlot =
      _OrderSlot<NavalMoveOrder>(
        getter: _navalMoveOrders,
        updater: _withNavalMoveOrders,
        label: 'naval move',
      );

  static const _OrderSlot<NavalMissionOrder> _navalMissionSlot =
      _OrderSlot<NavalMissionOrder>(
        getter: _navalMissionOrders,
        updater: _withNavalMissionOrders,
        label: 'naval mission',
      );

  OrderValidationResult _addOrder<T>(
    String playerId,
    T order,
    _OrderSlot<T> slot,
  ) {
    _appendOrder(playerId, order, slot.getter, slot.updater);
    return OrderValidationResult.accepted();
  }

  OrderValidationResult _addOrderWithContextSlot<T>(
    Game game,
    MapTopology topology,
    String playerId,
    T order,
    _OrderSlot<T> slot, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    return _addOrderWithContext(
      game,
      topology,
      playerId,
      order,
      slot.getter,
      slot.updater,
      slot.label,
      tileMapByRegion: tileMapByRegion,
    );
  }

  void _removeOrderAtSlot<T>(String playerId, int index, _OrderSlot<T> slot) {
    _removeOrderAt(playerId, index, slot.getter, slot.updater);
  }

  OrderValidationResult addMoveOrder(String playerId, MoveOrder order) =>
      _addOrder(playerId, order, _moveSlot);

  OrderValidationResult addArmyMoveOrder(String playerId, ArmyMoveOrder order) =>
      _addOrder(playerId, order, _armyMoveSlot);

  OrderValidationResult addMoveOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    MoveOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _moveSlot,
        tileMapByRegion: tileMapByRegion,
      );

  OrderValidationResult addArmyMoveOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    ArmyMoveOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _armyMoveSlot,
        tileMapByRegion: tileMapByRegion,
      );

  OrderValidationResult addBuildOrder(String playerId, BuildUnitOrder order) =>
      _addOrder(playerId, order, _buildSlot);

  OrderValidationResult addBuildOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    BuildUnitOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _buildSlot,
        tileMapByRegion: tileMapByRegion,
      );

  OrderValidationResult addWorkOrder(String playerId, WorkOrder order) =>
      _addOrder(playerId, order, _workSlot);

  OrderValidationResult addWorkOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    WorkOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _workSlot,
        tileMapByRegion: tileMapByRegion,
      );

  OrderValidationResult addDiplomaticOrder(
    String playerId,
    DiplomaticOrder order,
  ) => _addOrder(playerId, order, _diplomaticSlot);

  OrderValidationResult addDiplomaticOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    DiplomaticOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _diplomaticSlot,
        tileMapByRegion: tileMapByRegion,
      );

  OrderValidationResult addNavalMoveOrder(
    String playerId,
    NavalMoveOrder order,
  ) => _addOrder(playerId, order, _navalMoveSlot);

  OrderValidationResult addNavalMoveOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    NavalMoveOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _navalMoveSlot,
        tileMapByRegion: tileMapByRegion,
      );

  OrderValidationResult addNavalMissionOrder(
    String playerId,
    NavalMissionOrder order,
  ) => _addOrder(playerId, order, _navalMissionSlot);

  OrderValidationResult addNavalMissionOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    NavalMissionOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _navalMissionSlot,
        tileMapByRegion: tileMapByRegion,
      );

  void removeMoveOrder(String playerId, int index) =>
      _removeOrderAtSlot(playerId, index, _moveSlot);

  void removeArmyMoveOrder(String playerId, int index) =>
      _removeOrderAtSlot(playerId, index, _armyMoveSlot);

  void removeBuildOrder(String playerId, int index) =>
      _removeOrderAtSlot(playerId, index, _buildSlot);

  void removeWorkOrder(String playerId, int index) =>
      _removeOrderAtSlot(playerId, index, _workSlot);

  /// Validates with full context. Call this when Game and topology available.
  List<OrderValidationResult> validatePlayerOrdersWithContext(
    Game game,
    MapTopology topology,
    String playerId, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final results = <OrderValidationResult>[];
    final player = game.playerById(playerId);
    if (player == null) return results;

    final view = buildPlayerView(game, topology, playerId);

    final moves = _orders.moveOrdersByPlayerId[playerId] ?? [];
    final armyMoves = _orders.armyMoveOrdersByPlayerId[playerId] ?? [];
    final builds = _orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final works = _orders.workOrdersByPlayerId[playerId] ?? [];
    final diplomatic = _orders.diplomaticOrdersByPlayerId[playerId] ?? [];
    final navals = _orders.navalMoveOrdersByPlayerId[playerId] ?? [];
    final missions = _orders.navalMissionOrdersByPlayerId[playerId] ?? [];
    var rejected = false;

    final unitsById = Map<String, Unit>.from(
      unitsByIdFromWorld(game.worldState),
    );

    final devExclusiveTiles = devExclusiveTilesFromWorld(
      game.worldState,
      playerId,
    );

    const _moveValidator = MoveValidator();
    const _armyMoveValidator = ArmyMoveValidator();

    OrderValidationResult validateMove(MoveOrder o) {
      return _moveValidator.validate(
        o,
        game,
        playerId,
        unitsById,
        diplomatic,
        view,
        topology,
      );
    }

    OrderValidationResult validateArmyMove(ArmyMoveOrder o) {
      return _armyMoveValidator.validate(
        o,
        game,
        playerId,
        diplomatic,
        view,
        topology,
      );
    }

    rejected = _appendValidationResults(
      results,
      moves,
      rejected,
      (o, prev) => prev ? previousInvalidOrderResult : validateMove(o),
    );

    rejected = _appendValidationResults(
      results,
      armyMoves,
      rejected,
      (o, prev) => prev ? previousInvalidOrderResult : validateArmyMove(o),
    );

    var stockpile = player.stockpile;
    var treasury = player.treasury;

    final buildValidator = BuildOrderValidator(game: game, player: player);
    rejected = _appendValidationResults(
      results,
      builds,
      rejected,
      (o, prev) => buildValidator.validate(o, previousRejected: prev),
    );
    stockpile = buildValidator.stockpile;
    treasury = buildValidator.treasury;

    final workValidator = WorkOrderValidator(
      game: game,
      player: player,
      playerId: playerId,
      view: view,
      unitsById: unitsById,
      devExclusiveTiles: devExclusiveTiles,
      stockpile: stockpile,
      treasury: treasury,
      tileMapByRegion: tileMapByRegion,
    );
    rejected = _appendValidationResults(
      results,
      works,
      rejected,
      (o, prev) => workValidator.validate(o, previousRejected: prev),
    );
    stockpile = workValidator.stockpile;
    treasury = workValidator.treasury;

    final diplomaticValidator = DiplomaticOrderValidator(
      game: game,
      playerId: playerId,
      initialTreasury: treasury,
    );
    final afterDiplomatic =
        _appendValidationResultsWithState<DiplomaticOrder, int>(
          results,
          diplomatic,
          rejected,
          treasury,
          (o, prev) {
            final r = diplomaticValidator.validate(o, previousRejected: prev);
            return (result: r.result, state: r.treasury);
          },
        );
    rejected = afterDiplomatic.rejected;
    treasury = afterDiplomatic.state;

    final navalValidator = NavalOrderValidator(
      game: game,
      topology: topology,
      playerId: playerId,
    );
    rejected = _appendValidationResults(
      results,
      navals,
      rejected,
      (o, prev) => navalValidator.validateNavalMove(o, previousRejected: prev),
    );
    rejected = _appendValidationResults(
      results,
      missions,
      rejected,
      (o, prev) =>
          navalValidator.validateNavalMission(o, previousRejected: prev),
    );
    return results;
  }

  /// Dry-run: apply orders via resolver (no mutation of [game]); return projected effects.
  /// Uses [projectOrderEffects] for worker count, treasury delta, unit locations, stockpile deltas.
  /// When [tileMapByRegion] is null or omitted, an empty map is used and projected extraction is zero
  /// (caller may pass tile maps when available so expected extraction is non-zero).
  ProjectedEffects projectedEffects(
    Game game,
    MapTopology topology,
    String playerId, {
    List<AssignedRecipe> defaultAssignments = const [],
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final orders = _copyOrders(_orders);
    final tileMaps = tileMapByRegion ?? <String, TileMapResult>{};
    if (tileMaps.isEmpty) {
      _log.d(
        'projectedEffects called with no tileMapByRegion; expected extraction will be zero',
      );
    }
    return projectOrderEffects(
      game: game,
      orders: orders,
      topology: topology,
      tileMapByRegion: tileMaps,
      playerId: playerId,
      defaultAssignments: defaultAssignments,
    );
  }
}
