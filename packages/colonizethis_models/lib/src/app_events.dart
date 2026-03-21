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
//
// Panel requests: prefer typed subclasses below (SPEC/program/app-event-bus.md).
// [OpenPanelEvent] remains for legacy string-id panels until migrated.

import 'game.dart';
import 'unit.dart';

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

/// In-game pause menu bottom sheet. Handled by the shell-level event handler (app layer).
class OpenPauseMenuPanelEvent extends UIActionEvent {
  const OpenPauseMenuPanelEvent({this.onDebugLog, this.onResume});

  final void Function()? onDebugLog;
  final void Function()? onResume;
}

/// Civilian units bottom sheet. App handler supplies [Game] / orders from Riverpod;
/// callbacks bridge map/shell behavior (locate, work orders, target pick).
class OpenCivilianUnitsPanelEvent extends UIActionEvent {
  OpenCivilianUnitsPanelEvent({
    required this.onLocateUnit,
    required this.onRemoveWorkOrder,
    required this.onCancelUnitWork,
    required this.onStartWorkTargetSelection,
    this.onPanelDismissed,
  });

  final void Function(Unit unit) onLocateUnit;
  final void Function(String playerId, int index) onRemoveWorkOrder;
  final void Function(String unitId) onCancelUnitWork;
  final void Function(Unit unit, String workTarget) onStartWorkTargetSelection;

  /// Invoked when the bottom sheet route is popped (any reason).
  final void Function()? onPanelDismissed;
}

/// Military units bottom sheet.
class OpenMilitaryUnitsPanelEvent extends UIActionEvent {
  OpenMilitaryUnitsPanelEvent({
    required this.onLocateTile,
    this.onPanelDismissed,
  });

  final void Function(String tileKey, String regionId) onLocateTile;
  final void Function()? onPanelDismissed;
}

/// Naval units bottom sheet.
class OpenNavalUnitsPanelEvent extends UIActionEvent {
  OpenNavalUnitsPanelEvent({
    required this.onLocateFleet,
    required this.onFleetsChanged,
    this.onPanelDismissed,
  });

  final void Function(String tileKey, String regionId) onLocateFleet;
  final void Function(Game game) onFleetsChanged;
  final void Function()? onPanelDismissed;
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

/// Emitted by GrantOrSubsidyDialog when user submits the amount form.
/// Carries the data needed to show a final confirmation dialog.
class GrantOrSubsidySubmittedEvent extends UIActionEvent {
  const GrantOrSubsidySubmittedEvent({
    required this.targetFactionId,
    required this.amount,
    required this.isSubsidy,
  });
  final String targetFactionId;
  final int amount;
  final bool isSubsidy;
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

// ---------------------------------------------------------------------------
// App-prefixed GameEvent mirrors — forwarded from logic layer via GameEventBridge.
// SPEC/program/game-event-bridge.md
// ---------------------------------------------------------------------------

/// Combat resolved in a province. Mirrors colonizethis_logic CombatResultEvent.
class AppCombatResultEvent extends GameToUIEvent {
  const AppCombatResultEvent({
    required this.provinceId,
    required this.attackerId,
    required this.defenderId,
    required this.winnerId,
    required this.turnNumber,
    this.casualties = const {},
  });
  final String provinceId;
  final String attackerId;
  final String defenderId;
  final String winnerId;
  final int turnNumber;
  final Map<String, int> casualties;
}

/// Province ownership changed. Mirrors colonizethis_logic ProvinceCapturedEvent.
class AppProvinceCapturedEvent extends GameToUIEvent {
  const AppProvinceCapturedEvent({
    required this.provinceId,
    required this.previousOwnerId,
    required this.newOwnerId,
    required this.turnNumber,
  });
  final String provinceId;
  final String? previousOwnerId;
  final String newOwnerId;
  final int turnNumber;
}

/// Diplomatic relationship changed. Mirrors colonizethis_logic DiplomacyChangeEvent.
class AppDiplomacyChangeEvent extends GameToUIEvent {
  const AppDiplomacyChangeEvent({
    required this.actorId,
    required this.targetId,
    required this.changeType,
    required this.turnNumber,
  });
  final String actorId;
  final String targetId;
  final String changeType;
  final int turnNumber;
}

/// Technology research completed. Mirrors colonizethis_logic ResearchCompleteEvent.
class AppResearchCompleteEvent extends GameToUIEvent {
  const AppResearchCompleteEvent({
    required this.playerId,
    required this.techId,
    required this.turnNumber,
  });
  final String playerId;
  final String techId;
  final int turnNumber;
}

/// Victory condition set. Mirrors colonizethis_logic VictorySetEvent.
class AppVictorySetEvent extends GameToUIEvent {
  const AppVictorySetEvent({
    required this.winnerPlayerId,
    required this.victoryType,
    required this.turnNumber,
  });
  final String winnerPlayerId;
  final String victoryType;
  final int turnNumber;
}

/// Order rejected during validation. Mirrors colonizethis_logic OrderRejectedEvent.
class AppOrderRejectedEvent extends GameToUIEvent {
  const AppOrderRejectedEvent({
    required this.playerId,
    required this.orderSummary,
    required this.reasonCode,
  });
  final String playerId;
  final String orderSummary;
  final String reasonCode;
}
