part of 'game_map_area.dart';

/// Map canvas stack and in-map overlay chrome (left rail, corner controls,
/// side menu, minimap, players bar, turn feed). Split from
/// [game_map_area_build_overlays.dart] for Phase 3 flame map modularization.
mixin _GameMapAreaBuildMapStack
    on
        ConsumerState<GameMapArea>,
        _GameMapAreaStateBase,
        _GameMapAreaView,
        _GameMapAreaSelection,
        _GameMapAreaE2e,
        _GameMapAreaBuildMapStackChrome {
  Widget _buildMapFocusedStack({
    required BuildContext context,
    required bool isNarrow,
    required RegionMapViewData projectedRegion,
    required String mapPlayerId,
    required PlayerView mapPlayerView,
    required ShellPlayerContext shell,
    required List<PlayerTurnEventFeedEntry> feedEntries,
  }) {
    return Stack(
      children: [
        const Positioned.fill(child: GameMapAreaBackground()),
        GameMapCanvasStack(
          isNarrow: isNarrow,
          game: widget.game,
          region: projectedRegion,
          baseLayerDisplayMode: _baseLayerDisplayMode,
          showProvinceOverlay: _mapViewState.showProvinceOverlay,
          showProvinceOwnershipTint: _mapViewState.showProvinceOwnershipTint,
          showProvinceNamesLayer: _mapViewState.showProvinceNamesLayer,
          humanPlayerId: mapPlayerId,
          playerView: mapPlayerView,
          visibilityMode: shell.mapVisibilityMode,
          omniscientDetail: shell.omniscientDetail,
          canMutateViaUi: shell.canMutateViaUi,
          workTargetSelectionCache: _workTargetSelectionCache,
          centerOnTileKey: _centerOnTileKey,
          validTileKeysForSelection: _validTileKeysForSelection,
          selectedCivilianTileKey: _selectedCivilianTileKey,
          onTileSelectedForWork: _workTargetSelection != null
              ? _onTileSelectedForWork
              : null,
          onWorkTargetSelectionCancelled: _workTargetSelection != null
              ? _cancelWorkTargetSelection
              : null,
          onCivilianTileStateChanged: (tileKey) {
            setState(() {
              _selectedCivilianTileKey = tileKey;
            });
          },
          onCivilianTileSelectionCleared: () {
            if (_selectedCivilianTileKey == null) return;
            setState(() {
              _selectedCivilianTileKey = null;
            });
          },
          bus: ref.read(appEventBusProvider),
          onRegionViewportSnapshot: _onRegionViewportSnapshot,
          zoomMultiplier: _mapViewState.zoomMultiplier,
        ),
        if (!_sideMenuOpen)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: kEdgeSwipeStripWidth,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 20) {
                  setState(() => _sideMenuOpen = true);
                }
              },
            ),
          ),
        Positioned(
          left: kEdgeSwipeStripWidth,
          top: 0,
          child: GameMapEmpireLeftRail(
            game: widget.game,
            humanPlayerId: mapPlayerId,
            narrow: isNarrow,
            onIconTappedWhileSelectionMode: _workTargetSelection != null
                ? _cancelWorkTargetSelection
                : null,
          ),
        ),
        Positioned(
          left: kMapOverlayEdgeInset,
          bottom: kMapOverlayEdgeInset,
          child: GameMapCornerControls(
            narrow: isNarrow,
            onCycleBaseLayerDisplayMode: _cycleBaseLayerDisplayMode,
            onCenterOnHomeCapital: _centerOnCurrentPlayerCapital,
            homeToCapitalEnabled: shell.viewingPlayerId != null,
            onOpenMapDisplayOptions: () {
              showDialog<void>(
                context: context,
                barrierColor: EditorialMonoclePalette.dialogScrim,
                builder: (context) {
                  return GameMapOptionsDialog(
                    initialState: _mapViewState,
                    onChanged: _setMapViewState,
                  );
                },
              );
            },
          ),
        ),
        if (kCtE2EEnabled) ..._buildE2eOverlayTaps(projectedRegion),
        if (_sideMenuOpen) ...[
          Positioned.fill(
            child: GameSideMenuScrim(
              onDismiss: () => setState(() => _sideMenuOpen = false),
            ),
          ),
          GameSideMenu(
            sideMenuOpen: _sideMenuOpen,
            onClose: () => setState(() => _sideMenuOpen = false),
          ),
        ],
        ..._buildMapStackChromeChildren(
          isNarrow: isNarrow,
          projectedRegion: projectedRegion,
          mapPlayerId: mapPlayerId,
          shell: shell,
          feedEntries: feedEntries,
        ),
      ],
    );
  }
}
