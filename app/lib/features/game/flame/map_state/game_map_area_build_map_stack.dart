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
        _GameMapAreaE2e {
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
        Consumer(
          builder: (context, ref, _) {
            final panelOpen =
                ref.watch(mapProvincePanelProvider).overlayOpen;
            final rightInset = !isNarrow
                ? gameMapWideOverlayRightInset(provincePanelOpen: panelOpen)
                : kGameMapWideStackRightGutter;
            return Positioned(
              right: rightInset,
              bottom: 8,
              child: GameRegionMinimap(
                region: projectedRegion,
                viewportSnapshot: _regionViewportSnapshot,
                bus: ref.read(appEventBusProvider),
                cellSizePx: _currentRegion.cellSize.toDouble(),
                narrow: isNarrow,
              ),
            );
          },
        ),
        // Players bar paints below the news feed card so an open feed card is
        // never obscured by player chips (mockup z-order: news card 7 > players
        // bar 5; issue #2861 M4). Keep this child earlier in the stack than the
        // feed cards below.
        if (!isNarrow &&
            widget.game.victory == null &&
            _mapViewState.showPlayersBar)
          GameMapPlayersBar(
            game: widget.game,
            highlightPlayerId: shell.inObservePhase && shell.viewingPlayerId == null
                ? null
                : shell.viewingPlayerId ?? shell.effectiveHumanPlayerId,
          ),
        if (!isNarrow)
          Consumer(
            builder: (context, ref, _) {
              final panelOpen =
                  ref.watch(mapProvincePanelProvider).overlayOpen;
              final rightInset = gameMapWideOverlayRightInset(
                provincePanelOpen: panelOpen,
              );
              if (!shell.showPlayerChrome ||
                  !_mapViewState.showPlayerTurnEventsFeed) {
                return const SizedBox.shrink();
              }
              return Positioned(
                right: rightInset,
                top: 56,
                child: PlayerTurnEventFeedCard(
                  entries: feedEntries,
                  emptyLabel: 'No player events last turn.',
                ),
              );
            },
          ),
        if (isNarrow &&
            widget.game.victory == null &&
            (_mapViewState.showPlayersBar ||
                (shell.showPlayerChrome &&
                    _mapViewState.showPlayerTurnEventsFeed)))
          Positioned(
            right: kMapOverlayEdgeInset,
            top: 56,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (shell.showPlayerChrome &&
                    _mapViewState.showPlayerTurnEventsFeed)
                  PlayerTurnEventFeedCard(
                    entries: feedEntries,
                    emptyLabel: 'No player events last turn.',
                    narrow: true,
                  ),
                if (_mapViewState.showPlayersBar) ...[
                  if (shell.showPlayerChrome &&
                      _mapViewState.showPlayerTurnEventsFeed)
                    const SizedBox(
                      height: GameMapPlayersBar.narrowStackGap,
                    ),
                  GameMapPlayersBar(
                    game: widget.game,
                    highlightPlayerId:
                        shell.inObservePhase && shell.viewingPlayerId == null
                        ? null
                        : shell.viewingPlayerId ??
                            shell.effectiveHumanPlayerId,
                    embedded: true,
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
