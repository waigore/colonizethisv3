part of 'civilian_units_panel.dart';

extension _CivilianUnitsPanelBuild on _CivilianUnitsPanelState {
  Widget buildCivilianUnitsPanel(BuildContext context) {
    final l10n = appL10n(context);
    final provinceNames = provinceNamesByPrefixedId(widget.game);
    final ownerIds = widget.civilianOwnerIds ?? {widget.humanPlayerId};
    final multiOwner = ownerIds.length > 1;
    final ow = civilianUnitsInRegionForOwners(
      widget.game.worldState.oldWorld.units,
      ownerIds,
      provinceNames,
      widget.currentOrders,
    );
    final nw = civilianUnitsInRegionForOwners(
      widget.game.worldState.newWorld.units,
      ownerIds,
      provinceNames,
      widget.currentOrders,
    );
    final scopeTileKey = widget.tileScopeTileKey;
    final tileScopeActive = scopeTileKey != null && scopeTileKey.isNotEmpty;
    final scopedOw = _scopedCivilianUnits(
      ow,
      tileScopeTileKey: scopeTileKey,
      explorerOnly: widget.explorerOnly,
      builderOnly: widget.builderOnly,
    );
    final scopedNw = _scopedCivilianUnits(
      nw,
      tileScopeTileKey: scopeTileKey,
      explorerOnly: widget.explorerOnly,
      builderOnly: widget.builderOnly,
    );
    final hasAny = scopedOw.isNotEmpty || scopedNw.isNotEmpty;
    final allScopedUnits = <Unit>[...scopedOw, ...scopedNw];
    final selectedUnitId = _selectedUnitId;
    final resolvedSelectedUnitId =
        selectedUnitId != null &&
            allScopedUnits.any((u) => u.id == selectedUnitId)
        ? selectedUnitId
        : (allScopedUnits.isNotEmpty ? allScopedUnits.first.id : null);
    Unit? resolvedSelectedUnit;
    if (resolvedSelectedUnitId != null) {
      for (final u in allScopedUnits) {
        if (u.id == resolvedSelectedUnitId) {
          resolvedSelectedUnit = u;
          break;
        }
      }
    }
    final headerTileKey = resolvedSelectedUnit == null
        ? null
        : projectedCivilianTileKey(
            unit: resolvedSelectedUnit,
            playerId: resolvedSelectedUnit.ownerId,
            orders: widget.currentOrders,
          );

    final panel = UnitsPanelShell(
      title: tileScopeActive
          ? l10n.civilian_units_title_tile
          : l10n.civilian_units_title,
      // Header actions render as compact **primary** pills
      // (`CtActionTextButton(primary: true)`) — gradient surface, 1 px
      // accent-dim border, no nine-patch corner brackets — per
      // SPEC/ui/civilian-units-panel.md § Header actions and issue #3514
      // owner decision #5.
      actions: [
        if (tileScopeActive)
          CtActionTextButton(
            primary: true,
            enabled: headerTileKey != null && headerTileKey.isNotEmpty,
            onPressed: () {
              final key = headerTileKey;
              if (key == null || key.isEmpty) {
                return;
              }
              widget.bus.closePanelThenEmit(
                OpenMapTileDetailEvent(tileKey: key),
              );
            },
            label: l10n.civilian_units_tile,
          ),
        CtActionTextButton(
          primary: true,
          enabled: !widget.readOnly,
          onPressed: widget.readOnly
              ? null
              : () {
                  widget.bus.closePanelThenEmit(
                    OpenDialogEvent(trainCiviliansDialogId),
                  );
                },
          label: l10n.common_train,
        ),
      ],
      hasContent: hasAny,
      listChildren: [
        ..._civilianListChildrenForRegion(
          regionId: kRegionOldWorld,
          units: scopedOw,
          multiOwner: multiOwner,
          game: widget.game,
          provinceNames: provinceNames,
          tileScopeActive: tileScopeActive,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
          onSelectUnit: (id) => setState(() => _selectedUnitId = id),
        ),
        ..._civilianListChildrenForRegion(
          regionId: kRegionNewWorld,
          units: scopedNw,
          multiOwner: multiOwner,
          game: widget.game,
          provinceNames: provinceNames,
          tileScopeActive: tileScopeActive,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
          onSelectUnit: (id) => setState(() => _selectedUnitId = id),
        ),
      ],
      emptyMessage: l10n.civilian_units_empty,
    );
    if (kCtE2EEnabled) {
      final snapshotTargets = <String, List<String>>{
        for (final u in allScopedUnits)
          u.id: ref.read(availableWorkTargetIdsForUnitProvider(u.id)),
      };
      updateCtE2eCivilianPanelSnapshotIfEnabled(
        CtE2eCivilianPanelSnapshot(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          currentOrders: widget.currentOrders,
          availableWorkTargets: snapshotTargets,
          tileScopeTileKey: widget.tileScopeTileKey,
          initialSelectedUnitId: widget.initialSelectedUnitId,
          resolvedSelectedUnitId: resolvedSelectedUnitId,
        ),
      );
      return KeyedSubtree(key: kCtE2ECivilianPanelRootKey, child: panel);
    }
    return panel;
  }
}
