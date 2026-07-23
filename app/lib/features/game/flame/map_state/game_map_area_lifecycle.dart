import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_debug_console/colonizethis_debug_console.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_map/colonizethis_map.dart' show RegionMapViewData;
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
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

import '../../../../config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
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

import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_view.dart';
import 'game_map_area_events.dart';

/// State lifecycle for [GameMapArea]: bus-subscription wiring in [initState],
/// observe-mode listeners, teardown in [dispose], and the per-game reset /
/// work-target refresh in [didUpdateWidget] (Refs #3699 Theme 3).
mixin GameMapAreaLifecycle
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaSelection,
        GameMapAreaView,
        GameMapAreaEvents {
  @override
  void initState() {
    super.initState();
    mapViewState = widget.game.mapViewState;
    refreshWorkTargetSelectionCache(widget.game);
    final bus = ref.read(appEventBusProvider);
    for (final subscription in [
      bus.on<ct_models.OpenProvinceDetailPanelEvent>().listen((_) {
        if (!mounted) return;
        setState(() {
          // Town icon tap will be handled by the province panel provider
        });
      }),
      bus.on<ct_models.LocateMapTileEvent>().listen(
        (e) => locateTile(e.tileKey, e.regionId),
      ),
      bus.on<ct_models.StartCivilianWorkTargetSelectionEvent>().listen(
        (e) => startWorkTargetSelection(e.unitId, e.workTarget),
      ),
      bus.on<ct_models.UnitsPanelClosedEvent>().listen((_) {
        ref.read(mapProvincePanelProvider.notifier).setSecondaryHighlight(null);
      }),
      bus.on<ct_models.OpenMapTileDetailEvent>().listen(
        (e) => openMapTileDetail(e.tileKey),
      ),
      bus.on<ct_models.AppCombatResultEvent>().listen(onAppCombatResultEvent),
      bus.on<ct_models.AppNavalCombatResultEvent>().listen(
        onAppNavalCombatResultEvent,
      ),
      bus.on<ct_models.AppProvinceCapturedEvent>().listen(
        onAppProvinceCapturedEvent,
      ),
      bus.on<ct_models.AppDiplomacyChangeEvent>().listen(
        onAppDiplomacyChangeEvent,
      ),
      bus.on<ct_models.AppResearchCompleteEvent>().listen(
        onAppResearchCompleteEvent,
      ),
      bus.on<ct_models.AppOrderRejectedEvent>().listen(
        onAppOrderRejectedEvent,
      ),
      bus.on<ct_models.AppWorkOrderCompletedEvent>().listen(
        onAppWorkOrderCompletedEvent,
      ),
      bus.on<ct_models.AppPlayerProvinceDiscoveredEvent>().listen(
        onAppPlayerProvinceDiscoveredEvent,
      ),
      bus.on<ct_models.AppPlayerSeaZoneDiscoveredEvent>().listen(
        onAppPlayerSeaZoneDiscoveredEvent,
      ),
      bus.on<ct_models.AppOvertureAdvancedEvent>().listen(
        onAppOvertureAdvancedEvent,
      ),
      bus.on<ct_models.AppSpyCaughtEvent>().listen(onAppSpyCaughtEvent),
      bus.on<ct_models.AppSpyDefectedEvent>().listen(onAppSpyDefectedEvent),
      bus.on<ct_models.TurnResolutionCompleteEvent>().listen(
        onTurnResolutionCompleteEvent,
      ),
      bus.on<ct_models.OpenDebugConsolePanelEvent>().listen((_) {
        if (!mounted || !ref.read(debugConsoleEnabledProvider)) return;
        setState(() => debugConsoleOpen = true);
      }),
      bus.on<ct_models.CloseDebugConsolePanelEvent>().listen((_) {
        if (!mounted) return;
        setState(() => debugConsoleOpen = false);
      }),
      bus.on<ct_models.ToggleDebugConsolePanelEvent>().listen((_) {
        if (!mounted || !ref.read(debugConsoleEnabledProvider)) return;
        setState(() => debugConsoleOpen = !debugConsoleOpen);
      }),
    ]) {
      busSubscriptions.track(subscription);
    }
    ref.listenManual(observeSessionProvider, (previous, next) {
      if (!mounted) return;
      final enteredObserve =
          next.isObserving && !(previous?.isObserving ?? false);
      final switchedMode =
          next.isObserving && previous?.mode != next.mode;
      if (enteredObserve || switchedMode) {
        cancelWorkTargetSelection();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeAutoCenterOnShellEntry();
    });
  }

  @override
  void dispose() {
    turnResolutionProgressSub?.cancel();
    turnResolutionProgressSub = null;
    busSubscriptions.cancelAll();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameMapArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      ref.read(mapProvincePanelProvider.notifier).reset();
      ref.read(regionMinimapVisibleProvider.notifier).reset();
      setState(() {
        refreshWorkTargetSelectionCache(widget.game);
        mapViewState = widget.game.mapViewState;
        regionViewportSnapshot = null;
        pendingRegionViewport = null;
        regionViewportFrameScheduled = false;
        didAutoCenterOnEntry = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        maybeAutoCenterOnShellEntry();
      });
    } else if (oldWidget.game.mapViewState != widget.game.mapViewState) {
      mapViewState = widget.game.mapViewState;
    }
    if (oldWidget.game.worldState.turnState.turnNumber !=
        widget.game.worldState.turnState.turnNumber) {
      setState(() {
        refreshWorkTargetSelectionCache(widget.game);
      });
    }
  }
}
