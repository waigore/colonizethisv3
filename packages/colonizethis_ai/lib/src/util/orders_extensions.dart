import 'package:colonizethis_models/colonizethis_models.dart';

typedef _OrdersByPlayer<T> = Map<String, List<T>>;

_OrdersByPlayer<T> _appendOrdersByPlayer<T>(
  _OrdersByPlayer<T> source,
  String playerId,
  List<T> list,
) {
  final existing = source[playerId] ?? const [];
  return {
    ...source,
    playerId: [...existing, ...list],
  };
}

/// Mutable accumulator for one AI player turn's order families (Refs #3288).
///
/// The spread-copy [OrdersAppendExtension] helpers each allocate a fresh
/// immutable [Orders] (`copyWith` over ten family maps) on every append. When
/// a planner appends several families in sequence (for example the economy
/// domain-planner slice: civilian work, peasant recruit, then build) that is
/// one full [Orders] allocation per append. [OrdersBuilder] instead mutates a
/// per-family overlay in place and materialises a single [Orders] once via
/// [build], eliminating the intermediate copies while preserving the exact
/// append-order semantics: for each touched family, `build()` yields the same
/// map the equivalent chain of `appendXxxOrders` calls would have produced
/// (base entries preserved, the accumulating player's list = existing ++ the
/// appended lists in call order). Untouched families keep the seed [Orders]
/// maps unchanged, so `OrdersBuilder(base).build()` equals `base` for the
/// `MapEquality`-style comparisons the planners rely on.
///
/// This is an internal allocation optimisation only — it changes no emitted
/// orders. See `SPEC/program/turn-resolution.md` (wall-clock budget) and
/// `.cursor/rules/colonizethis-turn-resolution-budget.mdc`.
class OrdersBuilder {
  /// Seeds the builder from [base] (defaults to an empty [Orders]). The seed
  /// maps are never mutated; [build] copies a family map lazily only when that
  /// family is appended to.
  OrdersBuilder([Orders base = const Orders()]) : _base = base;

  final Orders _base;

  Map<String, List<MoveOrder>>? _move;
  Map<String, List<ArmyMoveOrder>>? _armyMove;
  Map<String, List<BuildUnitOrder>>? _build;
  Map<String, List<WorkOrder>>? _work;
  Map<String, List<RecruitWorkerOrder>>? _recruit;
  Map<String, List<DiplomaticOrder>>? _diplomatic;
  Map<String, List<ResearchOrder>>? _research;
  Map<String, List<NavalMoveOrder>>? _navalMove;
  Map<String, List<NavalMissionOrder>>? _navalMission;
  Map<String, List<TradeOrder>>? _trade;

  static Map<String, List<T>> _mutableAppend<T>(
    Map<String, List<T>> overlay,
    String playerId,
    List<T> list,
  ) {
    overlay[playerId] = [...(overlay[playerId] ?? const []), ...list];
    return overlay;
  }

  void addMoveOrders(String playerId, List<MoveOrder> list) {
    _move = _mutableAppend(
      _move ??= {..._base.moveOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addArmyMoveOrders(String playerId, List<ArmyMoveOrder> list) {
    _armyMove = _mutableAppend(
      _armyMove ??= {..._base.armyMoveOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addBuildOrders(String playerId, List<BuildUnitOrder> list) {
    _build = _mutableAppend(
      _build ??= {..._base.buildUnitOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addWorkOrders(String playerId, List<WorkOrder> list) {
    _work = _mutableAppend(
      _work ??= {..._base.workOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addRecruitWorkerOrders(String playerId, List<RecruitWorkerOrder> list) {
    _recruit = _mutableAppend(
      _recruit ??= {..._base.recruitWorkerOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addDiplomaticOrders(String playerId, List<DiplomaticOrder> list) {
    _diplomatic = _mutableAppend(
      _diplomatic ??= {..._base.diplomaticOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addResearchOrders(String playerId, List<ResearchOrder> list) {
    _research = _mutableAppend(
      _research ??= {..._base.researchOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addNavalMoveOrders(String playerId, List<NavalMoveOrder> list) {
    _navalMove = _mutableAppend(
      _navalMove ??= {..._base.navalMoveOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addNavalMissionOrders(String playerId, List<NavalMissionOrder> list) {
    _navalMission = _mutableAppend(
      _navalMission ??= {..._base.navalMissionOrdersByPlayerId},
      playerId,
      list,
    );
  }

  void addTradeOrders(String playerId, List<TradeOrder> list) {
    _trade = _mutableAppend(
      _trade ??= {..._base.tradeOrdersByPlayerId},
      playerId,
      list,
    );
  }

  /// Materialises the accumulated orders into a single immutable [Orders].
  ///
  /// Families never appended to fall through to the seed maps (via the
  /// `null`-keeps-existing semantics of [Orders.copyWith]).
  Orders build() => _base.copyWith(
    moveOrdersByPlayerId: _move,
    armyMoveOrdersByPlayerId: _armyMove,
    buildUnitOrdersByPlayerId: _build,
    workOrdersByPlayerId: _work,
    recruitWorkerOrdersByPlayerId: _recruit,
    diplomaticOrdersByPlayerId: _diplomatic,
    researchOrdersByPlayerId: _research,
    navalMoveOrdersByPlayerId: _navalMove,
    navalMissionOrdersByPlayerId: _navalMission,
    tradeOrdersByPlayerId: _trade,
  );
}

extension OrdersAppendExtension on Orders {
  Orders appendMoveOrders(String playerId, List<MoveOrder> list) => copyWith(
    moveOrdersByPlayerId: _appendOrdersByPlayer(
      moveOrdersByPlayerId,
      playerId,
      list,
    ),
  );

  Orders appendBuildOrders(String playerId, List<BuildUnitOrder> list) =>
      copyWith(
        buildUnitOrdersByPlayerId: _appendOrdersByPlayer(
          buildUnitOrdersByPlayerId,
          playerId,
          list,
        ),
      );

  Orders appendWorkOrders(String playerId, List<WorkOrder> list) => copyWith(
    workOrdersByPlayerId: _appendOrdersByPlayer(
      workOrdersByPlayerId,
      playerId,
      list,
    ),
  );

  Orders appendResearchOrders(String playerId, List<ResearchOrder> list) =>
      copyWith(
        researchOrdersByPlayerId: _appendOrdersByPlayer(
          researchOrdersByPlayerId,
          playerId,
          list,
        ),
      );

  Orders appendNavalMoveOrders(String playerId, List<NavalMoveOrder> list) =>
      copyWith(
        navalMoveOrdersByPlayerId: _appendOrdersByPlayer(
          navalMoveOrdersByPlayerId,
          playerId,
          list,
        ),
      );

  Orders appendNavalMissionOrders(
    String playerId,
    List<NavalMissionOrder> list,
  ) => copyWith(
    navalMissionOrdersByPlayerId: _appendOrdersByPlayer(
      navalMissionOrdersByPlayerId,
      playerId,
      list,
    ),
  );

  Orders appendDiplomaticOrders(String playerId, List<DiplomaticOrder> list) =>
      copyWith(
        diplomaticOrdersByPlayerId: _appendOrdersByPlayer(
          diplomaticOrdersByPlayerId,
          playerId,
          list,
        ),
      );

  Orders appendTradeOrders(String playerId, List<TradeOrder> list) => copyWith(
    tradeOrdersByPlayerId: _appendOrdersByPlayer(
      tradeOrdersByPlayerId,
      playerId,
      list,
    ),
  );

  Orders appendRecruitWorkerOrders(
    String playerId,
    List<RecruitWorkerOrder> list,
  ) => copyWith(
    recruitWorkerOrdersByPlayerId: _appendOrdersByPlayer(
      recruitWorkerOrdersByPlayerId,
      playerId,
      list,
    ),
  );
}
