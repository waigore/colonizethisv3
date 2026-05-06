// Order script parser - converts OrderCommand to Orders objects.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'scenario.dart';

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// Parses a list of OrderCommand into the game's Orders object.
Orders parseOrderCommands(List<OrderCommand> commands, Game game) {
  final gameWithArmies = ensureMilitaryArmiesForGame(game);
  final acc = _OrderAccumulator();

  for (final cmd in commands) {
    switch (cmd.type) {
      case 'move':
        _handleMoveCommand(acc, cmd, gameWithArmies);
        break;

      case 'build':
        _handleBuildCommand(acc, cmd);
        break;

      case 'work':
        _handleWorkCommand(acc, cmd);
        break;

      case 'diplomatic':
        _handleDiplomaticCommand(acc, cmd);
        break;

      case 'research':
        _handleResearchCommand(acc, cmd);
        break;

      case 'naval_move':
        _handleNavalMoveCommand(acc, cmd);
        break;

      case 'naval_mission':
        _handleNavalMissionCommand(acc, cmd);
        break;

      default:
        // Unknown order type - skip
        break;
    }
  }

  return acc.buildOrders();
}

final class _OrderAccumulator {
  final moveOrdersByPlayerId = <String, List<MoveOrder>>{};
  final armyMoveOrdersByPlayerId = <String, List<ArmyMoveOrder>>{};
  final buildUnitOrdersByPlayerId = <String, List<BuildUnitOrder>>{};
  final workOrdersByPlayerId = <String, List<WorkOrder>>{};
  final diplomaticOrdersByPlayerId = <String, List<DiplomaticOrder>>{};
  final researchOrdersByPlayerId = <String, List<ResearchOrder>>{};
  final navalMoveOrdersByPlayerId = <String, List<NavalMoveOrder>>{};
  final navalMissionOrdersByPlayerId = <String, List<NavalMissionOrder>>{};

  Orders buildOrders() {
    return Orders(
      moveOrdersByPlayerId: moveOrdersByPlayerId,
      armyMoveOrdersByPlayerId: armyMoveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: workOrdersByPlayerId,
      diplomaticOrdersByPlayerId: diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: researchOrdersByPlayerId,
      navalMoveOrdersByPlayerId: navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId: navalMissionOrdersByPlayerId,
    );
  }
}

void _handleMoveCommand(_OrderAccumulator acc, OrderCommand cmd, Game game) {
  final unitId = cmd.unit ?? '';
  final destination = cmd.to ?? '';
  final allUnits = <Unit>[
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ];
  final unit = _firstWhereOrNull(allUnits, (u) => u.id == unitId);
  if (_tryQueueArmyMove(acc, cmd, game, unitId, destination, unit)) {
    return;
  }
  acc.moveOrdersByPlayerId.putIfAbsent(cmd.player, () => []).add(
    MoveOrder(unitId: unitId, destinationTileKey: '$destination|0|0'),
  );
}

bool _tryQueueArmyMove(
  _OrderAccumulator acc,
  OrderCommand cmd,
  Game game,
  String unitId,
  String destination,
  Unit? unit,
) {
  if (unit == null || !isMilitaryUnit(unit.type)) {
    return false;
  }
  final army = _firstWhereOrNull(
    game.worldState.armies,
    (a) => a.ownerId == cmd.player && a.regimentUnitIds.contains(unitId),
  );
  if (army == null) {
    return false;
  }
  final list = acc.armyMoveOrdersByPlayerId.putIfAbsent(cmd.player, () => []);
  final alreadyQueued =
      list.any((o) => o.armyId == army.id && o.destinationProvinceId == destination);
  if (!alreadyQueued) {
    list.add(ArmyMoveOrder(armyId: army.id, destinationProvinceId: destination));
  }
  return true;
}

void _handleBuildCommand(_OrderAccumulator acc, OrderCommand cmd) {
  final unitType = cmd.unitType ?? 'infantry';
  final isMilitary =
      buildUnitCategoryForUnitType(unitType) == BuildUnitCategory.military;
  final buildOrder = BuildUnitOrder(
    unitType: unitType,
    isMilitary: isMilitary,
    spawnProvinceId: cmd.inProvince ?? '',
  );
  acc.buildUnitOrdersByPlayerId.putIfAbsent(cmd.player, () => []).add(buildOrder);
}

void _handleWorkCommand(_OrderAccumulator acc, OrderCommand cmd) {
  final workOrder = WorkOrder(
    unitId: cmd.unit ?? '',
    target: cmd.workType ?? kWorkTargetExplore,
    targetTileKey: cmd.targetTileKey ?? '',
  );
  acc.workOrdersByPlayerId.putIfAbsent(cmd.player, () => []).add(workOrder);
}

void _handleDiplomaticCommand(_OrderAccumulator acc, OrderCommand cmd) {
  final typeName = cmd.diplomaticType ?? 'declareWar';
  final diploType = DiplomaticOrderType.values.firstWhere(
    (e) => e.name == typeName,
    orElse: () => DiplomaticOrderType.declareWar,
  );
  final overtureStage = cmd.overtureStage != null
      ? OvertureStage.values.firstWhere(
          (e) => e.name == cmd.overtureStage,
          orElse: () => OvertureStage.none,
        )
      : null;
  final diploOrder = DiplomaticOrder(
    type: diploType,
    targetFactionId: cmd.targetFactionId ?? '',
    amount: cmd.amount,
    overtureStage: overtureStage,
  );
  acc.diplomaticOrdersByPlayerId.putIfAbsent(cmd.player, () => []).add(diploOrder);
}

void _handleResearchCommand(_OrderAccumulator acc, OrderCommand cmd) {
  final researchOrder = ResearchOrder(
    slotIndex: cmd.slotIndex ?? 0,
    techId: cmd.techId ?? '',
    funding: ResearchFundingLevel.low,
  );
  acc.researchOrdersByPlayerId.putIfAbsent(cmd.player, () => []).add(researchOrder);
}

void _handleNavalMoveCommand(_OrderAccumulator acc, OrderCommand cmd) {
  final portId = cmd.destinationPortProvinceId;
  final isDock = portId != null && portId.isNotEmpty;
  final navalMoveOrder = isDock
      ? NavalMoveOrder(
          fleetId: cmd.fleetId ?? '',
          destinationPortProvinceId: portId,
        )
      : NavalMoveOrder(
          fleetId: cmd.fleetId ?? '',
          destinationSeaZoneId: cmd.destinationSeaZoneId ?? '',
        );
  acc.navalMoveOrdersByPlayerId.putIfAbsent(cmd.player, () => []).add(navalMoveOrder);
}

void _handleNavalMissionCommand(_OrderAccumulator acc, OrderCommand cmd) {
  final navalMissionOrder = NavalMissionOrder(
    fleetId: cmd.fleetId ?? '',
    mission: cmd.mission ?? 'patrol',
    targetPortId: cmd.targetPortId,
    targetProvinceId: cmd.targetProvinceId,
  );
  acc.navalMissionOrdersByPlayerId
      .putIfAbsent(cmd.player, () => [])
      .add(navalMissionOrder);
}
