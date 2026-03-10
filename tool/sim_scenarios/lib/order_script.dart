// Order script parser - converts OrderCommand to Orders objects.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'scenario.dart';

/// Parses a list of OrderCommand into the game's Orders object.
Orders parseOrderCommands(List<OrderCommand> commands, Game game) {
  final moveOrdersByPlayerId = <String, List<MoveOrder>>{};
  final buildUnitOrdersByPlayerId = <String, List<BuildUnitOrder>>{};
  final workOrdersByPlayerId = <String, List<WorkOrder>>{};
  final diplomaticOrdersByPlayerId = <String, List<DiplomaticOrder>>{};
  final researchOrdersByPlayerId = <String, List<ResearchOrder>>{};
  final navalMoveOrdersByPlayerId = <String, List<NavalMoveOrder>>{};
  final navalMissionOrdersByPlayerId = <String, List<NavalMissionOrder>>{};

  for (final cmd in commands) {
    switch (cmd.type) {
      case 'move':
        final moveOrder = MoveOrder(
          unitId: cmd.unit ?? '',
          destinationProvinceId: cmd.to ?? '',
        );
        moveOrdersByPlayerId.putIfAbsent(cmd.player, () => []).add(moveOrder);
        break;

      case 'build':
        final unitType = cmd.unitType ?? 'infantry';
        final isMilitary = buildUnitCategoryForUnitType(unitType) ==
            BuildUnitCategory.military;
        final buildOrder = BuildUnitOrder(
          unitType: unitType,
          isMilitary: isMilitary,
          spawnProvinceId: cmd.inProvince ?? '',
        );
        buildUnitOrdersByPlayerId
            .putIfAbsent(cmd.player, () => [])
            .add(buildOrder);
        break;

      case 'work':
        // Work orders need unit ID and target. For tile-level work the scenario
        // should provide targetTileKey; otherwise empty string is used.
        final workOrder = WorkOrder(
          unitId: cmd.unit ?? '',
          target: cmd.workType ?? 'explore',
          targetTileKey: cmd.targetTileKey ?? '',
        );
        workOrdersByPlayerId.putIfAbsent(cmd.player, () => []).add(workOrder);
        break;

      case 'diplomatic':
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
        diplomaticOrdersByPlayerId
            .putIfAbsent(cmd.player, () => [])
            .add(diploOrder);
        break;

      case 'research':
        // Default slot 0 with low funding for tests
        final researchOrder = ResearchOrder(
          slotIndex: cmd.slotIndex ?? 0,
          techId: cmd.techId ?? '',
          funding: ResearchFundingLevel.low,
        );
        researchOrdersByPlayerId
            .putIfAbsent(cmd.player, () => [])
            .add(researchOrder);
        break;

      case 'naval_move':
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
        navalMoveOrdersByPlayerId
            .putIfAbsent(cmd.player, () => [])
            .add(navalMoveOrder);
        break;

      case 'naval_mission':
        final navalMissionOrder = NavalMissionOrder(
          fleetId: cmd.fleetId ?? '',
          mission: cmd.mission ?? 'patrol',
          targetPortId: cmd.targetPortId,
          targetProvinceId: cmd.targetProvinceId,
        );
        navalMissionOrdersByPlayerId
            .putIfAbsent(cmd.player, () => [])
            .add(navalMissionOrder);
        break;

      default:
        // Unknown order type - skip
        break;
    }
  }

  return Orders(
    moveOrdersByPlayerId: moveOrdersByPlayerId,
    buildUnitOrdersByPlayerId: buildUnitOrdersByPlayerId,
    workOrdersByPlayerId: workOrdersByPlayerId,
    diplomaticOrdersByPlayerId: diplomaticOrdersByPlayerId,
    researchOrdersByPlayerId: researchOrdersByPlayerId,
    navalMoveOrdersByPlayerId: navalMoveOrdersByPlayerId,
    navalMissionOrdersByPlayerId: navalMissionOrdersByPlayerId,
  );
}
