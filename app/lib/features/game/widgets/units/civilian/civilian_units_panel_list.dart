import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_orders/src/orders/civilian_projected_tile.dart'
    show projectedCivilianTileKey;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/region_labels.dart';
import '../shared/region_section_header.dart';
import 'civilian_units_panel.dart';
import 'civilian_units_panel_unit_row.dart';

mixin CivilianUnitsPanelList on ConsumerState<CivilianUnitsPanel> {
  bool isExplorerUnit(Unit unit) {
    return workOrderTargetsByUnitType[unit.type]?.contains(
          kWorkTargetProspect,
        ) ??
        false;
  }

  bool isBuilderUnit(Unit unit) {
    return workOrderTargetsByUnitType[unit.type]?.contains(
          kWorkTargetBuildImprovement,
        ) ??
        false;
  }

  bool isEngineerUnit(Unit unit) {
    return workOrderTargetsByUnitType[unit.type]?.contains(
          kWorkTargetBuildRoad,
        ) ??
        false;
  }

  List<Widget> civilianListChildrenForRegion({
    required String regionId,
    required List<Unit> units,
    required bool multiOwner,
    required Game game,
    required Map<String, String> provinceNames,
    required bool tileScopeActive,
    required String? resolvedSelectedUnitId,
    required void Function(String id) onSelectUnit,
  }) {
    if (units.isEmpty) {
      return const [];
    }
    final children = <Widget>[
      RegionSectionHeader(
        label: regionDisplayLabel(regionId),
        variant: RegionHeaderVariant.bottomBorderMuted,
      ),
    ];
    if (!multiOwner) {
      children.addAll(
        units.map(
          (u) => unitRow(
            unit: u,
            provinceNames: provinceNames,
            tileScopeActive: tileScopeActive,
            resolvedSelectedUnitId: resolvedSelectedUnitId,
            onSelectUnit: onSelectUnit,
          ),
        ),
      );
      return children;
    }
    final byOwner = <String, List<Unit>>{};
    for (final u in units) {
      byOwner.putIfAbsent(u.ownerId, () => []).add(u);
    }
    final ownerIds = byOwner.keys.toList()..sort();
    for (final ownerId in ownerIds) {
      final ownerUnits = byOwner[ownerId]!;
      children.add(
        RegionSectionHeader(
          label: game.factionDisplayNameById(ownerId) ?? ownerId,
        ),
      );
      children.addAll(
        ownerUnits.map(
          (u) => unitRow(
            unit: u,
            provinceNames: provinceNames,
            tileScopeActive: tileScopeActive,
            resolvedSelectedUnitId: resolvedSelectedUnitId,
            onSelectUnit: onSelectUnit,
          ),
        ),
      );
    }
    return children;
  }

  Widget unitRow({
    required Unit unit,
    required Map<String, String> provinceNames,
    required bool tileScopeActive,
    required String? resolvedSelectedUnitId,
    required void Function(String id) onSelectUnit,
  }) {
    return CivilianUnitsPanelUnitRow(
      game: widget.game,
      unit: unit,
      provinceNames: provinceNames,
      currentOrders: widget.currentOrders,
      humanPlayerId: unit.ownerId,
      bus: widget.bus,
      readOnly: widget.readOnly,
      isTileScope: tileScopeActive,
      isSelectedInTileScope: resolvedSelectedUnitId == unit.id,
      onSelectInTileScope: () => onSelectUnit(unit.id),
      projectedTileKey: projectedCivilianTileKey(
        unit: unit,
        playerId: unit.ownerId,
        orders: widget.currentOrders,
      ),
      prospectShortcutTargetTileKey: widget.prospectShortcutTargetTileKey,
      exploreShortcutTargetTileKey: widget.exploreShortcutTargetTileKey,
      buildImprovementShortcutTargetTileKey:
          widget.buildImprovementShortcutTargetTileKey,
      buildRoadShortcutTargetTileKey: widget.buildRoadShortcutTargetTileKey,
    );
  }

  List<Unit> scopedCivilianUnits(
    List<Unit> units, {
    required String? tileScopeTileKey,
    required bool explorerOnly,
    required bool builderOnly,
    required bool engineerOnly,
  }) {
    final tileScopeActive =
        tileScopeTileKey != null && tileScopeTileKey.isNotEmpty;
    if (!tileScopeActive && !explorerOnly && !builderOnly && !engineerOnly) {
      return units;
    }
    return [
      for (final u in units)
        if ((!tileScopeActive ||
                projectedCivilianTileKey(
                      unit: u,
                      playerId: u.ownerId,
                      orders: widget.currentOrders,
                    ) ==
                    tileScopeTileKey) &&
            (!explorerOnly || isExplorerUnit(u)) &&
            (!builderOnly || isBuilderUnit(u)) &&
            (!engineerOnly || isEngineerUnit(u)))
          u,
    ];
  }
}
