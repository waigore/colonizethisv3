import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show buildPlayerView;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/game/flame/caches/per_player_army_move_picker_cache.dart';
import '../../../features/game/flame/map_state/province_army_move_home_army.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import '../../../features/game/widgets/unit_orders/army_stack_marker_action.dart';
import '../../../features/game/widgets/unit_orders/home_army_detach_then_move_flow.dart';
import '../../../features/game/widgets/unit_orders/naval_mission_flow.dart';
import '../../../features/game/widgets/unit_orders/overlay_army_move_flow.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../providers/home_fleet_cargo_provider.dart';
import '../observe/observe_mode_session_handler.dart';
import 'app_event_handler.dart';
import 'app_event_handler_unit_panels.dart';

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
  if (_rejectObserveMutation(handler, shell)) return;
  final game = container.read(currentGameProvider);
  if (game == null) return;
  final humanPlayerId = resolveShellPanelPlayerId(shell, game);
  final mapData = container.read(gameServiceProvider).getMapData(game.id);
  final draftOrders = container.read(currentOrdersProvider);
  final cargo = container.read(homeFleetCargoSummaryProvider);
  await showNavalFleetMarkerFlow(
    context: ctx,
    game: game,
    topology: mapData?.combinedTopology ?? const MapTopology(),
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    bus: container.read(appEventBusProvider),
    fleetIds: event.fleetIds,
    locationScopeKey: event.locationScopeKey,
    preselectedFleetId: event.initialSelectedFleetId,
    tileScopeTileKey: event.tileScopeTileKey,
    overseasCargoUsed: cargo.used,
    isCargoUsedReliable: cargo.isCargoUsedReliable,
    cargoNotDefined: cargo.notDefined,
  );
}

Future<void> appEventHandlerOpenArmyStackMarker(
  AppEventHandler handler,
  OpenArmyStackMarkerEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) return;
  final ctx = nav.context;
  if (!ctx.mounted) return;
  final container = ProviderScope.containerOf(ctx);
  final shell = container.read(shellPlayerContextProvider);
  if (_rejectObserveMutation(handler, shell)) return;
  final game = container.read(currentGameProvider);
  if (game == null) return;
  final humanPlayerId = resolveShellPanelPlayerId(shell, game);
  final mapData = container.read(gameServiceProvider).getMapData(game.id);
  final topology = mapData?.combinedTopology ?? const MapTopology();
  final draftOrders = container.read(currentOrdersProvider);
  final cache = PerPlayerArmyMovePickerCache();
  cache.refresh(
    ArmyMovePickerSnapshot(
      game: game,
      playerId: humanPlayerId,
      playerView: buildPlayerView(game, topology, humanPlayerId),
      topology: topology,
      currentOrders: draftOrders,
    ),
  );
  final home = humanHomeArmy(game, humanPlayerId);
  final action = resolveArmyStackMarkerAction(
    canMutateViaUi: true,
    fieldArmyIds: event.fieldArmyIds,
    stackHasNonEmptyHomeArmy:
        home != null &&
        home.regimentUnitIds.isNotEmpty &&
        event.armyIds.contains(home.id),
    fieldArmyIdsWithDestinations: cache.stationedFieldArmyIdsWithDestinations(
      humanPlayerId,
      event.provinceId,
      game,
    ),
  );
  switch (action.kind) {
    case ArmyStackMarkerKind.observeBlocked:
      return;
    case ArmyStackMarkerKind.openMilitaryRoster:
      await appEventHandlerOpenMilitaryUnitsPanel(
        handler,
        const OpenMilitaryUnitsPanelEvent(),
        nav,
      );
      return;
    case ArmyStackMarkerKind.overlayMove:
      if (!ctx.mounted) return;
      await showOverlayArmyMoveFlow(
        context: ctx,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        bus: container.read(appEventBusProvider),
        armyIds: action.moveArmyIds,
      );
      return;
    case ArmyStackMarkerKind.detachThenMove:
      if (!ctx.mounted) return;
      await showHomeArmyDetachThenMoveFlow(
        context: ctx,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        bus: container.read(appEventBusProvider),
      );
  }
}

bool _rejectObserveMutation(
  AppEventHandler handler,
  ShellPlayerContext shell,
) => rejectUiMutationIfObserving(
  shell: shell,
  showSnack: (event) => handler.state.onShowSnackBar?.call(event),
);
