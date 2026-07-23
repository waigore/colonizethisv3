part of 'military_units_panel.dart';

extension _MilitaryUnitsPanelBuild on _MilitaryUnitsPanelState {
  Widget buildMilitaryUnitsPanel(BuildContext context) {
    final l10n = appL10n(context);
    final groups = buildMilitaryGroups(widget.game, widget.humanPlayerId);
    final flat = flattenMilitaryArmyBlocks(groups);
    final hasAny = groups.isNotEmpty;
    final readOnly = widget.readOnly;
    final canCombine =
        !readOnly && canCombineArmySelection(flat, selection.selectedIds);

    // Shared select-all + Combine cluster per SPEC/ui/military-units-panel.md
    // § Header actions and issue #3514 owner decisions #5 / #15; the trailing
    // Train pill follows the cluster (`BaseUnitsPanelState.buildUnitsPanel`).
    return buildUnitsPanel(
      title: l10n.military_units_title,
      showCombineCluster: hasAny && flat.isNotEmpty && !readOnly,
      selectableIds: _armyIds(flat),
      selectAllTooltip: l10n.military_units_selectAllArmies,
      deselectAllTooltip: l10n.military_units_deselectAllArmies,
      combineLabel: l10n.common_combine,
      canCombine: canCombine,
      onSelectAll: () => selectAllOrClear(_armyIds(flat)),
      onCombine: () => _performCombine(flat),
      trailingActions: [
        CtActionTextButton(
          primary: true,
          onPressed: readOnly ? null : _openTrainDialog,
          enabled: !readOnly,
          label: l10n.common_train,
        ),
      ],
      hasContent: hasAny,
      listChildren: _buildListChildren(groups, l10n),
      emptyMessage: l10n.military_units_empty,
    );
  }

  List<Widget> _buildListChildren(
    List<RegionMilitaryGroup> groups,
    AppLocalizations l10n,
  ) {
    return [
      for (final group in groups) ...[
        RegionSectionHeader(
          label: regionDisplayLabel(group.regionKey),
          variant: RegionHeaderVariant.leftBar,
        ),
        ..._buildProvinceLocationChildren(group, l10n),
        ..._buildSeaLocationChildren(group, l10n),
      ],
    ];
  }

  List<Widget> _buildProvinceLocationChildren(
    RegionMilitaryGroup group,
    AppLocalizations l10n,
  ) {
    return [
      for (final loc in group.provinces) ...[
        LocationSectionHeader(
          label: loc.displayLabel,
          regionLabel: regionDisplayLabel(loc.regionId),
        ),
        for (final block in loc.armies) _buildArmyTile(block, l10n),
      ],
    ];
  }

  Widget _buildArmyTile(ArmyBlock block, AppLocalizations l10n) {
    return _ArmyExpansionTile(
      block: block,
      l10n: l10n,
      stationedProvinceDisplayLabel: armyStationedProvinceDisplayLabel(
        widget.game,
        block.army,
      ),
      draftArmyMoveLine: armyDraftMoveLineForArmy(
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        armyId: block.army.id,
        draftOrders: widget.draftOrders,
      ),
      isSelectedForCombine: isSelected(block.army.id),
      combineSelectionEnabled: !widget.readOnly,
      onCombineSelectionToggle: () => toggleSelection(block.army.id),
      onLocate: _armyLocateCallback(block),
      onSplit: widget.readOnly || block.army.regimentUnitIds.length < 2
          ? null
          : () => _openSplitDialog(block),
      onMove:
          widget.readOnly ||
              block.army.isHomeArmy ||
              block.army.regimentUnitIds.isEmpty
          ? null
          : () => _openMoveDialog(block),
    );
  }

  VoidCallback? _armyLocateCallback(ArmyBlock block) {
    if (block.rows.isEmpty || block.rows.first.tileKey == null) {
      return null;
    }
    return () => _emitLocateMapTile(
      tileKey: block.rows.first.tileKey!,
      regionId: block.regionKey,
    );
  }

  List<Widget> _buildSeaLocationChildren(
    RegionMilitaryGroup group,
    AppLocalizations l10n,
  ) {
    return [
      for (final loc in group.seaLocations) ...[
        LocationSectionHeader(
          label: loc.displayLabel,
          regionLabel: regionDisplayLabel(loc.regionId),
        ),
        for (final row in loc.rows)
          _ShipRow(
            row: row,
            l10n: l10n,
            onTap: row.tileKey == null
                ? null
                : () => _emitLocateMapTile(
                    tileKey: row.tileKey!,
                    regionId: row.regionId,
                  ),
          ),
      ],
    ];
  }

  void _emitLocateMapTile({required String tileKey, required String regionId}) {
    widget.bus.closePanelThenEmit(
      LocateMapTileEvent(tileKey: tileKey, regionId: regionId),
    );
  }
}
