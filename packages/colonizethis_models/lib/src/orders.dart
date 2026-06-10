import 'diplomacy.dart';
import 'model_validation_exception.dart';
import 'province_id.dart';
import 'worker_tier.dart';
import 'world_market.dart';

part 'orders/move_orders.dart';
part 'orders/build_work_orders.dart';

/// Per-player orders for the current turn.
/// SPEC/game/world-model.
/// SPEC/program/orders.md
class Orders {
  const Orders({
    this.moveOrdersByPlayerId = const {},
    this.armyMoveOrdersByPlayerId = const {},
    this.buildUnitOrdersByPlayerId = const {},
    this.workOrdersByPlayerId = const {},
    this.recruitWorkerOrdersByPlayerId = const {},
    this.diplomaticOrdersByPlayerId = const {},
    this.researchOrdersByPlayerId = const {},
    this.navalMoveOrdersByPlayerId = const {},
    this.navalMissionOrdersByPlayerId = const {},
    this.tradeOrdersByPlayerId = const {},
  });

  /// Player id -> list of move orders.
  final Map<String, List<MoveOrder>> moveOrdersByPlayerId;

  /// Player id -> land army move orders. SPEC/game/military-armies.md.
  final Map<String, List<ArmyMoveOrder>> armyMoveOrdersByPlayerId;

  /// Player id -> list of build-unit orders.
  final Map<String, List<BuildUnitOrder>> buildUnitOrdersByPlayerId;

  /// Player id -> list of work orders.
  final Map<String, List<WorkOrder>> workOrdersByPlayerId;

  /// Player id -> list of worker recruit / train orders.
  ///
  /// Single order type per SPEC/game/workers-and-population.md §
  /// Recruiting, Training, and Disbanding: the UI may surface "Recruit" and
  /// "Train" as separate controls but both emit a [RecruitWorkerOrder] with
  /// `targetTier` set. Applied in Build / work (phase 12) before
  /// [BuildUnitOrder].
  final Map<String, List<RecruitWorkerOrder>> recruitWorkerOrdersByPlayerId;

  /// Player id -> list of diplomatic orders. Phase 4.
  final Map<String, List<DiplomaticOrder>> diplomaticOrdersByPlayerId;

  /// Player id -> list of research orders. Phase 5.
  final Map<String, List<ResearchOrder>> researchOrdersByPlayerId;

  /// Player id -> list of naval move orders. Phase 5. SPEC/program/naval-movement-resolution.md.
  final Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId;

  /// Player id -> list of naval mission orders. Phase 6.
  final Map<String, List<NavalMissionOrder>> navalMissionOrdersByPlayerId;

  /// Player id -> list of world-market trade orders (bids and offers).
  /// Resolved in Phase 13 World Market. SPEC/program/world-market-resolution.md,
  /// SPEC/game/world-market.md.
  final Map<String, List<TradeOrder>> tradeOrdersByPlayerId;

  Map<String, dynamic> toJson() => {
    'moveOrdersByPlayerId': moveOrdersByPlayerId.map(
      (playerId, orders) =>
          MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
    ),
    if (armyMoveOrdersByPlayerId.isNotEmpty)
      'armyMoveOrdersByPlayerId': armyMoveOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    'buildUnitOrdersByPlayerId': buildUnitOrdersByPlayerId.map(
      (playerId, orders) =>
          MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
    ),
    'workOrdersByPlayerId': workOrdersByPlayerId.map(
      (playerId, orders) =>
          MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
    ),
    if (diplomaticOrdersByPlayerId.isNotEmpty)
      'diplomaticOrdersByPlayerId': diplomaticOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (researchOrdersByPlayerId.isNotEmpty)
      'researchOrdersByPlayerId': researchOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (navalMoveOrdersByPlayerId.isNotEmpty)
      'navalMoveOrdersByPlayerId': navalMoveOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (navalMissionOrdersByPlayerId.isNotEmpty)
      'navalMissionOrdersByPlayerId': navalMissionOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (recruitWorkerOrdersByPlayerId.isNotEmpty)
      'recruitWorkerOrdersByPlayerId': recruitWorkerOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
    if (tradeOrdersByPlayerId.isNotEmpty)
      'tradeOrdersByPlayerId': tradeOrdersByPlayerId.map(
        (playerId, orders) =>
            MapEntry(playerId, orders.map((o) => o.toJson()).toList()),
      ),
  };

  static Orders fromJson(Map<String, dynamic> json) {
    final moveRaw =
        json['moveOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final moveByPlayerId = <String, List<MoveOrder>>{};
    moveRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => MoveOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      moveByPlayerId[playerId] = list;
    });

    final armyMoveRaw =
        json['armyMoveOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final armyMoveByPlayerId = <String, List<ArmyMoveOrder>>{};
    armyMoveRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => ArmyMoveOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      armyMoveByPlayerId[playerId] = list;
    });

    final buildRaw =
        json['buildUnitOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final buildByPlayerId = <String, List<BuildUnitOrder>>{};
    buildRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => BuildUnitOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      buildByPlayerId[playerId] = list;
    });

    final workRaw =
        json['workOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final workByPlayerId = <String, List<WorkOrder>>{};
    workRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => WorkOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      workByPlayerId[playerId] = list;
    });

    final diploRaw =
        json['diplomaticOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final diploByPlayerId = <String, List<DiplomaticOrder>>{};
    diploRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => DiplomaticOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      diploByPlayerId[playerId] = list;
    });

    final researchRaw =
        json['researchOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final researchByPlayerId = <String, List<ResearchOrder>>{};
    researchRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => ResearchOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      researchByPlayerId[playerId] = list;
    });

    final navalRaw =
        json['navalMoveOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final navalByPlayerId = <String, List<NavalMoveOrder>>{};
    navalRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => NavalMoveOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      navalByPlayerId[playerId] = list;
    });

    final missionRaw =
        json['navalMissionOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final missionByPlayerId = <String, List<NavalMissionOrder>>{};
    missionRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => NavalMissionOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      missionByPlayerId[playerId] = list;
    });

    final recruitWorkerRaw =
        json['recruitWorkerOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final recruitWorkerByPlayerId = <String, List<RecruitWorkerOrder>>{};
    recruitWorkerRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => RecruitWorkerOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      recruitWorkerByPlayerId[playerId] = list;
    });

    final tradeRaw =
        json['tradeOrdersByPlayerId'] as Map<dynamic, dynamic>? ?? {};
    final tradeByPlayerId = <String, List<TradeOrder>>{};
    tradeRaw.forEach((key, value) {
      final playerId = key.toString();
      final list = (value as List<dynamic>? ?? [])
          .map(
            (e) => TradeOrder.fromJson(
              Map<String, dynamic>.from(e as Map<Object?, Object?>),
            ),
          )
          .toList();
      tradeByPlayerId[playerId] = list;
    });

    return Orders(
      moveOrdersByPlayerId: moveByPlayerId,
      armyMoveOrdersByPlayerId: armyMoveByPlayerId,
      buildUnitOrdersByPlayerId: buildByPlayerId,
      workOrdersByPlayerId: workByPlayerId,
      recruitWorkerOrdersByPlayerId: recruitWorkerByPlayerId,
      diplomaticOrdersByPlayerId: diploByPlayerId,
      researchOrdersByPlayerId: researchByPlayerId,
      navalMoveOrdersByPlayerId: navalByPlayerId,
      navalMissionOrdersByPlayerId: missionByPlayerId,
      tradeOrdersByPlayerId: tradeByPlayerId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Orders &&
          runtimeType == other.runtimeType &&
          _mapEquals(moveOrdersByPlayerId, other.moveOrdersByPlayerId) &&
          _mapEquals(
            armyMoveOrdersByPlayerId,
            other.armyMoveOrdersByPlayerId,
          ) &&
          _mapEquals(
            buildUnitOrdersByPlayerId,
            other.buildUnitOrdersByPlayerId,
          ) &&
          _mapEquals(workOrdersByPlayerId, other.workOrdersByPlayerId) &&
          _mapEquals(
            diplomaticOrdersByPlayerId,
            other.diplomaticOrdersByPlayerId,
          ) &&
          _mapEquals(
            researchOrdersByPlayerId,
            other.researchOrdersByPlayerId,
          ) &&
          _mapEquals(
            navalMoveOrdersByPlayerId,
            other.navalMoveOrdersByPlayerId,
          ) &&
          _mapEquals(
            navalMissionOrdersByPlayerId,
            other.navalMissionOrdersByPlayerId,
          ) &&
          _mapEquals(
            recruitWorkerOrdersByPlayerId,
            other.recruitWorkerOrdersByPlayerId,
          ) &&
          _mapEquals(
            tradeOrdersByPlayerId,
            other.tradeOrdersByPlayerId,
          );

  @override
  int get hashCode => Object.hash(
    runtimeType,
    Object.hashAll(
      moveOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      armyMoveOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      buildUnitOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      workOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      diplomaticOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      researchOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      navalMoveOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      navalMissionOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      recruitWorkerOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
    Object.hashAll(
      tradeOrdersByPlayerId.entries.map((e) => Object.hashAll(e.value)),
    ),
  );

  Orders copyWith({
    Map<String, List<MoveOrder>>? moveOrdersByPlayerId,
    Map<String, List<ArmyMoveOrder>>? armyMoveOrdersByPlayerId,
    Map<String, List<BuildUnitOrder>>? buildUnitOrdersByPlayerId,
    Map<String, List<WorkOrder>>? workOrdersByPlayerId,
    Map<String, List<RecruitWorkerOrder>>? recruitWorkerOrdersByPlayerId,
    Map<String, List<DiplomaticOrder>>? diplomaticOrdersByPlayerId,
    Map<String, List<ResearchOrder>>? researchOrdersByPlayerId,
    Map<String, List<NavalMoveOrder>>? navalMoveOrdersByPlayerId,
    Map<String, List<NavalMissionOrder>>? navalMissionOrdersByPlayerId,
    Map<String, List<TradeOrder>>? tradeOrdersByPlayerId,
  }) => Orders(
    moveOrdersByPlayerId: moveOrdersByPlayerId ?? this.moveOrdersByPlayerId,
    armyMoveOrdersByPlayerId:
        armyMoveOrdersByPlayerId ?? this.armyMoveOrdersByPlayerId,
    buildUnitOrdersByPlayerId:
        buildUnitOrdersByPlayerId ?? this.buildUnitOrdersByPlayerId,
    workOrdersByPlayerId: workOrdersByPlayerId ?? this.workOrdersByPlayerId,
    recruitWorkerOrdersByPlayerId:
        recruitWorkerOrdersByPlayerId ?? this.recruitWorkerOrdersByPlayerId,
    diplomaticOrdersByPlayerId:
        diplomaticOrdersByPlayerId ?? this.diplomaticOrdersByPlayerId,
    researchOrdersByPlayerId:
        researchOrdersByPlayerId ?? this.researchOrdersByPlayerId,
    navalMoveOrdersByPlayerId:
        navalMoveOrdersByPlayerId ?? this.navalMoveOrdersByPlayerId,
    navalMissionOrdersByPlayerId:
        navalMissionOrdersByPlayerId ?? this.navalMissionOrdersByPlayerId,
    tradeOrdersByPlayerId:
        tradeOrdersByPlayerId ?? this.tradeOrdersByPlayerId,
  );

  static bool _mapEquals<K, V>(Map<K, List<V>> a, Map<K, List<V>> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final otherList = b[entry.key];
      if (otherList == null || otherList.length != entry.value.length) {
        return false;
      }
      for (var i = 0; i < entry.value.length; i++) {
        if (entry.value[i] != otherList[i]) return false;
      }
    }
    return true;
  }
}
