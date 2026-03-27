// App events: typed event bus for UI↔UI, UI↔game logic, game logic→UI.
// Coupling / wiring rules: SPEC/program/app-ui-wiring.md. Bus architecture: SPEC/program/app-event-bus.md.
//
// Three event domains:
//  1. GameEvent    — game occurrences from colonizethis_logic (consumed, not defined here)
//  2. UIActionEvent — UI components requesting actions (dialogs, navigation, panels)
//  3. UISystemEvent — system-level UI feedback (snackbars, overlays, toasts)
//
// Note: GameEvent lives in colonizethis_logic to avoid circular deps.
// DialogueEvent and PortraitMoodEvent live here in colonizethis_models.
//
// Panel requests: prefer typed subclasses below (SPEC/program/app-ui-wiring.md).
// [OpenPanelEvent] remains for legacy string-id panels until migrated.

import 'game.dart';

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

/// Civilian units bottom sheet. App handler supplies [Game] / orders from Riverpod.
/// Pending work removal and in-progress cancel use [SessionCommandEvent]s (bus), not
/// closures on this event — see SPEC/program/app-event-bus.md.
class OpenCivilianUnitsPanelEvent extends UIActionEvent {
  const OpenCivilianUnitsPanelEvent();
}

/// Military units bottom sheet.
class OpenMilitaryUnitsPanelEvent extends UIActionEvent {
  const OpenMilitaryUnitsPanelEvent();
}

/// Naval units bottom sheet. Fleet mutations emit [NavalFleetsUpdatedEvent] from the panel.
class OpenNavalUnitsPanelEvent extends UIActionEvent {
  const OpenNavalUnitsPanelEvent();
}

/// Request to center/highlight a map tile, optionally dismissing the active panel.
class LocateMapTileEvent extends UIActionEvent {
  const LocateMapTileEvent({
    required this.tileKey,
    required this.regionId,
    this.closeCurrentPanel = false,
  });

  final String tileKey;
  final String regionId;
  final bool closeCurrentPanel;
}

/// Request to start civilian target-selection mode from the units panel.
class StartCivilianWorkTargetSelectionEvent extends UIActionEvent {
  const StartCivilianWorkTargetSelectionEvent({
    required this.unitId,
    required this.workTarget,
    this.closeCurrentPanel = true,
  });

  final String unitId;
  final String workTarget;
  final bool closeCurrentPanel;
}

/// Emitted when a typed units panel route is dismissed.
class UnitsPanelClosedEvent extends UIActionEvent {
  const UnitsPanelClosedEvent(this.panel);

  final String panel;
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

/// Request to open the province/sea zone detail overlay for [provinceId].
/// Emitted by the map widget when user taps a town or port icon.
/// SPEC/ui/town-port-icons.md.
class OpenProvinceDetailPanelEvent extends UIActionEvent {
  const OpenProvinceDetailPanelEvent(this.provinceId);
  final String provinceId;
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
// SessionCommandEvent — applied by long-lived shell listeners, not AppEventHandler.
// ---------------------------------------------------------------------------

/// Session-scoped commands: listeners use a stable [ProviderScope] ref (e.g.
/// [AppEventHandlerScope]). **Do not** capture [WidgetRef] from widgets that
/// unmount when opening panels (side menus, sheets). SPEC/program/app-event-bus.md.
sealed class SessionCommandEvent extends AppEvent {
  const SessionCommandEvent();
}

/// Remove pending civilian work order at [index] for [playerId] in current-turn
/// draft. Shell listener applies the canonical mutation from colonizethis_logic.
class RemovePendingWorkOrderRequestedEvent extends SessionCommandEvent {
  RemovePendingWorkOrderRequestedEvent({
    required this.playerId,
    required this.index,
  });

  final String playerId;
  final int index;
}

/// Clear in-progress civilian work for [unitId] (no refund). Shell listener
/// applies the canonical mutation from colonizethis_logic and persists game.
class CancelInProgressCivilianWorkRequestedEvent extends SessionCommandEvent {
  CancelInProgressCivilianWorkRequestedEvent({required this.unitId});

  final String unitId;
}

/// Naval panel produced an updated [game] (split/combine). Handler updates session game.
class NavalFleetsUpdatedEvent extends SessionCommandEvent {
  NavalFleetsUpdatedEvent({required this.game});

  final Game game;
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

/// Naval battle resolved in a sea zone. Mirrors colonizethis_logic NavalCombatResultEvent.
class AppNavalCombatResultEvent extends GameToUIEvent {
  const AppNavalCombatResultEvent({
    required this.seaZoneId,
    required this.side1OwnerId,
    required this.side2OwnerId,
    required this.outcomeName,
    required this.turnNumber,
    this.winnerOwnerId,
    this.side1Retreated = false,
    this.side2Retreated = false,
  });
  final String seaZoneId;
  final String side1OwnerId;
  final String side2OwnerId;
  final String outcomeName;
  final int turnNumber;
  final String? winnerOwnerId;
  final bool side1Retreated;
  final bool side2Retreated;
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
