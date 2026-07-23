import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../config/routes.dart';
import '../../../features/game/widgets/panels/pause_menu_panel.dart';
import '../../../features/game/widgets/shell/shell_player_context.dart';
import '../game_session_clear.dart';
import '../../../features/game/flame/overlays/exit_confirm_dialog.dart';
import '../../../widgets/ct_confirm_dialog.dart';
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

/// Pause-menu Exit to Main Menu flow. The pause sheet has already emitted
/// [ClosePanelEvent] before this event fires, so the sheet is being
/// dismissed via `Navigator.maybePop`. We schedule the exit-confirm
/// dialog after the current frame so the closing pop completes before
/// the new modal mounts (preventing the confirm dialog from being torn
/// down with the pause sheet). SPEC: `SPEC/ui/pause-menu-panel.md`
/// § Navigation, `SPEC/ui/in-game-shell-narrow.md` § Android back confirm.
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
