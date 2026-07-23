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
import 'game_map_area_turn_feed_labels.dart';
/// Player turn-event feed for [GameMapArea]: turning resolved `GameToUIEvent`s
/// into tappable feed entries (Refs #3699 Theme 3).
mixin GameMapAreaTurnFeed
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaTurnFeedLabels {
  List<PlayerTurnEventFeedEntry> resolveFeedEntries() {
    return resolvedPlayerTurnEvents
        .map((event) {
          return switch (event) {
            ct_models.AppCombatResultEvent(
              :final provinceId,
              :final winnerId,
              :final attackerId,
              :final defenderId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${provinceLabel(provinceId)} battle resolved! ${factionLabel(winnerId)} defeated ${factionLabel(winnerId == attackerId ? defenderId : attackerId)}!',
                onTap: () => locateProvinceById(provinceId),
              ),
            ct_models.AppProvinceCapturedEvent(
              :final provinceId,
              :final newOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${provinceLabel(provinceId)} captured! ${factionLabel(newOwnerId)} now controls it!',
                onTap: () => locateProvinceById(provinceId),
              ),
            ct_models.AppNavalCombatResultEvent(
              :final seaZoneId,
              :final outcomeName,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${seaZoneLabel(seaZoneId)} naval battle resolved! Outcome: $outcomeName!',
                onTap: () => locateSeaZoneTile(seaZoneId),
              ),
            ct_models.AppDiplomacyChangeEvent(
              :final actorId,
              :final targetId,
              :final changeType,
            ) =>
              PlayerTurnEventFeedEntry(
                text: diplomacyOutcomeLine(
                  actorId: actorId,
                  targetId: targetId,
                  changeType: changeType,
                ),
              ),
            ct_models.AppResearchCompleteEvent(:final techId) =>
              PlayerTurnEventFeedEntry(
                text: 'Research complete! $techId unlocked!',
              ),
            ct_models.AppOrderRejectedEvent(:final reasonCode) =>
              PlayerTurnEventFeedEntry(
                text: 'Order rejected! Reason: $reasonCode!',
              ),
            ct_models.AppWorkOrderCompletedEvent(
              :final workTarget,
              :final targetTileKey,
              :final provinceId,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    '${provinceLabel(provinceId)} work completed! ${workTarget.toUpperCase()} finished!',
                onTap: () => locateTileKey(targetTileKey),
              ),
            ct_models.AppPlayerProvinceDiscoveredEvent(:final provinceId) =>
              PlayerTurnEventFeedEntry(
                text: '${provinceLabel(provinceId)} discovered!',
                onTap: () => locateProvinceById(provinceId),
              ),
            ct_models.AppPlayerSeaZoneDiscoveredEvent(:final seaZoneId) =>
              PlayerTurnEventFeedEntry(
                text: '${seaZoneLabel(seaZoneId)} discovered!',
                onTap: () => locateSeaZoneTile(seaZoneId),
              ),
            ct_models.AppOvertureAdvancedEvent(
              :final offererGpId,
              :final targetFactionId,
              :final newStage,
            ) =>
              PlayerTurnEventFeedEntry(
                text:
                    'Overture advanced! ${factionLabel(offererGpId)} with ${factionLabel(targetFactionId)}: ${newStage.toUpperCase()}!',
              ),
            ct_models.AppSpyCaughtEvent(
              :final provinceId,
              :final spyOwnerId,
              :final territoryOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text: mapPlayerId == territoryOwnerId
                    ? '${provinceLabel(provinceId)} — enemy spy from ${factionLabel(spyOwnerId)} caught and eliminated!'
                    : 'Spy caught in ${provinceLabel(provinceId)}! ${factionLabel(territoryOwnerId)} eliminated your agent!',
                onTap: () => locateProvinceById(provinceId),
              ),
            ct_models.AppSpyDefectedEvent(
              :final provinceId,
              :final previousOwnerId,
              :final newOwnerId,
            ) =>
              PlayerTurnEventFeedEntry(
                text: mapPlayerId == newOwnerId
                    ? '${provinceLabel(provinceId)} — enemy spy from ${factionLabel(previousOwnerId)} defected to your side!'
                    : 'Spy defected in ${provinceLabel(provinceId)}! Agent joined ${factionLabel(newOwnerId)}!',
                onTap: () => locateProvinceById(provinceId),
              ),
            _ => const PlayerTurnEventFeedEntry(text: 'Event resolved!'),
          };
        })
        .toList(growable: false);
  }
}
