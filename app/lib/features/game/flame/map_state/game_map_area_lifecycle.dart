
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

import '../../../../providers/app_event_bus_provider.dart';
import '../../../../providers/debug_console_provider.dart';
import '../../../../providers/observe_session_provider.dart';
import '../../../../providers/map_province_panel_provider.dart';
import '../../../../providers/region_minimap_provider.dart';
import '../../../../providers/games_provider.dart';

import 'game_map_area.dart';
import 'game_map_area_state_base.dart';
import 'game_map_area_selection.dart';
import 'game_map_area_relocate_selection.dart';
import 'game_map_area_view.dart';
import 'game_map_area_events.dart';
import 'game_map_area_last_turn_playback.dart';

/// State lifecycle for [GameMapArea]: bus-subscription wiring in [initState],
/// observe-mode listeners, teardown in [dispose], and the per-game reset /
/// work-target refresh in [didUpdateWidget] (Refs #3699 Theme 3).
mixin GameMapAreaLifecycle
    on
        ConsumerState<GameMapArea>,
        GameMapAreaStateBase,
        GameMapAreaSelection,
        GameMapAreaRelocateSelection,
        GameMapAreaView,
        GameMapAreaEvents,
        GameMapAreaLastTurnPlayback {
  @override
  void initState() {
    super.initState();
    mapViewState = widget.game.mapViewState;
    refreshMapSuggestionCaches(widget.game);
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
      bus.on<ct_models.StartCivilianRelocateSelectionEvent>().listen(
        (e) => startCivilianRelocateSelection(e.unitId),
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
      bus.on<ct_models.AppOverseasProfitCreditedEvent>().listen(
        onAppOverseasProfitCreditedEvent,
      ),
      bus.on<ct_models.AppMarketTurnSummaryEvent>().listen(
        onAppMarketTurnSummaryEvent,
      ),
      bus.on<ct_models.AppEconomyTurnSummaryEvent>().listen(
        onAppEconomyTurnSummaryEvent,
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
      bus.on<ct_models.AppGeneralMedalGainedEvent>().listen(
        onAppGeneralMedalGainedEvent,
      ),
      bus.on<ct_models.TurnResolutionCompleteEvent>().listen(
        onTurnResolutionCompleteEvent,
      ),
      bus.on<ct_models.TurnNewsDialogClosedEvent>().listen(
        onTurnNewsDialogClosedEvent,
      ),
      bus.on<ct_models.VictoryOverlayViewFinalStateEvent>().listen(
        onVictoryOverlayViewFinalStateEvent,
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
        cancelAnyMapTileSelection();
      }
    });
    ref.listenManual(currentOrdersProvider, (previous, next) {
      if (!mounted) return;
      if (identical(previous, next)) return;
      refreshArmyMovePickerCache(widget.game);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      maybeAutoCenterOnShellEntry();
    });
  }

  @override
  void dispose() {
    disposeLastTurnPlayback();
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
        refreshMapSuggestionCaches(widget.game);
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
        refreshMapSuggestionCaches(widget.game);
      });
    }
  }
}
