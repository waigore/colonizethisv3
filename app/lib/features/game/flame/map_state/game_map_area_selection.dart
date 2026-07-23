part of 'game_map_area.dart';

/// Civilian work-target tile selection for [GameMapArea]: maintaining the
/// per-player valid-tile cache, starting/cancelling a selection, and committing
/// the resulting work order (Refs #3699 Theme 3).
mixin _GameMapAreaSelection on ConsumerState<GameMapArea>, _GameMapAreaStateBase {
  void _refreshWorkTargetSelectionCache(ct_models.Game game) {
    final view = buildPlayerView(
      game,
      widget.mapViewData.combinedTopology,
      _mapPlayerId,
    );
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    _workTargetSelectionCache.refresh(
      WorkTargetSelectionSnapshot(
        game: game,
        playerId: _mapPlayerId,
        playerView: view,
        topology: widget.mapViewData.combinedTopology,
        currentOrders: const ct_models.Orders(),
        tileMapByRegion: mapData?.tileMapByRegion,
      ),
    );
  }

  int? _preferredRegionIndexForValidSelection(Set<String> validTileKeys) {
    if (validTileKeys.isEmpty) {
      return null;
    }
    final currentRegionId = _currentRegion.regionId;
    final hasCurrent = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$currentRegionId|'),
    );
    if (hasCurrent) {
      return null;
    }
    final hasOldWorld = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$kRegionOldWorld|'),
    );
    final hasNewWorld = validTileKeys.any(
      (tileKey) => tileKey.startsWith('$kRegionNewWorld|'),
    );
    if (hasOldWorld && !hasNewWorld) {
      return 0;
    }
    if (hasNewWorld && !hasOldWorld) {
      return 1;
    }
    return null;
  }

  void _computeValidTileKeysForSelection() {
    if (_workTargetSelection == null) {
      _cachedValidTileKeys = null;
      return;
    }
    final game = ref.read(currentGameProvider);
    if (game == null) {
      _cachedValidTileKeys = null;
      return;
    }
    final orders = ref.read(currentOrdersProvider);
    final mapData = ref.read(gameServiceProvider).getMapData(game.id);
    final topology = mapData?.combinedTopology ?? const MapTopology();
    final view = buildPlayerView(game, topology, _mapPlayerId);
    final workTarget = _workTargetSelection!.workTarget;
    _cachedValidTileKeys =
        GameMapAreaStateLogic.resolveValidTileKeysForCivilianWorkSelection(
          workTarget: workTarget,
          workTargetSelectionCache: _workTargetSelectionCache,
          humanPlayerId: _mapPlayerId,
          selectedUnitId: _workTargetSelection!.unit.id,
          game: game,
          currentOrders: orders,
          playerView: view,
          topology: topology,
          tileMapByRegion: mapData?.tileMapByRegion,
        );
  }

  ct_models.Unit? _findUnitById(String unitId) {
    for (final unit in widget.game.worldState.oldWorld.units) {
      if (unit.id == unitId) return unit;
    }
    for (final unit in widget.game.worldState.newWorld.units) {
      if (unit.id == unitId) return unit;
    }
    return null;
  }

  void _startWorkTargetSelection(String unitId, String workTarget) {
    final unit = _findUnitById(unitId);
    if (unit == null) return;
    setState(() {
      _workTargetSelection = (unit: unit, workTarget: workTarget);
      _computeValidTileKeysForSelection();
      final validTileKeys = _cachedValidTileKeys;
      if (validTileKeys != null) {
        final preferredRegionIndex = _preferredRegionIndexForValidSelection(
          validTileKeys,
        );
        if (preferredRegionIndex != null) {
          _regionIndex = preferredRegionIndex;
        }
      }
    });
  }

  void _cancelWorkTargetSelection() {
    if (_workTargetSelection == null) {
      return;
    }
    setState(() {
      _workTargetSelection = null;
      _cachedValidTileKeys = null;
    });
  }

  void _onTileSelectedForWork(String tileKey) {
    if (!ref.read(shellPlayerContextProvider).canMutateViaUi) {
      return;
    }
    final sel = _workTargetSelection;
    if (sel == null) return;
    final target = sel.workTarget;
    final targetTileKey = GameMapAreaStateLogic.translateWorkTargetTileKey(
      tileKey: tileKey,
      workTarget: target,
    );
    final workOrder = ct_models.WorkOrder(
      unitId: sel.unit.id,
      target: target,
      targetTileKey: targetTileKey,
    );
    final orders = ref.read(currentOrdersProvider);
    ref
        .read(currentOrdersProvider.notifier)
        .replaceAll(
          GameMapAreaStateLogic.addHumanWorkOrder(
            orders: orders,
            humanPlayerId: _mapPlayerId,
            workOrder: workOrder,
          ),
        );
    setState(() {
      _selectedCivilianTileKey =
          GameMapAreaStateLogic.selectionAfterWorkAssignment(
            currentSelectedCivilianTileKey: _selectedCivilianTileKey,
            assignedTileKey: targetTileKey,
          );
      _workTargetSelection = null;
      _cachedValidTileKeys = null;
    });
  }
}
