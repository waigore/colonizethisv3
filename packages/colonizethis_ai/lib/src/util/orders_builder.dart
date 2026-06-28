import 'package:colonizethis_models/colonizethis_models.dart';

/// Mutable accumulator for [Orders].
///
/// Domain planning historically grew an [Orders] value through chained
/// `copyWith` / `appendXxxOrders` calls, each allocating a fresh immutable
/// [Orders] plus a per-family map spread copy. [OrdersBuilder] collects orders
/// per family in mutable `Map<String, List<T>>` structures, appends in place,
/// and materialises a single immutable [Orders] once via [build]. This removes
/// the intermediate shallow copies on the AI planning hot path while preserving
/// the exact append order (and therefore byte-for-byte [Orders] equality) of
/// the previous immutable flow. Refs #3288 (15 000 ms turn-resolution budget).
///
/// The builder is single-pass: append, then [build]. [build] caches its result
/// so repeated reads between mutations are free; any append invalidates the
/// cache. Built [Orders] own copies of the per-family lists, so further appends
/// never mutate a previously built snapshot.
class OrdersBuilder {
  /// Seeds the accumulator with a copy of every family in [orders] so the
  /// source value is never mutated.
  OrdersBuilder.from(Orders orders)
    : _move = _clone(orders.moveOrdersByPlayerId),
      _armyMove = _clone(orders.armyMoveOrdersByPlayerId),
      _build = _clone(orders.buildUnitOrdersByPlayerId),
      _work = _clone(orders.workOrdersByPlayerId),
      _recruitWorker = _clone(orders.recruitWorkerOrdersByPlayerId),
      _diplomatic = _clone(orders.diplomaticOrdersByPlayerId),
      _research = _clone(orders.researchOrdersByPlayerId),
      _navalMove = _clone(orders.navalMoveOrdersByPlayerId),
      _navalMission = _clone(orders.navalMissionOrdersByPlayerId),
      _trade = _clone(orders.tradeOrdersByPlayerId);

  final Map<String, List<MoveOrder>> _move;
  final Map<String, List<ArmyMoveOrder>> _armyMove;
  final Map<String, List<BuildUnitOrder>> _build;
  final Map<String, List<WorkOrder>> _work;
  final Map<String, List<RecruitWorkerOrder>> _recruitWorker;
  final Map<String, List<DiplomaticOrder>> _diplomatic;
  final Map<String, List<ResearchOrder>> _research;
  final Map<String, List<NavalMoveOrder>> _navalMove;
  final Map<String, List<NavalMissionOrder>> _navalMission;
  final Map<String, List<TradeOrder>> _trade;

  Orders? _cached;

  void appendMoveOrders(String playerId, List<MoveOrder> orders) =>
      _append(_move, playerId, orders);

  void appendBuildOrders(String playerId, List<BuildUnitOrder> orders) =>
      _append(_build, playerId, orders);

  void appendWorkOrders(String playerId, List<WorkOrder> orders) =>
      _append(_work, playerId, orders);

  void appendRecruitWorkerOrders(
    String playerId,
    List<RecruitWorkerOrder> orders,
  ) => _append(_recruitWorker, playerId, orders);

  void appendResearchOrders(String playerId, List<ResearchOrder> orders) =>
      _append(_research, playerId, orders);

  void appendNavalMoveOrders(String playerId, List<NavalMoveOrder> orders) =>
      _append(_navalMove, playerId, orders);

  void appendNavalMissionOrders(
    String playerId,
    List<NavalMissionOrder> orders,
  ) => _append(_navalMission, playerId, orders);

  void appendDiplomaticOrders(String playerId, List<DiplomaticOrder> orders) =>
      _append(_diplomatic, playerId, orders);

  void appendTradeOrders(String playerId, List<TradeOrder> orders) =>
      _append(_trade, playerId, orders);

  /// Materialises the accumulated families into an immutable [Orders].
  ///
  /// Cached until the next append so callers may read intermediate state
  /// without re-copying. Built lists are independent copies of the builder's
  /// internal lists, so subsequent appends never mutate a returned [Orders].
  Orders build() => _cached ??= Orders(
    moveOrdersByPlayerId: _freeze(_move),
    armyMoveOrdersByPlayerId: _freeze(_armyMove),
    buildUnitOrdersByPlayerId: _freeze(_build),
    workOrdersByPlayerId: _freeze(_work),
    recruitWorkerOrdersByPlayerId: _freeze(_recruitWorker),
    diplomaticOrdersByPlayerId: _freeze(_diplomatic),
    researchOrdersByPlayerId: _freeze(_research),
    navalMoveOrdersByPlayerId: _freeze(_navalMove),
    navalMissionOrdersByPlayerId: _freeze(_navalMission),
    tradeOrdersByPlayerId: _freeze(_trade),
  );

  void _append<T>(Map<String, List<T>> family, String playerId, List<T> list) {
    if (list.isEmpty) return;
    (family[playerId] ??= <T>[]).addAll(list);
    _cached = null;
  }

  static Map<String, List<T>> _clone<T>(Map<String, List<T>> source) {
    if (source.isEmpty) return <String, List<T>>{};
    final out = <String, List<T>>{};
    source.forEach((playerId, list) => out[playerId] = List<T>.of(list));
    return out;
  }

  static Map<String, List<T>> _freeze<T>(Map<String, List<T>> source) {
    if (source.isEmpty) return <String, List<T>>{};
    final out = <String, List<T>>{};
    source.forEach((playerId, list) => out[playerId] = List<T>.of(list));
    return out;
  }
}
