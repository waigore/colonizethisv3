import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/debug_console_provider.dart';
import '../../../../providers/treasury_summary_provider.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../../../providers/home_fleet_cargo_provider.dart';
import '../../../../providers/human_draft_projected_region_provider.dart';

import '../../../../config/constants.dart';
import '../../../../config/routes.dart';
import '../controls/controls.dart';
import '../../widgets/shell/old_world_race_snapshot.dart';
import 'game_map_area_state_logic.dart';
import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_view.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_turn_resolution.dart';
import 'game_map_area_turn_feed.dart';
import 'game_map_area_e2e.dart';
import 'game_map_area_build_overlays.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/turn_time_api.dart';

/// View composition for [GameMapArea]: the controls bar and play-area stack
/// delegating map overlays to [GameMapAreaBuildOverlays] (Refs #3699 Theme 3).
mixin GameMapAreaBuild
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaView,
        GameMapAreaSelection,
        GameMapAreaTurnResolution,
        GameMapAreaTurnFeed,
        GameMapAreaE2e,
        GameMapAreaBuildOverlays {
  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final mapTopology = widget.mapViewData.combinedTopology;
    final shell = ref.watch(shellPlayerContextProvider);
    final mapPlayerId = shell.mapPlayerIdFor(widget.game);
    final mapPlayerView =
        shell.playerView ??
        buildPlayerView(widget.game, mapTopology, mapPlayerId);
    final l10n = appL10n(context);
    final projectedRegion =
        ref.watch(humanDraftProjectedRegionProvider(currentRegion.regionId)) ??
        currentRegion;
    final turnNumber = widget.game.worldState.turnState.turnNumber;
    final year = turnToYear(turnNumber, widget.game.turnTimeMapping);
    final nextTurnText = shell.inObservePhase
        ? 'Observe — Turn $turnNumber ($year)'
        : l10n.game_nextTurnButton(turnNumber, year);
    final turnDisplayText = l10n.game_turnDisplay(turnNumber, year);
    final cargoSummary = ref.watch(homeFleetCargoSummaryProvider);
    final treasurySummary = ref.watch(treasurySummaryProvider);
    final feedEntries = buildFeedEntries();
    final debugConsoleEnabled = ref.watch(debugConsoleEnabledProvider);
    final raceFocusId = widget.game.victory != null
        ? null
        : (shell.panelPlayerId ??
              OldWorldRaceSnapshot.leadingPlayerId(widget.game));
    final OldWorldRaceSnapshot? oldWorldRace = raceFocusId == null
        ? null
        : OldWorldRaceSnapshot.fromGame(
            game: widget.game,
            focusPlayerId: raceFocusId,
          );
    return Column(
      children: [
        GameMapControls(
          sideMenuOpen: sideMenuOpen,
          onToggleSideMenu: () => setState(() => sideMenuOpen = !sideMenuOpen),
          onPausePressed: isTurnResolving
              ? null
              : () => ref
                    .read(appEventBusProvider)
                    .emit(const ct_models.OpenPauseMenuPanelEvent()),
          onNextTurn: onNextTurn,
          nextTurnEnabled:
              !isTurnResolving &&
              GameMapAreaStateLogicShell.allowsFullTurnResolution(widget.game),
          regionIndex: regionIndex,
          onRegionIndexChanged: (i) =>
              setState(() => regionIndex = i == 0 ? 0 : 1),
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
          showPlayerTurnEventsFeed: mapViewState.showPlayerTurnEventsFeed,
          onTogglePlayerTurnEventsFeed: togglePlayerTurnEventsFeedVisibility,
          showPlayersBar: mapViewState.showPlayersBar,
          onTogglePlayersBar: togglePlayersBarVisibility,
          oldWorldRace: oldWorldRace,
          oldWorldRaceNarrow: isNarrow,
          onOldWorldRaceTap: oldWorldRace == null
              ? null
              : () => ref
                    .read(appEventBusProvider)
                    .emit(
                      ct_models.NavigateToRouteEvent(Routes.victory, {
                        'game': widget.game,
                        'humanPlayerId': mapPlayerId,
                      }),
                    ),
        ),
        Expanded(
          child: buildMapPlayAreaStack(
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
