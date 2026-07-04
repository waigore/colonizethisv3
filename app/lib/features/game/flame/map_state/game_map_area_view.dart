part of 'game_map_area.dart';

/// Camera/view-state controls for [GameMapArea]: base-layer display cycling,
/// map view state persistence, capital centering, tile locating, and region
/// viewport snapshot handling (Refs #3699 Theme 3).
mixin _GameMapAreaView on ConsumerState<GameMapArea>, _GameMapAreaStateBase {
  void _cycleBaseLayerDisplayMode() {
    setState(() {
      _baseLayerDisplayMode = switch (_baseLayerDisplayMode) {
        BaseLayerDisplayMode.terrainOnly =>
          BaseLayerDisplayMode.terrainAndResources,
        BaseLayerDisplayMode.terrainAndResources =>
          BaseLayerDisplayMode.terrainAndResourcesImprovementLabels,
        BaseLayerDisplayMode.terrainAndResourcesImprovementLabels =>
          BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads,
        BaseLayerDisplayMode.terrainAndResourcesImprovementsRoads =>
          BaseLayerDisplayMode.terrainOnly,
      };
    });
  }

  void _setMapViewState(ct_models.MapViewState next) {
    if (_mapViewState == next) {
      return;
    }
    setState(() {
      _mapViewState = next;
    });
    final current = ref.read(currentGameProvider);
    if (current != null && current.id == widget.game.id) {
      ref
          .read(currentGameProvider.notifier)
          .setGame(current.copyWith(mapViewState: next));
    }
  }

  void _togglePlayerTurnEventsFeedVisibility() {
    _setMapViewState(
      _mapViewState.copyWith(
        showPlayerTurnEventsFeed: !_mapViewState.showPlayerTurnEventsFeed,
      ),
    );
  }

  /// Runs the one-shot shell-entry auto-center on the current player's capital.
  /// Skipped in global observe (no `viewingPlayerId`) or when the current
  /// player has no capital. SPEC/ui/empire-overview.md § Initial map viewport.
  void _maybeAutoCenterOnShellEntry() {
    if (_didAutoCenterOnEntry) {
      return;
    }
    _didAutoCenterOnEntry = true;
    final shell = ref.read(shellPlayerContextProvider);
    _applyCapitalCenter(shell.viewingPlayerId);
  }

  /// Manual home-to-capital action: centers on the current player's capital.
  /// SPEC/ui/empire-overview.md § Home-to-capital button.
  void _centerOnCurrentPlayerCapital() {
    final shell = ref.read(shellPlayerContextProvider);
    _applyCapitalCenter(shell.mapPlayerIdFor(widget.game));
  }

  /// Switches the region tab, centers the camera, and sets the secondary
  /// highlight on [currentPlayerId]'s capital tile. No-op when the resolved
  /// target is null (global observe or no capital).
  void _applyCapitalCenter(String? currentPlayerId) {
    final target = GameMapAreaStateLogic.resolveShellEntryAutoCenter(
      game: widget.game,
      currentPlayerId: currentPlayerId,
    );
    if (target == null) {
      return;
    }
    ref
        .read(mapProvincePanelProvider.notifier)
        .setSecondaryHighlight(target.tileKey);
    setState(() {
      _centerOnTileKey = target.tileKey;
      _regionIndex = target.regionIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _centerOnTileKey = null;
      });
    });
  }

  void _locateTile(String tileKey, String regionId) {
    ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(tileKey);
    setState(() {
      _centerOnTileKey = tileKey;
      if (regionId == kRegionNewWorld) {
        _regionIndex = 1;
      } else if (regionId == kRegionOldWorld) {
        _regionIndex = 0;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _centerOnTileKey = null);
    });
  }

  void _openMapTileDetail(String tileKey) {
    final regionId = ct_models.Unit.regionIdFromTileKey(tileKey);
    if (regionId == null) return;
    ref.read(mapProvincePanelProvider.notifier).reportMapTileTapped(tileKey);
    setState(() {
      if (regionId == kRegionNewWorld) {
        _regionIndex = 1;
      } else if (regionId == kRegionOldWorld) {
        _regionIndex = 0;
      }
    });
  }

  void _onRegionViewportSnapshot(RegionMapViewportSnapshot snapshot) {
    final clampedMultiplier = snapshot.zoomMultiplier.clamp(0.5, 8.0);
    if ((clampedMultiplier - _mapViewState.zoomMultiplier).abs() > 0.001) {
      _setMapViewState(
        _mapViewState.copyWith(zoomMultiplier: clampedMultiplier),
      );
    }
    _pendingRegionViewport = snapshot;
    if (_regionViewportFrameScheduled) return;
    _regionViewportFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _regionViewportFrameScheduled = false;
      if (!mounted) return;
      final next = _pendingRegionViewport;
      _pendingRegionViewport = null;
      if (next == null) return;
      final cur = _regionViewportSnapshot;
      if (cur != null && cur.matches(next)) return;
      setState(() => _regionViewportSnapshot = next);
    });
  }
}
