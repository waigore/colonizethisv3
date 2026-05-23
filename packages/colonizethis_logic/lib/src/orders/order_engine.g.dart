// GENERATED FILE — do not edit by hand.
// Run: dart run tool/generate_order_engine_slots.dart
// Source: order_engine_manifest.yaml

part of 'order_engine.dart';

Map<String, List<MoveOrder>> _orderEngineGetMoveOrder(Orders o) => o.moveOrdersByPlayerId;

Orders _orderEngineWithMoveOrder(Orders o, Map<String, List<MoveOrder>> m) => o.copyWith(moveOrdersByPlayerId: m);

const _orderSlotMoveOrder = _OrderSlot<MoveOrder>(
  getter: _orderEngineGetMoveOrder,
  updater: _orderEngineWithMoveOrder,
  label: 'move',
);

Map<String, List<ArmyMoveOrder>> _orderEngineGetArmyMoveOrder(Orders o) => o.armyMoveOrdersByPlayerId;

Orders _orderEngineWithArmyMoveOrder(Orders o, Map<String, List<ArmyMoveOrder>> m) => o.copyWith(armyMoveOrdersByPlayerId: m);

const _orderSlotArmyMoveOrder = _OrderSlot<ArmyMoveOrder>(
  getter: _orderEngineGetArmyMoveOrder,
  updater: _orderEngineWithArmyMoveOrder,
  label: 'army move',
);

Map<String, List<BuildUnitOrder>> _orderEngineGetBuildUnitOrder(Orders o) => o.buildUnitOrdersByPlayerId;

Orders _orderEngineWithBuildUnitOrder(Orders o, Map<String, List<BuildUnitOrder>> m) => o.copyWith(buildUnitOrdersByPlayerId: m);

const _orderSlotBuildUnitOrder = _OrderSlot<BuildUnitOrder>(
  getter: _orderEngineGetBuildUnitOrder,
  updater: _orderEngineWithBuildUnitOrder,
  label: 'build',
);

Map<String, List<WorkOrder>> _orderEngineGetWorkOrder(Orders o) => o.workOrdersByPlayerId;

Orders _orderEngineWithWorkOrder(Orders o, Map<String, List<WorkOrder>> m) => o.copyWith(workOrdersByPlayerId: m);

const _orderSlotWorkOrder = _OrderSlot<WorkOrder>(
  getter: _orderEngineGetWorkOrder,
  updater: _orderEngineWithWorkOrder,
  label: 'work',
);

Map<String, List<DiplomaticOrder>> _orderEngineGetDiplomaticOrder(Orders o) => o.diplomaticOrdersByPlayerId;

Orders _orderEngineWithDiplomaticOrder(Orders o, Map<String, List<DiplomaticOrder>> m) => o.copyWith(diplomaticOrdersByPlayerId: m);

const _orderSlotDiplomaticOrder = _OrderSlot<DiplomaticOrder>(
  getter: _orderEngineGetDiplomaticOrder,
  updater: _orderEngineWithDiplomaticOrder,
  label: 'diplomatic',
);

Map<String, List<NavalMoveOrder>> _orderEngineGetNavalMoveOrder(Orders o) => o.navalMoveOrdersByPlayerId;

Orders _orderEngineWithNavalMoveOrder(Orders o, Map<String, List<NavalMoveOrder>> m) => o.copyWith(navalMoveOrdersByPlayerId: m);

const _orderSlotNavalMoveOrder = _OrderSlot<NavalMoveOrder>(
  getter: _orderEngineGetNavalMoveOrder,
  updater: _orderEngineWithNavalMoveOrder,
  label: 'naval move',
);

Map<String, List<NavalMissionOrder>> _orderEngineGetNavalMissionOrder(Orders o) => o.navalMissionOrdersByPlayerId;

Orders _orderEngineWithNavalMissionOrder(Orders o, Map<String, List<NavalMissionOrder>> m) => o.copyWith(navalMissionOrdersByPlayerId: m);

const _orderSlotNavalMissionOrder = _OrderSlot<NavalMissionOrder>(
  getter: _orderEngineGetNavalMissionOrder,
  updater: _orderEngineWithNavalMissionOrder,
  label: 'naval mission',
);

Map<String, List<RecruitWorkerOrder>> _orderEngineGetRecruitWorkerOrder(Orders o) => o.recruitWorkerOrdersByPlayerId;

Orders _orderEngineWithRecruitWorkerOrder(Orders o, Map<String, List<RecruitWorkerOrder>> m) => o.copyWith(recruitWorkerOrdersByPlayerId: m);

const _orderSlotRecruitWorkerOrder = _OrderSlot<RecruitWorkerOrder>(
  getter: _orderEngineGetRecruitWorkerOrder,
  updater: _orderEngineWithRecruitWorkerOrder,
  label: 'recruit worker',
);

Orders copyInitialOrdersForEngine(Orders initialOrders) =>
    Orders(
      moveOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.moveOrdersByPlayerId),
      armyMoveOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.armyMoveOrdersByPlayerId),
      buildUnitOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.buildUnitOrdersByPlayerId),
      workOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.workOrdersByPlayerId),
      diplomaticOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.diplomaticOrdersByPlayerId),
      navalMoveOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.navalMoveOrdersByPlayerId),
      navalMissionOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.navalMissionOrdersByPlayerId),
      recruitWorkerOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.recruitWorkerOrdersByPlayerId),
      researchOrdersByPlayerId: _copyMapOfOrderLists(initialOrders.researchOrdersByPlayerId),
    );

Orders copyOrdersSnapshotForEngine(Orders o) =>
    Orders(
      moveOrdersByPlayerId: _copyMapOfOrderLists(o.moveOrdersByPlayerId),
      armyMoveOrdersByPlayerId: _copyMapOfOrderLists(o.armyMoveOrdersByPlayerId),
      buildUnitOrdersByPlayerId: _copyMapOfOrderLists(o.buildUnitOrdersByPlayerId),
      workOrdersByPlayerId: _copyMapOfOrderLists(o.workOrdersByPlayerId),
      diplomaticOrdersByPlayerId: _copyMapOfOrderLists(o.diplomaticOrdersByPlayerId),
      navalMoveOrdersByPlayerId: _copyMapOfOrderLists(o.navalMoveOrdersByPlayerId),
      navalMissionOrdersByPlayerId: _copyMapOfOrderLists(o.navalMissionOrdersByPlayerId),
      recruitWorkerOrdersByPlayerId: _copyMapOfOrderLists(o.recruitWorkerOrdersByPlayerId),
      researchOrdersByPlayerId: _copyMapOfOrderLists(o.researchOrdersByPlayerId),
    );

mixin _OrderEngineGeneratedOrderMethods {
  OrderValidationResult addMoveOrder(String playerId, MoveOrder order) =>
      (this as OrderEngine).addOrderForSlot(playerId, order, _orderSlotMoveOrder);

  OrderValidationResult addMoveOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    MoveOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => (this as OrderEngine).addOrderForSlotWithContext(
    game,
    topology,
    playerId,
    order,
    _orderSlotMoveOrder,
    tileMapByRegion: tileMapByRegion,
  );

  void removeMoveOrder(String playerId, int index) =>
      (this as OrderEngine).removeOrderForSlot(playerId, index, _orderSlotMoveOrder);

  OrderValidationResult addArmyMoveOrder(String playerId, ArmyMoveOrder order) =>
      (this as OrderEngine).addOrderForSlot(playerId, order, _orderSlotArmyMoveOrder);

  OrderValidationResult addArmyMoveOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    ArmyMoveOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => (this as OrderEngine).addOrderForSlotWithContext(
    game,
    topology,
    playerId,
    order,
    _orderSlotArmyMoveOrder,
    tileMapByRegion: tileMapByRegion,
  );

  void removeArmyMoveOrder(String playerId, int index) =>
      (this as OrderEngine).removeOrderForSlot(playerId, index, _orderSlotArmyMoveOrder);

  OrderValidationResult addBuildOrder(String playerId, BuildUnitOrder order) =>
      (this as OrderEngine).addOrderForSlot(playerId, order, _orderSlotBuildUnitOrder);

  OrderValidationResult addBuildOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    BuildUnitOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => (this as OrderEngine).addOrderForSlotWithContext(
    game,
    topology,
    playerId,
    order,
    _orderSlotBuildUnitOrder,
    tileMapByRegion: tileMapByRegion,
  );

  void removeBuildOrder(String playerId, int index) =>
      (this as OrderEngine).removeOrderForSlot(playerId, index, _orderSlotBuildUnitOrder);

  OrderValidationResult addWorkOrder(String playerId, WorkOrder order) =>
      (this as OrderEngine).addOrderForSlot(playerId, order, _orderSlotWorkOrder);

  OrderValidationResult addWorkOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    WorkOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => (this as OrderEngine).addOrderForSlotWithContext(
    game,
    topology,
    playerId,
    order,
    _orderSlotWorkOrder,
    tileMapByRegion: tileMapByRegion,
  );

  void removeWorkOrder(String playerId, int index) =>
      (this as OrderEngine).removeOrderForSlot(playerId, index, _orderSlotWorkOrder);

  OrderValidationResult addDiplomaticOrder(String playerId, DiplomaticOrder order) =>
      (this as OrderEngine).addOrderForSlot(playerId, order, _orderSlotDiplomaticOrder);

  OrderValidationResult addDiplomaticOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    DiplomaticOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => (this as OrderEngine).addOrderForSlotWithContext(
    game,
    topology,
    playerId,
    order,
    _orderSlotDiplomaticOrder,
    tileMapByRegion: tileMapByRegion,
  );

  void removeDiplomaticOrder(String playerId, int index) =>
      (this as OrderEngine).removeOrderForSlot(playerId, index, _orderSlotDiplomaticOrder);

  OrderValidationResult addNavalMoveOrder(String playerId, NavalMoveOrder order) =>
      (this as OrderEngine).addOrderForSlot(playerId, order, _orderSlotNavalMoveOrder);

  OrderValidationResult addNavalMoveOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    NavalMoveOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => (this as OrderEngine).addOrderForSlotWithContext(
    game,
    topology,
    playerId,
    order,
    _orderSlotNavalMoveOrder,
    tileMapByRegion: tileMapByRegion,
  );

  void removeNavalMoveOrder(String playerId, int index) =>
      (this as OrderEngine).removeOrderForSlot(playerId, index, _orderSlotNavalMoveOrder);

  OrderValidationResult addNavalMissionOrder(String playerId, NavalMissionOrder order) =>
      (this as OrderEngine).addOrderForSlot(playerId, order, _orderSlotNavalMissionOrder);

  OrderValidationResult addNavalMissionOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    NavalMissionOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => (this as OrderEngine).addOrderForSlotWithContext(
    game,
    topology,
    playerId,
    order,
    _orderSlotNavalMissionOrder,
    tileMapByRegion: tileMapByRegion,
  );

  void removeNavalMissionOrder(String playerId, int index) =>
      (this as OrderEngine).removeOrderForSlot(playerId, index, _orderSlotNavalMissionOrder);

  OrderValidationResult addRecruitWorkerOrder(String playerId, RecruitWorkerOrder order) =>
      (this as OrderEngine).addOrderForSlot(playerId, order, _orderSlotRecruitWorkerOrder);

  OrderValidationResult addRecruitWorkerOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    RecruitWorkerOrder order, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => (this as OrderEngine).addOrderForSlotWithContext(
    game,
    topology,
    playerId,
    order,
    _orderSlotRecruitWorkerOrder,
    tileMapByRegion: tileMapByRegion,
  );

  void removeRecruitWorkerOrder(String playerId, int index) =>
      (this as OrderEngine).removeOrderForSlot(playerId, index, _orderSlotRecruitWorkerOrder);

}

