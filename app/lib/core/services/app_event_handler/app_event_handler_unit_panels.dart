import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import '../../../features/game/widgets/shell/shell_player_guarded_body.dart';
import '../../../features/game/widgets/units/civilian/civilian_units_panel.dart';
import '../../../features/game/widgets/units/military/military_units_panel.dart';
import '../../../features/game/widgets/units/naval/naval_units_panel.dart';
import '../../../features/game/widgets/unit_orders/naval_mission_flow.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import 'app_event_handler.dart';
import 'app_event_handler_units_panel_sheet.dart';

Future<void> appEventHandlerOpenCivilianUnitsPanel(
  AppEventHandler handler,
  OpenCivilianUnitsPanelEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) return;
  await appEventHandlerShowUnitsPanelSheet(
    handler,
    nav: nav,
    panelKind: 'civilian',
    applyCivilianE2eHeightOverride: true,
    beforeClosedEvent: () {
      if (kCtE2EEnabled) {
        updateCtE2eCivilianPanelSnapshotIfEnabled(null);
      }
    },
    buildBody: (context, ref, game) {
      final shell = ref.read(shellPlayerContextProvider);
      final civilianOwnerIds = resolveCivilianMarkerOwnerIds(shell, game);
      final panelPlayerId = resolveShellPanelPlayerId(shell, game);
      final readOnly = !shell.canMutateViaUi;
      final currentOrders = ref.watch(currentOrdersProvider);
      final bus = ref.watch(appEventBusProvider);
      return (
        replacement: null,
        panel: CivilianUnitsPanel(
          game: game,
          humanPlayerId: panelPlayerId,
          civilianOwnerIds: civilianOwnerIds,
          bus: bus,
          readOnly: readOnly,
          currentOrders: currentOrders,
          tileScopeTileKey: event.tileScopeTileKey,
          initialSelectedUnitId: event.initialSelectedUnitId,
          explorerOnly: event.explorerOnly,
          builderOnly: event.builderOnly,
          engineerOnly: event.engineerOnly,
          merchantOnly: event.merchantOnly,
          prospectShortcutTargetTileKey: event.prospectShortcutTargetTileKey,
          exploreShortcutTargetTileKey: event.exploreShortcutTargetTileKey,
          buildImprovementShortcutTargetTileKey:
              event.buildImprovementShortcutTargetTileKey,
          buildRoadShortcutTargetTileKey:
              event.buildRoadShortcutTargetTileKey,
          buildFortShortcutTargetTileKey:
              event.buildFortShortcutTargetTileKey,
          buildPortShortcutTargetTileKey:
              event.buildPortShortcutTargetTileKey,
          purchaseLandShortcutTargetTileKey:
              event.purchaseLandShortcutTargetTileKey,
          upgradeTownShortcutTargetTileKey:
              event.upgradeTownShortcutTargetTileKey,
        ),
      );
    },
  );
}

Future<void> appEventHandlerOpenMilitaryUnitsPanel(
  AppEventHandler handler,
  OpenMilitaryUnitsPanelEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) return;
  await appEventHandlerShowUnitsPanelSheet(
    handler,
    nav: nav,
    panelKind: 'military',
    buildBody: (context, ref, game) {
      final shell = ref.read(shellPlayerContextProvider);
      final sentinel = observeNotDefinedSentinel(shell, 'Military Units');
      if (sentinel != null) {
        return (replacement: sentinel, panel: null);
      }
      final humanPlayerId = resolveShellPanelPlayerId(shell, game);
      final readOnly = !shell.canMutateViaUi;
      final bus = ref.watch(appEventBusProvider);
      final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
      final draftOrders = ref.watch(currentOrdersProvider);
      return (
        replacement: null,
        panel: MilitaryUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: bus,
          readOnly: readOnly,
          topology: mapData?.combinedTopology ?? const MapTopology(),
          draftOrders: draftOrders,
        ),
      );
    },
  );
}

Future<void> appEventHandlerOpenNavalUnitsPanel(
  AppEventHandler handler,
  OpenNavalUnitsPanelEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) return;
  await appEventHandlerShowUnitsPanelSheet(
    handler,
    nav: nav,
    panelKind: 'naval',
    // Keep the last naval snapshot after close for fleet E2E (Refs #2336).
    buildBody: (context, ref, game) {
      final shell = ref.read(shellPlayerContextProvider);
      final sentinel = observeNotDefinedSentinel(shell, 'Naval Units');
      if (sentinel != null) {
        return (replacement: sentinel, panel: null);
      }
      final humanPlayerId = resolveShellPanelPlayerId(shell, game);
      final readOnly = !shell.canMutateViaUi;
      final bus = ref.watch(appEventBusProvider);
      final mapData = ref.watch(gameServiceProvider).getMapData(game.id);
      final draftOrders = ref.watch(currentOrdersProvider);
      return (
        replacement: null,
        panel: NavalUnitsPanel(
          game: game,
          humanPlayerId: humanPlayerId,
          bus: bus,
          readOnly: readOnly,
          topology: mapData?.combinedTopology ?? const MapTopology(),
          draftOrders: draftOrders,
          tileMapByRegion: mapData?.tileMapByRegion,
          topologyByRegion: mapData?.topologyByRegion,
          locationScopeKey: event.locationScopeKey,
          initialSelectedFleetId: event.initialSelectedFleetId,
          tileScopeTileKey: event.tileScopeTileKey,
        ),
      );
    },
  );
}

Future<void> appEventHandlerOpenNavalMissionMenu(
  AppEventHandler handler,
  OpenNavalMissionMenuEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) return;
  final ctx = nav.context;
  if (!ctx.mounted) return;
  final container = ProviderScope.containerOf(ctx);
  final shell = container.read(shellPlayerContextProvider);
  if (!shell.canMutateViaUi) {
    handler.state.onShowSnackBar?.call(
      const ShowSnackBarEvent(
        message: 'Observe mode: UI actions are read-only.',
      ),
    );
    return;
  }
  final game = container.read(currentGameProvider);
  if (game == null) return;
  final humanPlayerId = resolveShellPanelPlayerId(shell, game);
  final mapData = container.read(gameServiceProvider).getMapData(game.id);
  final draftOrders = container.read(currentOrdersProvider);
  await showNavalMissionFlow(
    context: ctx,
    game: game,
    topology: mapData?.combinedTopology ?? const MapTopology(),
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    bus: container.read(appEventBusProvider),
    fleetIds: event.fleetIds,
    preselectedFleetId: event.initialSelectedFleetId,
  );
}
