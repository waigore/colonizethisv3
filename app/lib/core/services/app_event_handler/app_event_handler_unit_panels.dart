import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../config/routes.dart';
import '../../../features/game/screens/development/development_disconnected_assign_dialog.dart';
import '../../../features/game/flame/overlays/exit_confirm_dialog.dart';
import '../../../features/game/widgets/panels/pause_menu_panel.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import '../../../features/game/widgets/shell/shell_player_guarded_body.dart';
import '../../../features/game/widgets/units/civilian/civilian_units_panel.dart';
import '../../../features/game/widgets/units/military/military_units_panel.dart';
import '../../../features/game/widgets/units/naval/naval_units_panel.dart';
import '../../../features/game/widgets/unit_orders/naval_mission_flow.dart';
import '../../../features/game/widgets/units/shared/units_panel_sheet_surface.dart';
import '../../../features/game/widgets/units/shared/units_panel_viewport_constraints.dart';
import '../../../providers/app_event_bus_provider.dart';
import '../../../providers/game_service_provider.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_confirm_dialog.dart';
import '../game_session_clear.dart';
import 'app_event_handler.dart';

final _log = packageLogger('event');

const _observeBlockedDialogIds = {
  'train_civilians',
  'train_military',
  'grant_or_subsidy',
};

Future<void> appEventHandlerOpenDialog(
  AppEventHandler handler,
  OpenDialogEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) return;
  final state = handler.state;
  if (_observeBlockedDialogIds.contains(event.dialogId)) {
    final ctx = nav.context;
    final container = ProviderScope.containerOf(ctx);
    if (!container.read(shellPlayerContextProvider).canMutateViaUi) {
      state.onShowSnackBar?.call(
        const ShowSnackBarEvent(
          message: 'Observe mode: UI actions are read-only.',
        ),
      );
      return;
    }
  }
  final builder = state.dialogBuilders[event.dialogId];
  if (builder == null) {
    debugPrint('[AppEventHandler] No dialog builder for: ${event.dialogId}');
    return;
  }
  await showDialog<void>(
    context: nav.context,
    builder: (ctx) => builder(ctx, event.params),
  );
}

Future<bool> appEventHandlerShowConfirmDialog(
  AppEventHandler handler,
  ConfirmDialogEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) {
    event.result(false);
    return false;
  }
  try {
    final confirmed = await showCtConfirmDialog(
      nav.context,
      title: event.title,
      message: event.message,
      confirmLabel: event.confirmLabel,
      cancelLabel: event.cancelLabel,
    );
    event.result(confirmed);
    return confirmed;
  } catch (e, st) {
    _log.e('ConfirmDialog failed', error: e, stackTrace: st);
    event.result(false);
    return false;
  }
}

Future<void> appEventHandlerShowDevelopmentDisconnectedAssignDialog(
  AppEventHandler handler,
  DevelopmentDisconnectedAssignDialogEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) {
    event.result(DevelopmentDisconnectedAssignChoice.cancel);
    return;
  }
  try {
    final choice = await showDialog<DevelopmentDisconnectedAssignChoice>(
      context: nav.context,
      barrierDismissible: true,
      barrierColor: EditorialMonoclePalette.dialogScrim,
      builder: (ctx) => DevelopmentDisconnectedAssignDialog(
        roadFirstState: DevelopmentRoadFirstState(
          enabled: event.roadFirstEnabled,
          disabledReason: event.roadFirstDisabledReason,
        ),
      ),
    );
    event.result(choice ?? DevelopmentDisconnectedAssignChoice.cancel);
  } catch (e, st) {
    _log.e('DevelopmentDisconnectedAssignDialog failed', error: e, stackTrace: st);
    event.result(DevelopmentDisconnectedAssignChoice.cancel);
  }
}

Future<void> appEventHandlerOpenPanel(
  AppEventHandler handler,
  OpenPanelEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) return;
  final builder = handler.state.panelBuilders[event.panelId];
  if (builder == null) {
    debugPrint('[AppEventHandler] No panel builder for: ${event.panelId}');
    return;
  }
  await showModalBottomSheet<void>(
    context: nav.context,
    builder: (ctx) => builder(ctx, event.params),
  );
}

Future<void> appEventHandlerOpenPauseMenuPanel(
  AppEventHandler handler,
  OpenPauseMenuPanelEvent event,
  NavigatorState? nav,
) async {
  if (nav == null) return;
  await showDialog<void>(
    context: nav.context,
    useRootNavigator: true,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) => PauseMenuPanel(bus: handler.state.bus),
  );
}

void appEventHandlerRequestExitToMainMenuFlow(
  AppEventHandler handler,
  NavigatorState? nav,
) {
  if (nav == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final state = handler.state.navigatorKey.currentState;
    final ctx = state?.context;
    if (state == null || ctx == null || !ctx.mounted) return;
    final confirmed = await showExitToMainMenuConfirmDialog(ctx);
    if (!confirmed) return;
    handler.state.bus.emit(const NavigateToShellEvent());
  });
}

void appEventHandlerNavigateToShell(
  AppEventHandler handler,
  NavigatorState? nav,
) {
  if (nav == null) return;
  final ctx = nav.context;
  if (ctx.mounted) {
    try {
      final container = ProviderScope.containerOf(ctx, listen: false);
      clearActiveGameSession(container);
    } catch (e, st) {
      _log.d(
        'navigateToShell: skipped in-memory game clear (no ProviderScope)',
        error: e,
        stackTrace: st,
      );
    }
  }
  var foundShellRoute = false;
  nav.popUntil((route) {
    final matches = route.settings.name == Routes.shell;
    if (matches) {
      foundShellRoute = true;
    }
    return matches;
  });
  if (!foundShellRoute) {
    nav.pushNamedAndRemoveUntil(Routes.shell, (route) => false);
  }
}

/// Result of a unit-panel sheet body builder.
typedef UnitsPanelSheetBody = ({Widget? replacement, Widget? panel});

/// Shared bottom-sheet host for civilian / military / naval unit panels.
Future<void> appEventHandlerShowUnitsPanelSheet(
  AppEventHandler handler, {
  required NavigatorState nav,
  required String panelKind,
  required UnitsPanelSheetBody Function(
    BuildContext context,
    WidgetRef ref,
    Game game,
  )
  buildBody,
  bool applyCivilianE2eHeightOverride = false,
  VoidCallback? beforeClosedEvent,
}) async {
  await showModalBottomSheet<void>(
    context: nav.context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final game = ref.watch(currentGameProvider);
        if (game == null) {
          return const SizedBox.shrink();
        }
        final body = buildBody(context, ref, game);
        final replacement = body.replacement;
        if (replacement != null) {
          return replacement;
        }
        final panel = body.panel;
        if (panel == null) {
          return const SizedBox.shrink();
        }
        final sheetConstraints = unitsPanelHostSheetConstraints(
          viewport: MediaQuery.sizeOf(context),
          applyCivilianE2eHeightOverride: applyCivilianE2eHeightOverride,
          e2eEnabled: kCtE2EEnabled,
        );
        return UnitsPanelSheetSurface(
          child: ConstrainedBox(
            constraints: sheetConstraints,
            child: panel,
          ),
        );
      },
    ),
  ).whenComplete(() {
    beforeClosedEvent?.call();
    handler.state.bus.emit(UnitsPanelClosedEvent(panelKind));
  });
}

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
          prospectShortcutTargetTileKey: event.prospectShortcutTargetTileKey,
          exploreShortcutTargetTileKey: event.exploreShortcutTargetTileKey,
          buildImprovementShortcutTargetTileKey:
              event.buildImprovementShortcutTargetTileKey,
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
