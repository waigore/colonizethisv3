import 'package:flutter/material.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import '../../../providers/observe_session_provider.dart';
import '../widgets/game_top_bar.dart';
import '../widgets/game_tab_bar.dart';
import '../widgets/player_turn_event_feed.dart';

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
    this.isCargoUsedReliable = true,
    this.observeBannerLabel,
    this.treasuryNotDefined = false,
    this.cargoNotDefined = false,
    this.playerTurnEventsFeedNotDefined = false,
    super.key,
  });

  final bool sideMenuOpen;
  final VoidCallback onToggleSideMenu;
  final VoidCallback onPausePressed;
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
  final bool isCargoUsedReliable;
  final String? observeBannerLabel;
  final bool treasuryNotDefined;
  final bool cargoNotDefined;
  final bool playerTurnEventsFeedNotDefined;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final cargoHoldLabel = cargoNotDefined
        ? kObserveNotDefinedLabel
        : l10n.mapControls_cargoHold(
            isCargoUsedReliable ? '$cargoUsed' : '—',
            '$cargoCapacity',
          );

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
        GameTabBar(
          regionIndex: regionIndex,
          onRegionIndexChanged: onRegionIndexChanged,
          oldWorldLabel: l10n.region_oldWorld,
          newWorldLabel: l10n.region_newWorld,
          treasury: treasury,
          treasuryDelta: treasuryDelta,
          treasuryNotDefined: treasuryNotDefined,
          treasuryObserveLabel: kObserveNotDefinedLabel,
          cargoUsed: cargoUsed,
          cargoCapacity: cargoCapacity,
          cargoNotDefined: cargoNotDefined,
          isCargoUsedReliable: isCargoUsedReliable,
          cargoHoldLabel: cargoHoldLabel,
          trailing: playerTurnEventsFeedNotDefined
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    kObserveNotDefinedLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : PlayerTurnEventsFeedToggleButton(
                  eventCount: playerTurnEventsFeedCount,
                  tooltip: l10n.playerTurnFeed_eventsChip(
                    playerTurnEventsFeedCount,
                  ),
                  showFeed: showPlayerTurnEventsFeed,
                  onPressed: onTogglePlayerTurnEventsFeed,
                ),
        ),
      ],
    );
  }
}
