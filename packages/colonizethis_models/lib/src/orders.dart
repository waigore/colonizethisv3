import 'model_collection_equality.dart';
import 'diplomacy.dart';
import 'orders_serialization.dart';
import 'world_market.dart';

import 'orders/build_work_orders.dart';
import 'orders/move_orders.dart';

export 'orders/build_work_orders.dart';
export 'orders/move_orders.dart';


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

  Map<String, dynamic> toJson() => encodeOrdersToJson(this);

  static Orders fromJson(Map<String, dynamic> json) => decodeOrdersFromJson(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Orders &&
          runtimeType == other.runtimeType &&
          modelMapOfListEquals(
            moveOrdersByPlayerId,
            other.moveOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
            armyMoveOrdersByPlayerId,
            other.armyMoveOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
            buildUnitOrdersByPlayerId,
            other.buildUnitOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
            workOrdersByPlayerId,
            other.workOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
            diplomaticOrdersByPlayerId,
            other.diplomaticOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
            researchOrdersByPlayerId,
            other.researchOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
            navalMoveOrdersByPlayerId,
            other.navalMoveOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
            navalMissionOrdersByPlayerId,
            other.navalMissionOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
            recruitWorkerOrdersByPlayerId,
            other.recruitWorkerOrdersByPlayerId,
          ) &&
          modelMapOfListEquals(
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
    tradeOrdersByPlayerId: tradeOrdersByPlayerId ?? this.tradeOrdersByPlayerId,
  );
}
