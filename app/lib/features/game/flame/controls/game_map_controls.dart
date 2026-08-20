import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import '../../../../providers/observe_session_provider.dart';
import '../../widgets/shell/game_top_bar.dart';
import '../../widgets/shell/game_tab_bar.dart';
import '../../widgets/shell/player_turn_event_feed.dart';
import '../../widgets/shell/players_bar_toggle_button.dart';

/// Top bar and tab bar for the in-game map shell.
///
/// Hosts [GameTopBar] (36 px) and [GameTabBar] (34 px) per issue #2861 S1/S2.
class GameMapControls extends StatelessWidget {
  const GameMapControls({
    required this.sideMenuOpen,
    required this.onToggleSideMenu,
    required this.onPausePressed,
    required this.onNextTurn,
    required this.nextTurnEnabled,
    required this.regionIndex,
    required this.onRegionIndexChanged,
    required this.turnDisplayText,
    required this.nextTurnText,
    required this.cargoUsed,
    required this.cargoCapacity,
    required this.treasury,
    required this.treasuryDelta,
    required this.playerTurnEventsFeedCount,
    required this.showPlayerTurnEventsFeed,
    required this.onTogglePlayerTurnEventsFeed,
    required this.showPlayersBar,
    required this.onTogglePlayersBar,
    this.isCargoUsedReliable = true,
    this.observeBannerLabel,
    this.treasuryNotDefined = false,
    this.treasuryCommittedLines = const [],
    this.cargoNotDefined = false,
    this.playerTurnEventsFeedNotDefined = false,
    this.oldWorldRace,
    this.onOldWorldRaceTap,
    this.oldWorldRaceNarrow = false,
    this.showLabourFeedingIndicator = false,
    this.labourFeedingLabel = '—',
    this.labourFeedingNotDefined = false,
    this.labourReadiness,
    this.forcesFeeding,
    super.key,
  });

  final bool sideMenuOpen;
  final VoidCallback onToggleSideMenu;
  final VoidCallback? onPausePressed;
  final Future<void> Function() onNextTurn;
  final bool nextTurnEnabled;
  final int regionIndex;
  final void Function(int index) onRegionIndexChanged;
  final String turnDisplayText;
  final String nextTurnText;
  final int cargoUsed;
  final int cargoCapacity;
  final int treasury;
  final int? treasuryDelta;
  final int playerTurnEventsFeedCount;
  final bool showPlayerTurnEventsFeed;
  final VoidCallback onTogglePlayerTurnEventsFeed;
  final bool showPlayersBar;
  final VoidCallback onTogglePlayersBar;
  final bool isCargoUsedReliable;
  final String? observeBannerLabel;
  final bool treasuryNotDefined;
  final List<TreasuryCommittedSpendLine> treasuryCommittedLines;
  final bool cargoNotDefined;
  final bool playerTurnEventsFeedNotDefined;
  final OldWorldRaceSnapshot? oldWorldRace;
  final VoidCallback? onOldWorldRaceTap;
  final bool oldWorldRaceNarrow;
  final bool showLabourFeedingIndicator;
  final String labourFeedingLabel;
  final bool labourFeedingNotDefined;
  final LabourReadinessSnapshot? labourReadiness;
  final ForceFeedingSnapshot? forcesFeeding;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return Column(
      children: [
        GameTopBar(
          onToggleSideMenu: onToggleSideMenu,
          onPausePressed: onPausePressed,
          onNextTurn: onNextTurn,
          nextTurnEnabled: nextTurnEnabled,
          turnDisplayText: turnDisplayText,
          nextTurnText: nextTurnText,
          menuTooltip: l10n.gameMap_menuTooltip,
          pauseTooltip: l10n.game_pauseMenu_tooltip,
          observeBannerLabel: observeBannerLabel,
        ),
        _GameMapControlsTabBar(parent: this),
      ],
    );
  }
}

/// Tab-bar host extracted so [GameMapControls.build] stays under the
/// `widget_build_method_too_long` budget (Refs #4560).
class _GameMapControlsTabBar extends StatelessWidget {
  const _GameMapControlsTabBar({required this.parent});

  final GameMapControls parent;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final cargoHoldLabel = parent.cargoNotDefined
        ? kObserveNotDefinedLabel
        : l10n.mapControls_cargoHold(
            parent.isCargoUsedReliable ? '${parent.cargoUsed}' : '—',
            '${parent.cargoCapacity}',
          );

    return GameTabBar(
      regionIndex: parent.regionIndex,
      onRegionIndexChanged: parent.onRegionIndexChanged,
      oldWorldLabel: l10n.region_oldWorld,
      newWorldLabel: l10n.region_newWorld,
      treasury: parent.treasury,
      treasuryDelta: parent.treasuryDelta,
      treasuryNotDefined: parent.treasuryNotDefined,
      treasuryObserveLabel: kObserveNotDefinedLabel,
      treasuryCommittedLines: parent.treasuryCommittedLines,
      cargoUsed: parent.cargoUsed,
      cargoCapacity: parent.cargoCapacity,
      cargoNotDefined: parent.cargoNotDefined,
      isCargoUsedReliable: parent.isCargoUsedReliable,
      cargoHoldLabel: cargoHoldLabel,
      showLabourFeedingIndicator: parent.showLabourFeedingIndicator,
      labourFeedingLabel: parent.labourFeedingLabel,
      labourFeedingNotDefined: parent.labourFeedingNotDefined,
      labourReadiness: parent.labourReadiness,
      forcesFeeding: parent.forcesFeeding,
      oldWorldRace: parent.oldWorldRace,
      onOldWorldRaceTap: parent.onOldWorldRaceTap,
      oldWorldRaceNarrow: parent.oldWorldRaceNarrow,
      trailing: _GameMapControlsTabBarTrailing(
        playersBarToggleTooltip: l10n.mapControls_playersBarToggle,
        showPlayersBar: parent.showPlayersBar,
        onTogglePlayersBar: parent.onTogglePlayersBar,
        playerTurnEventsFeedNotDefined: parent.playerTurnEventsFeedNotDefined,
        playerTurnEventsFeedCount: parent.playerTurnEventsFeedCount,
        playerTurnEventsFeedTooltip: l10n.playerTurnFeed_eventsChip(
          parent.playerTurnEventsFeedCount,
        ),
        showPlayerTurnEventsFeed: parent.showPlayerTurnEventsFeed,
        onTogglePlayerTurnEventsFeed: parent.onTogglePlayerTurnEventsFeed,
      ),
    );
  }
}

class _GameMapControlsTabBarTrailing extends StatelessWidget {
  const _GameMapControlsTabBarTrailing({
    required this.playersBarToggleTooltip,
    required this.showPlayersBar,
    required this.onTogglePlayersBar,
    required this.playerTurnEventsFeedNotDefined,
    required this.playerTurnEventsFeedCount,
    required this.playerTurnEventsFeedTooltip,
    required this.showPlayerTurnEventsFeed,
    required this.onTogglePlayerTurnEventsFeed,
  });

  final String playersBarToggleTooltip;
  final bool showPlayersBar;
  final VoidCallback onTogglePlayersBar;
  final bool playerTurnEventsFeedNotDefined;
  final int playerTurnEventsFeedCount;
  final String playerTurnEventsFeedTooltip;
  final bool showPlayerTurnEventsFeed;
  final VoidCallback onTogglePlayerTurnEventsFeed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayersBarToggleButton(
          tooltip: playersBarToggleTooltip,
          showPlayersBar: showPlayersBar,
          onPressed: onTogglePlayersBar,
        ),
        const SizedBox(width: GameTabBar.clusterTrailingGap),
        if (playerTurnEventsFeedNotDefined)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              kObserveNotDefinedLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          PlayerTurnEventsFeedToggleButton(
            eventCount: playerTurnEventsFeedCount,
            tooltip: playerTurnEventsFeedTooltip,
            showFeed: showPlayerTurnEventsFeed,
            onPressed: onTogglePlayerTurnEventsFeed,
          ),
      ],
    );
  }
}
