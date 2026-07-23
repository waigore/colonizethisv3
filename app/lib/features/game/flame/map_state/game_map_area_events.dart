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
/// App-event-bus handlers for [GameMapArea]: filtering combat/diplomacy/
/// discovery/overture events to the viewing player and buffering them for the
/// turn-event feed, plus the turn-resolution-complete flush (Refs #3699 Theme
/// 3).
mixin GameMapAreaEvents
    on ConsumerState<GameMapArea>, GameMapAreaStateBase, GameMapAreaSelection {
  void onTurnResolutionCompleteEvent(
    ct_models.TurnResolutionCompleteEvent event,
  ) {
    if (event.gameId != widget.game.id || !mounted) {
      return;
    }
    setState(() {
      refreshWorkTargetSelectionCache(widget.game);
      resolvedPlayerTurnEvents = List<ct_models.GameToUIEvent>.from(
        pendingPlayerTurnEvents,
      );
      pendingPlayerTurnEvents.clear();
    });
  }

  void onAppCombatResultEvent(ct_models.AppCombatResultEvent event) {
    if (event.attackerId != mapPlayerId &&
        event.defenderId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppNavalCombatResultEvent(ct_models.AppNavalCombatResultEvent event) {
    if (event.side1OwnerId != mapPlayerId &&
        event.side2OwnerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppProvinceCapturedEvent(ct_models.AppProvinceCapturedEvent event) {
    if (event.previousOwnerId != mapPlayerId &&
        event.newOwnerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppDiplomacyChangeEvent(ct_models.AppDiplomacyChangeEvent event) {
    if (event.actorId != mapPlayerId && event.targetId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppResearchCompleteEvent(ct_models.AppResearchCompleteEvent event) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppOrderRejectedEvent(ct_models.AppOrderRejectedEvent event) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppWorkOrderCompletedEvent(
    ct_models.AppWorkOrderCompletedEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppPlayerProvinceDiscoveredEvent(
    ct_models.AppPlayerProvinceDiscoveredEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppPlayerSeaZoneDiscoveredEvent(
    ct_models.AppPlayerSeaZoneDiscoveredEvent event,
  ) {
    if (event.playerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppOvertureAdvancedEvent(ct_models.AppOvertureAdvancedEvent event) {
    if (event.offererGpId != mapPlayerId &&
        event.targetFactionId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppSpyCaughtEvent(ct_models.AppSpyCaughtEvent event) {
    if (event.spyOwnerId != mapPlayerId &&
        event.territoryOwnerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }

  void onAppSpyDefectedEvent(ct_models.AppSpyDefectedEvent event) {
    if (event.previousOwnerId != mapPlayerId &&
        event.newOwnerId != mapPlayerId) {
      return;
    }
    pendingPlayerTurnEvents.add(event);
  }
}
