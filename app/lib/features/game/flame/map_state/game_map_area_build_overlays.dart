part of 'game_map_area.dart';

/// Map play-area shell (keyboard focus, debug console, narrow detail slot).
/// Split from [game_map_area_build.dart] for Phase 3 flame map modularization.
mixin _GameMapAreaBuildOverlays
    on
        ConsumerState<GameMapArea>,
        _GameMapAreaStateBase,
        _GameMapAreaView,
        _GameMapAreaSelection,
        _GameMapAreaE2e,
        _GameMapAreaBuildMapStack {
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
}
