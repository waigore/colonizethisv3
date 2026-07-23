import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData, RegionMapViewData;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import '../../../../config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../screens/game/game_screen_shared.dart';
import '../map_area/map_area.dart'
    show GameMapAreaBackground, GameMapCanvasStack;
import '../controls/controls.dart';
import '../minimap/minimap.dart';
import '../overlays/game_map_narrow_detail_overlay.dart';
import '../overlays/debug_console_overlay_panel.dart';
import 'game_map_area_state_logic.dart';
import '../overlays/next_turn_confirmation_dialog.dart';
import '../overlays/turn_resolution_processing_dialog.dart';
import '../overlays/turn_resolution_progress_labels.dart';
import '../../../../core/services/turn_resolution/turn_resolution_result_applier.dart';
import 'map_location_resolver.dart';
import '../../widgets/dialogs/game_map_options_dialog.dart';
import '../../widgets/shell/game_map_players_bar.dart';
import '../../widgets/shell/player_turn_event_feed.dart';
import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/debug_console_provider.dart';
import '../../../../core/services/game_service/game_service.dart'
    show GameMapData, GameService;
import '../../../../providers/game_service_provider.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/observe_session_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../../../providers/region_minimap_provider.dart';
import '../../../../providers/treasury_summary_provider.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../region_map/region_map_component.dart' show BaseLayerDisplayMode;
import '../../../../providers/blessed_ai_profiles_provider.dart';
import '../../../../providers/turn_resolution_blocking_provider.dart';
import '../../../../providers/turn_resolution_runner_provider.dart';
import '../../../../core/services/ai/ai_profile_resolution.dart';
import '../../../../core/services/subscription_tracker.dart';
import '../../../../core/services/turn_resolution/turn_resolution_blocking_service.dart';
import '../../../../core/services/turn_resolution/turn_resolution_runner.dart';
import '../region_map/region_map_viewport_snapshot.dart';
import '../../../../providers/home_fleet_cargo_provider.dart';
import '../../../../providers/human_draft_projected_region_provider.dart';

import 'game_map_area_state_base.dart';
import 'game_map_area_widget.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_view.dart';
import 'game_map_area_turn_resolution.dart';
import 'game_map_area_turn_feed.dart';
import 'game_map_area_e2e.dart';
import 'game_map_area_build_overlays.dart';
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
        shell.playerView ?? buildPlayerView(widget.game, mapTopology, mapPlayerId);
    final l10n = appL10n(context);
    final projectedRegion = ref.watch(
          humanDraftProjectedRegionProvider(currentRegion.regionId),
        ) ??
        currentRegion;
    final turnNumber = widget.game.worldState.turnState.turnNumber;
    final year = turnToYear(turnNumber, widget.game.turnTimeMapping);
    final nextTurnText = shell.inObservePhase
        ? 'Observe — Turn $turnNumber ($year)'
        : l10n.game_nextTurnButton(turnNumber, year);
    final turnDisplayText = l10n.game_turnDisplay(turnNumber, year);
    final cargoSummary = ref.watch(homeFleetCargoSummaryProvider);
    final treasurySummary = ref.watch(treasurySummaryProvider);
    final feedEntries = resolveFeedEntries();
    final debugConsoleEnabled = ref.watch(debugConsoleEnabledProvider);
    return Column(
      children: [
        GameMapControls(
          sideMenuOpen: sideMenuOpen,
          onToggleSideMenu: () =>
              setState(() => sideMenuOpen = !sideMenuOpen),
          onPausePressed: isTurnResolving
              ? null
              : () => ref
                    .read(appEventBusProvider)
                    .emit(const ct_models.OpenPauseMenuPanelEvent()),
          onNextTurn: onNextTurn,
          nextTurnEnabled:
              !isTurnResolving &&
              GameMapAreaStateLogic.allowsFullTurnResolution(widget.game),
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
