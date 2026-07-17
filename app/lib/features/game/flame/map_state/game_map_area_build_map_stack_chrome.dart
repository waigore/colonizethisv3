part of 'game_map_area.dart';

/// Minimap, players bar, and turn-feed overlay chrome for the map stack.
mixin _GameMapAreaBuildMapStackChrome
    on
        ConsumerState<GameMapArea>,
        _GameMapAreaStateBase,
        _GameMapAreaView,
        _GameMapAreaSelection,
        _GameMapAreaE2e {
  List<Widget> _buildMapStackChromeChildren({
    required bool isNarrow,
    required RegionMapViewData projectedRegion,
    required String mapPlayerId,
    required ShellPlayerContext shell,
    required List<PlayerTurnEventFeedEntry> feedEntries,
  }) {
    return [
      Consumer(
        builder: (context, ref, _) {
          final panelOpen = ref.watch(
            mapProvincePanelProvider.select((s) => s.overlayOpen),
          );
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
            final panelOpen = ref.watch(
              mapProvincePanelProvider.select((s) => s.overlayOpen),
            );
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
                      : shell.viewingPlayerId ?? shell.effectiveHumanPlayerId,
                  embedded: true,
                ),
              ],
            ],
          ),
        ),
    ];
  }
}
