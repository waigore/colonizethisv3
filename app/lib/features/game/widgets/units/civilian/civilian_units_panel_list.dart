part of 'civilian_units_panel.dart';

extension _CivilianUnitsPanelList on _CivilianUnitsPanelState {
  bool _isExplorerUnit(Unit unit) {
    return workOrderTargetsByUnitType[unit.type]?.contains(
          kWorkTargetProspect,
        ) ??
        false;
  }

  bool _isBuilderUnit(Unit unit) {
    return workOrderTargetsByUnitType[unit.type]?.contains(
          kWorkTargetBuildImprovement,
        ) ??
        false;
  }

  List<Widget> _civilianListChildrenForRegion({
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
          (u) => _unitRow(
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
          (u) => _unitRow(
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

  Widget _unitRow({
    required Unit unit,
    required Map<String, String> provinceNames,
    required bool tileScopeActive,
    required String? resolvedSelectedUnitId,
    required void Function(String id) onSelectUnit,
  }) {
    return _UnitRow(
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
    );
  }

  List<Unit> _scopedCivilianUnits(
    List<Unit> units, {
    required String? tileScopeTileKey,
    required bool explorerOnly,
    required bool builderOnly,
  }) {
    final tileScopeActive =
        tileScopeTileKey != null && tileScopeTileKey.isNotEmpty;
    if (!tileScopeActive && !explorerOnly && !builderOnly) {
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
            (!explorerOnly || _isExplorerUnit(u)) &&
            (!builderOnly || _isBuilderUnit(u)))
          u,
    ];
  }
}
