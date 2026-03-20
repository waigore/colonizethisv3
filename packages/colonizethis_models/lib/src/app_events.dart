// App events: typed event bus for UI↔UI, UI↔game logic, game logic→UI.
// SPEC/program/game-events.md, SPEC/program/app-event-bus.md (pending).
//
// Three event domains:
//  1. GameEvent    — game occurrences from colonizethis_logic (consumed, not defined here)
//  2. UIActionEvent — UI components requesting actions (dialogs, navigation, panels)
//  3. UISystemEvent — system-level UI feedback (snackbars, overlays, toasts)
//
// Note: GameEvent lives in colonizethis_logic to avoid circular deps.
// DialogueEvent and PortraitMoodEvent live here in colonizethis_models.

export 'ai_events.dart' show DialogueEvent, PortraitMoodEvent;

abstract class AppEvent {
  const AppEvent();
}

// ---------------------------------------------------------------------------
// UIActionEvent — emitted by UI components that need other UI components to act.
// ---------------------------------------------------------------------------

sealed class UIActionEvent extends AppEvent {
  const UIActionEvent();
}

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

/// Request to open a side panel or overlay.
class OpenPanelEvent extends UIActionEvent {
  const OpenPanelEvent(this.panelId, [this.params]);
  final String panelId;
  final Map<String, Object?>? params;
}

/// Request to close the current panel or overlay.
class ClosePanelEvent extends UIActionEvent {
  const ClosePanelEvent();
}

/// Request to start a unit target-selection mode (map enters target-pick state).
class StartTargetSelectionEvent extends UIActionEvent {
  const StartTargetSelectionEvent({
    required this.unitId,
    required this.action,
    this.onComplete,
    this.onCancel,
  });
  final String unitId;
  final String action;
  final void Function(String provinceId)? onComplete;
  final void Function()? onCancel;
}

/// Cancel any active target-selection mode.
class CancelTargetSelectionEvent extends UIActionEvent {
  const CancelTargetSelectionEvent();
}

// ---------------------------------------------------------------------------
// UISystemEvent — emitted by any layer to request transient system feedback.
// ---------------------------------------------------------------------------

sealed class UISystemEvent extends AppEvent {
  const UISystemEvent();
}

/// Show a snackbar / toast message.
class ShowSnackBarEvent extends UISystemEvent {
  const ShowSnackBarEvent({
    required this.message,
    this.actionLabel,
    this.action,
  });
  final String message;
  final String? actionLabel;
  final void Function()? action;
}

/// Show a transient overlay (e.g. "Combat resolving..." spinner).
class ShowOverlayEvent extends UISystemEvent {
  const ShowOverlayEvent({required this.overlayId, this.params});
  final String overlayId;
  final Map<String, Object?>? params;
}

/// Dismiss the transient overlay.
class DismissOverlayEvent extends UISystemEvent {
  const DismissOverlayEvent(this.overlayId);
  final String overlayId;
}

/// Show a non-blocking notification badge / toast for an event (combat, research, etc.).
/// Unlike SnackBar, this may auto-dismiss and is less intrusive.
class NotifyEvent extends UISystemEvent {
  const NotifyEvent({required this.title, required this.body, this.priority});
  final String title;
  final String body;
  final NotifyPriority? priority;
}

enum NotifyPriority { low, normal, high }

// ---------------------------------------------------------------------------
// Game-to-UI bridge — emitted by services when game state changes.
// These are additional events beyond GameEvent (which lives in colonizethis_logic).
// ---------------------------------------------------------------------------

sealed class GameToUIEvent extends AppEvent {
  const GameToUIEvent();
}

/// Emitted when turn resolution completes; UI may refresh panels.
class TurnResolutionCompleteEvent extends GameToUIEvent {
  const TurnResolutionCompleteEvent({
    required this.gameId,
    required this.turnNumber,
  });
  final String gameId;
  final int turnNumber;
}

/// Emitted when overture decisions are required; UI should show overture dialog.
class OvertureRequiredEvent extends GameToUIEvent {
  const OvertureRequiredEvent({required this.overtures});
  final List<Object> overtures; // OvertureOffer
}

/// Emitted when save/load completes.
class SaveGameCompleteEvent extends GameToUIEvent {
  const SaveGameCompleteEvent({required this.gameId});
  final String gameId;
}

/// Emitted when a new game is created.
class NewGameCreatedEvent extends GameToUIEvent {
  const NewGameCreatedEvent({required this.gameId});
  final String gameId;
}
