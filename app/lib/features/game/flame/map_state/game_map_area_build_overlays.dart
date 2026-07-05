part of 'game_map_area.dart';

/// Map canvas stack and in-map overlay chrome for [GameMapArea] (left rail,
/// corner controls, side menu, minimap, players bar, turn feed, E2E taps).
/// Split from [game_map_area_build.dart] for Phase 3 flame map modularization.
mixin _GameMapAreaBuildOverlays
    on
        ConsumerState<GameMapArea>,
        _GameMapAreaStateBase,
        _GameMapAreaView,
        _GameMapAreaSelection,
        _GameMapAreaE2e {
  Widget _buildMapPlayAreaStack({
    required BuildContext context,
    required bool isNarrow,
    required RegionMapViewData projectedRegion,
    required String mapPlayerId,
    required PlayerView mapPlayerView,
    required ShellPlayerContext shell,
    required List<PlayerTurnEventFeedEntry> feedEntries,
    required bool debugConsoleEnabled,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _isTurnResolving,
            child: Focus(
              autofocus: true,
              onKeyEvent: (node, event) {
                if (_workTargetSelection != null &&
                    event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  _cancelWorkTargetSelection();
                  return KeyEventResult.handled;
                }
                if (_sideMenuOpen &&
                    event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  setState(() => _sideMenuOpen = false);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: _buildMapFocusedStack(
                context: context,
                isNarrow: isNarrow,
                projectedRegion: projectedRegion,
                mapPlayerId: mapPlayerId,
                mapPlayerView: mapPlayerView,
                shell: shell,
                feedEntries: feedEntries,
              ),
            ),
          ),
        ),
        if (debugConsoleEnabled && _debugConsoleOpen)
          Positioned(
            left: kEdgeSwipeStripWidth + 60,
            top: 56,
            child: DebugConsoleOverlayPanel(
              bus: ref.read(appEventBusProvider),
              humanPlayerId: _debugConsolePlayerId ?? mapPlayerId,
              readOnlyContextProvider: () {
                final selectedTileKey =
                    ref.read(mapProvincePanelProvider).selectedTileKey;
                final players = widget.game.players
                    .map(
                      (p) => DebugConsolePlayerSnapshot(
                        id: p.id,
                        displayName: p.displayName,
                        isHuman: p.isHuman,
                        capitalProvinceId: p.capitalProvinceId,
                      ),
                    )
                    .toList(growable: false);
                return DebugConsoleReadOnlyContext(
                  selectedTileKey: selectedTileKey,
                  players: players,
                );
              },
              onClose: () => setState(() => _debugConsoleOpen = false),
            ),
          ),
        if (isNarrow)
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameMapNarrowDetailOverlaySlot(
                  game: widget.game,
                  region: projectedRegion,
                  humanPlayerId: mapPlayerId,
                  playerView: mapPlayerView,
                  omniscientDetail: shell.omniscientDetail,
                  canMutateViaUi: shell.canMutateViaUi,
                  workTargetSelectionCache: _workTargetSelectionCache,
                ),
              ],
            ),
          ),
      ],
    );
  }

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

  List<Widget> _buildE2eOverlayTaps(RegionMapViewData projectedRegion) {
    return [
      Positioned(
        right: kMapOverlayEdgeInset,
        top: kMapOverlayEdgeInset,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: kCtE2EOpenCapitalProvinceDetailKey,
              onTap: _e2eOpenHumanCapitalTileDetail,
            ),
          ),
        ),
      ),
      if (_workTargetSelection != null &&
          _cachedValidTileKeys != null &&
          _cachedValidTileKeys!.isNotEmpty)
        Positioned(
          right: kMapOverlayEdgeInset,
          top: kMapOverlayEdgeInset + 48,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: kCtE2ESelectFirstValidWorkTileKey,
                onTap: _e2eSelectFirstValidWorkTargetTile,
              ),
            ),
          ),
        ),
      if (projectedRegion.civilianTileMarkers.isNotEmpty)
        Positioned(
          right: kMapOverlayEdgeInset,
          top: kMapOverlayEdgeInset + 96,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: kCtE2EOpenFirstCivilianMarkerPanelKey,
                onTap: _e2eOpenFirstCivilianMarkerPanel,
              ),
            ),
          ),
        ),
      if (projectedRegion.fleetTileMarkers.isNotEmpty)
        Positioned(
          right: kMapOverlayEdgeInset,
          top: kMapOverlayEdgeInset + 144,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: kCtE2EOpenFirstFleetMarkerPanelKey,
                onTap: _e2eOpenFirstFleetMarkerPanel,
              ),
            ),
          ),
        ),
    ];
  }
}
