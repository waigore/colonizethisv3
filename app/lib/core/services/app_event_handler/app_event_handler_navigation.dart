part of 'app_event_handler.dart';

extension _AppEventHandlerNavigation on AppEventHandler {
  static const _observeBlockedDialogIds = {
    'train_civilians',
    'train_military',
    'grant_or_subsidy',
  };

  Future<void> _openDialog(OpenDialogEvent event, NavigatorState? nav) async {
    if (nav == null) return;
    if (_observeBlockedDialogIds.contains(event.dialogId)) {
      final ctx = nav.context;
      final container = ProviderScope.containerOf(ctx);
      if (!container.read(shellPlayerContextProvider).canMutateViaUi) {
        _onShowSnackBar?.call(
          const ShowSnackBarEvent(
            message: 'Observe mode: UI actions are read-only.',
          ),
        );
        return;
      }
    }
    final builder = _dialogBuilders[event.dialogId];
    if (builder == null) {
      debugPrint('[AppEventHandler] No dialog builder for: ${event.dialogId}');
      return;
    }
    await showDialog<void>(
      context: nav.context,
      builder: (ctx) => builder(ctx, event.params),
    );
  }

  Future<bool> _showConfirmDialog(
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

  Future<void> _openPanel(OpenPanelEvent event, NavigatorState? nav) async {
    if (nav == null) return;
    final builder = _panelBuilders[event.panelId];
    if (builder == null) {
      debugPrint('[AppEventHandler] No panel builder for: ${event.panelId}');
      return;
    }
    await showModalBottomSheet<void>(
      context: nav.context,
      builder: (ctx) => builder(ctx, event.params),
    );
  }

  Future<void> _openPauseMenuPanel(
    OpenPauseMenuPanelEvent event,
    NavigatorState? nav,
  ) async {
    if (nav == null) return;
    await showDialog<void>(
      context: nav.context,
      useRootNavigator: true,
      barrierColor: EditorialMonoclePalette.dialogScrim,
      builder: (ctx) => PauseMenuPanel(bus: _bus),
    );
  }

  /// Pause-menu Exit to Main Menu flow. The pause sheet has already emitted
  /// [ClosePanelEvent] before this event fires, so the sheet is being
  /// dismissed via `Navigator.maybePop`. We schedule the exit-confirm
  /// dialog after the current frame so the closing pop completes before
  /// the new modal mounts (preventing the confirm dialog from being torn
  /// down with the pause sheet). SPEC: `SPEC/ui/pause-menu-panel.md`
  /// § Navigation, `SPEC/ui/in-game-shell-narrow.md` § Android back confirm.
  void _handleRequestExitToMainMenuFlow(NavigatorState? nav) {
    if (nav == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = _navigatorKey.currentState;
      final ctx = state?.context;
      if (state == null || ctx == null || !ctx.mounted) return;
      final confirmed = await showExitToMainMenuConfirmDialog(ctx);
      if (!confirmed) return;
      _bus.emit(const NavigateToShellEvent());
    });
  }

  void _navigateToShell(NavigatorState? nav) {
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
}
