/// Navigation and dialog UI actions (Refs #4334 wave 3).

import 'ui_action_event_base.dart';

/// Request to open a dialog by string id; params passed to dialog builder.
class OpenDialogEvent extends UIActionEvent {
  const OpenDialogEvent(this.dialogId, [this.params]);
  final String dialogId;
  final Map<String, Object?>? params;
}

/// Request to show a confirmation dialog; returns bool via Future.
class ConfirmDialogEvent extends UIActionEvent {
  const ConfirmDialogEvent({
    required this.title,
    required this.message,
    this.confirmLabel = 'OK',
    this.cancelLabel = 'Cancel',
    void Function(bool)? onResult,
  }) : _onResult = onResult;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final void Function(bool)? _onResult;

  void result(bool confirmed) => _onResult?.call(confirmed);
}

/// Request to navigate to a named route.
class NavigateToRouteEvent extends UIActionEvent {
  const NavigateToRouteEvent(this.route, [this.arguments]);
  final String route;
  final Object? arguments;
}

/// Request to pop the current route.
class PopNavigationEvent extends UIActionEvent {
  const PopNavigationEvent();
}

/// Return to the main menu shell, clearing the game route stack.
/// Handled only by the app-layer event handler (`AppEventHandler`). SPEC/program/app-ui-wiring.md.
class NavigateToShellEvent extends UIActionEvent {
  const NavigateToShellEvent();
}

/// Request the app-layer exit-to-main-menu confirmation flow.
///
/// Emitted by the pause menu (`PauseMenuPanel`) when the player taps
/// **Exit to Main Menu**. The shell-level event handler responds by
/// showing the standard exit-confirm dialog
/// (`showExitToMainMenuConfirmDialog`); on confirm the handler emits
/// [NavigateToShellEvent], on cancel no further event fires.
///
/// SPEC: `SPEC/ui/pause-menu-panel.md` § Navigation,
/// `SPEC/ui/in-game-shell-narrow.md` § Android back confirm,
/// `SPEC/program/app-ui-wiring.md`.
class RequestExitToMainMenuFlowEvent extends UIActionEvent {
  const RequestExitToMainMenuFlowEvent();
}
