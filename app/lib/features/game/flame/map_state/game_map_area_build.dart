part of 'game_map_area.dart';

/// View composition for [GameMapArea]: the controls bar and play-area stack
/// delegating map overlays to [_GameMapAreaBuildOverlays] (Refs #3699 Theme 3).
mixin _GameMapAreaBuild
    on
        ConsumerState<GameMapArea>,
        _GameMapAreaStateBase,
        _GameMapAreaView,
        _GameMapAreaSelection,
        _GameMapAreaTurnResolution,
        _GameMapAreaTurnFeed,
        _GameMapAreaE2e,
        _GameMapAreaBuildOverlays {
  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final mapTopology = widget.mapViewData.combinedTopology;
    final shell = ref.watch(shellPlayerContextProvider);
    final mapPlayerId = shell.mapPlayerIdFor(widget.game);
    final mapPlayerView =
        shell.playerView ?? buildPlayerView(widget.game, mapTopology, mapPlayerId);
    final l10n = appL10n(context);
    final projectedRegion = ref.watch(
          humanDraftProjectedRegionProvider(_currentRegion.regionId),
        ) ??
        _currentRegion;
    final turnNumber = widget.game.worldState.turnState.turnNumber;
    final year = turnToYear(turnNumber, widget.game.turnTimeMapping);
    final nextTurnText = shell.inObservePhase
        ? 'Observe — Turn $turnNumber ($year)'
        : l10n.game_nextTurnButton(turnNumber, year);
    final turnDisplayText = l10n.game_turnDisplay(turnNumber, year);
    final cargoSummary = ref.watch(homeFleetCargoSummaryProvider);
    final treasurySummary = ref.watch(treasurySummaryProvider);
    final feedEntries = _feedEntries();
    final debugConsoleEnabled = ref.watch(debugConsoleEnabledProvider);
    return Column(
      children: [
        GameMapControls(
          sideMenuOpen: _sideMenuOpen,
          onToggleSideMenu: () =>
              setState(() => _sideMenuOpen = !_sideMenuOpen),
          onPausePressed: _isTurnResolving
              ? null
              : () => ref
                    .read(appEventBusProvider)
                    .emit(const ct_models.OpenPauseMenuPanelEvent()),
          onNextTurn: _onNextTurn,
          nextTurnEnabled:
              !_isTurnResolving &&
              GameMapAreaStateLogic.allowsFullTurnResolution(widget.game),
          regionIndex: _regionIndex,
          onRegionIndexChanged: (i) =>
              setState(() => _regionIndex = i == 0 ? 0 : 1),
          turnDisplayText: turnDisplayText,
          nextTurnText: nextTurnText,
          cargoUsed: cargoSummary.used,
          cargoCapacity: cargoSummary.capacity,
          isCargoUsedReliable: cargoSummary.isCargoUsedReliable,
          cargoNotDefined: cargoSummary.notDefined,
          treasury: treasurySummary.treasury,
          treasuryDelta: treasurySummary.projectedDelta,
          treasuryNotDefined: treasurySummary.notDefined,
          observeBannerLabel: shell.observeBannerLabel,
          playerTurnEventsFeedCount: feedEntries.length,
          playerTurnEventsFeedNotDefined: !shell.showPlayerChrome,
          showPlayerTurnEventsFeed: _mapViewState.showPlayerTurnEventsFeed,
          onTogglePlayerTurnEventsFeed: _togglePlayerTurnEventsFeedVisibility,
          showPlayersBar: _mapViewState.showPlayersBar,
          onTogglePlayersBar: _togglePlayersBarVisibility,
        ),
        Expanded(
          child: _buildMapPlayAreaStack(
            context: context,
            isNarrow: isNarrow,
            projectedRegion: projectedRegion,
            mapPlayerId: mapPlayerId,
            mapPlayerView: mapPlayerView,
            shell: shell,
            feedEntries: feedEntries,
            debugConsoleEnabled: debugConsoleEnabled,
          ),
        ),
      ],
    );
  }
}
