part of 'naval_units_panel.dart';

extension _NavalUnitsPanelBuild on _NavalUnitsPanelState {
  Widget buildNavalUnitsPanel(BuildContext context) {
    final l10n = appL10n(context);
    final tileScopeActive =
        widget.tileScopeTileKey != null && widget.tileScopeTileKey!.isNotEmpty;
    final tree = buildNavalTree(
      widget.game,
      widget.humanPlayerId,
      widget.topology,
      widget.draftOrders,
      l10n,
      tileMapByRegion: widget.tileMapByRegion,
      topologyByRegion: widget.topologyByRegion,
      locationScopeKeyFilter: widget.locationScopeKey,
    );
    final flat = flattenNavalTree(tree);
    _visibleScopedFleetIds.clear();
    _visibleScopedFleetIds.addAll(flat.map((row) => row.fleetId));
    final hasAny = tree.any(
      (group) => group.homeFleet != null || group.locations.isNotEmpty,
    );
    final canCombine = !widget.readOnly && _canCombineSelection(flat);
    final readOnly = widget.readOnly;

    // Header actions render as compact **primary** pills
    // (`CtActionTextButton(primary: true)`) per SPEC/ui/naval-units-panel.md
    // § Header actions and issue #3514 owner decisions #5 / #15. The optional
    // tile-scope pill (and its 4px spacer) leads the shared select-all +
    // Combine cluster assembled by `BaseUnitsPanelState.buildUnitsPanel`.
    final panel = buildUnitsPanel(
      title: tileScopeActive
          ? l10n.naval_units_title_tile
          : l10n.naval_units_title,
      leadingActions: [
        if (tileScopeActive)
          CtActionTextButton(
            primary: true,
            enabled: widget.tileScopeTileKey!.isNotEmpty,
            onPressed: () {
              final key = widget.tileScopeTileKey!;
              widget.bus.closePanelThenEmit(
                OpenMapTileDetailEvent(tileKey: key),
              );
            },
            label: l10n.civilian_units_tile,
          ),
        if (tileScopeActive && hasAny && flat.isNotEmpty)
          const SizedBox(width: 4),
      ],
      trailingActions: [
        CtActionTextButton(
          primary: true,
          onPressed: readOnly ? null : _openTrainDialog,
          enabled: !readOnly,
          label: l10n.common_train,
        ),
      ],
      showCombineCluster: hasAny && flat.isNotEmpty && !readOnly,
      selectableIds: _fleetSelectionIds(flat),
      selectAllTooltip: l10n.naval_units_selectAllFleets,
      deselectAllTooltip: l10n.naval_units_deselectAllFleets,
      combineLabel: l10n.common_combine,
      canCombine: canCombine,
      onSelectAll: () => _onHeaderSelectAllTapped(flat),
      onCombine: () => _performCombine(flat),
      hasContent: hasAny,
      listChildren: _navalListChildren(
        tree: tree,
        l10n: l10n,
        readOnly: readOnly,
      ),
      emptyMessage: l10n.naval_units_empty,
    );
    if (kCtE2EEnabled) {
      updateCtE2eNavalPanelSnapshotIfEnabled(
        CtE2eNavalPanelSnapshot(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          topology: widget.topology,
          draftOrders: widget.draftOrders,
          tileMapByRegion: widget.tileMapByRegion,
          topologyByRegion: widget.topologyByRegion,
          locationScopeKey: widget.locationScopeKey,
          initialSelectedFleetId: widget.initialSelectedFleetId,
          tileScopeTileKey: widget.tileScopeTileKey,
        ),
      );
      return KeyedSubtree(key: kCtE2ENavalPanelRootKey, child: panel);
    }
    return panel;
  }
}
