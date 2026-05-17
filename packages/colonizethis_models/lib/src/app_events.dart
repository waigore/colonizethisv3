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

import 'combat_mode.dart';
import 'diplomacy.dart';
import 'game.dart';
import 'turn_news_digest.dart';
import 'orders.dart';

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

/// Return to the main menu shell, clearing the game route stack.
/// Handled only by the app-layer event handler (`AppEventHandler`). SPEC/program/app-ui-wiring.md.
class NavigateToShellEvent extends UIActionEvent {
  const NavigateToShellEvent();
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
/// Menu actions emit [ClosePanelEvent] / [NavigateToRouteEvent]; no callbacks on this event.
class OpenPauseMenuPanelEvent extends UIActionEvent {
  const OpenPauseMenuPanelEvent();
}

/// Civilian units bottom sheet. App handler supplies [Game] / orders from Riverpod.
/// Pending work removal and in-progress cancel use [SessionCommandEvent]s (bus), not
/// closures on this event — see SPEC/program/app-event-bus.md.
class OpenCivilianUnitsPanelEvent extends UIActionEvent {
  const OpenCivilianUnitsPanelEvent({
    this.tileScopeTileKey,
    this.initialSelectedUnitId,
    this.explorerOnly = false,
    this.builderOnly = false,
    this.prospectShortcutTargetTileKey,
    this.exploreShortcutTargetTileKey,
    this.buildImprovementShortcutTargetTileKey,
  });

  /// Optional tile-scope key (`regionId|provinceId|x|y`) used to show only
  /// civilians currently rendered on that tile.
  final String? tileScopeTileKey;

  /// Optional initial selected unit id when opening in tile scope.
  final String? initialSelectedUnitId;

  /// Optional panel filter mode for explorer-only rows.
  final bool explorerOnly;

  /// Optional panel filter mode for builder-only rows.
  final bool builderOnly;

  /// Optional tile key used by the province prospect shortcut flow.
  final String? prospectShortcutTargetTileKey;

  /// Optional tile key used by the province explore shortcut flow.
  final String? exploreShortcutTargetTileKey;

  /// Optional tile key used by the province build-improvement shortcut flow.
  final String? buildImprovementShortcutTargetTileKey;
}

/// Military units bottom sheet.
class OpenMilitaryUnitsPanelEvent extends UIActionEvent {
  const OpenMilitaryUnitsPanelEvent();
}

/// Naval units bottom sheet. Fleet mutations emit [NavalFleetsUpdatedEvent] from the panel.
class OpenNavalUnitsPanelEvent extends UIActionEvent {
  const OpenNavalUnitsPanelEvent({
    this.locationScopeKey,
    this.initialSelectedFleetId,
    this.tileScopeTileKey,
  });

  /// Optional `port:regionId|provinceId` / `sea:regionId|seaZoneId` filter (naval tree).
  final String? locationScopeKey;

  /// Optional initial fleet selection when opening in location scope.
  final String? initialSelectedFleetId;

  /// Optional map tile key (`regionId|cellId|x|y`) for tile-scoped panel chrome (Locate / title).
  final String? tileScopeTileKey;
}

/// Toggle in-map debug console overlay panel.
class ToggleDebugConsolePanelEvent extends UIActionEvent {
  const ToggleDebugConsolePanelEvent();
}

/// Explicit open request for in-map debug console overlay panel.
class OpenDebugConsolePanelEvent extends UIActionEvent {
  const OpenDebugConsolePanelEvent();
}

/// Explicit close request for in-map debug console overlay panel.
class CloseDebugConsolePanelEvent extends UIActionEvent {
  const CloseDebugConsolePanelEvent();
}

/// Request to center/highlight a map tile. To close a units sheet first, emit [ClosePanelEvent]
/// before this event (same synchronous turn or after [SchedulerBinding] frame); do not dismiss sheets from the map widget.
class LocateMapTileEvent extends UIActionEvent {
  const LocateMapTileEvent({required this.tileKey, required this.regionId});

  final String tileKey;
  final String regionId;
}

/// Request to open the province/tile detail panel for a concrete map tile key.
class OpenMapTileDetailEvent extends UIActionEvent {
  const OpenMapTileDetailEvent({required this.tileKey});

  final String tileKey;
}

/// In-game region minimap requests the Flame map camera center at world coordinates (after clamp).
/// Consumed by the in-game region map host wired to the same [AppEventBus]. SPEC/ui/empire-overview.md.
class RequestRegionMapCameraCenterWorldEvent extends UIActionEvent {
  const RequestRegionMapCameraCenterWorldEvent({
    required this.regionId,
    required this.worldCenterX,
    required this.worldCenterY,
  });

  final String regionId;
  final double worldCenterX;
  final double worldCenterY;
}

/// In-game region minimap requests a world-space pan of the Flame map camera center (after clamp).
class RequestRegionMapCameraPanWorldDeltaEvent extends UIActionEvent {
  const RequestRegionMapCameraPanWorldDeltaEvent({
    required this.regionId,
    required this.worldDx,
    required this.worldDy,
  });

  final String regionId;
  final double worldDx;
  final double worldDy;
}

/// In-game shell requests an absolute fit-relative zoom multiplier `m` (`zoom = m × z_fit`).
/// The map clamps [zoomMultiplier] to **[0.5, 8.0]** before applying. SPEC/ui/map-widget.md.
class RequestRegionMapSetZoomMultiplierEvent extends UIActionEvent {
  const RequestRegionMapSetZoomMultiplierEvent({
    required this.regionId,
    required this.zoomMultiplier,
  });

  final String regionId;

  /// Target `m` vs fit-map baseline; host clamps to [0.5, 8.0].
  final double zoomMultiplier;
}

/// Request to start civilian target-selection mode from the units panel.
/// Emit [ClosePanelEvent] first when the civilian units sheet should close.
class StartCivilianWorkTargetSelectionEvent extends UIActionEvent {
  const StartCivilianWorkTargetSelectionEvent({
    required this.unitId,
    required this.workTarget,
  });

  final String unitId;
  final String workTarget;
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

/// Emitted when the user chooses auto-resolve or quick battle in [CombatModeChoiceDialog].
class CombatModeChosenEvent extends UIActionEvent {
  const CombatModeChosenEvent(this.mode);

  final CombatMode mode;
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

/// Upsert one pending civilian [workOrder] for [playerId] in current-turn draft.
/// Replaces any existing pending work for the same unit and clears conflicting
/// pending move order for that unit (work-order draft xor rule).
class UpsertPendingCivilianWorkOrderRequestedEvent extends SessionCommandEvent {
  UpsertPendingCivilianWorkOrderRequestedEvent({
    required this.playerId,
    required this.workOrder,
  });

  final String playerId;
  final WorkOrder workOrder;
}

/// Naval panel produced an updated [game] (split/combine). Handler updates session game.
class NavalFleetsUpdatedEvent extends SessionCommandEvent {
  NavalFleetsUpdatedEvent({required this.game});

  final Game game;
}

/// Split fleet dialog confirm: shell applies split and emits [NavalFleetsUpdatedEvent]
/// (same pipeline as combine). SPEC/program/app-ui-wiring.md.
class NavalSplitFleetRequestedEvent extends SessionCommandEvent {
  NavalSplitFleetRequestedEvent({
    required this.humanPlayerId,
    required this.originalFleetId,
    required this.shipInstanceIdsToNewFleet,
  });

  final String humanPlayerId;
  final String originalFleetId;
  final List<String> shipInstanceIdsToNewFleet;
}

/// Transfer selected ship instances from one existing fleet into another.
/// Shell listener applies canonical fleet mutation and emits
/// [NavalFleetsUpdatedEvent]. SPEC/program/app-ui-wiring.md.
class NavalTransferShipsRequestedEvent extends SessionCommandEvent {
  NavalTransferShipsRequestedEvent({
    required this.humanPlayerId,
    required this.sourceFleetId,
    required this.targetFleetId,
    required this.shipInstanceIdsToTransfer,
  });

  final String humanPlayerId;
  final String sourceFleetId;
  final String targetFleetId;
  final List<String> shipInstanceIdsToTransfer;
}

/// Move fleet dialog confirm: shell merges [moveOrder] into current-turn draft orders.
/// SPEC/program/app-ui-wiring.md.
class NavalMoveFleetRequestedEvent extends SessionCommandEvent {
  NavalMoveFleetRequestedEvent({
    required this.humanPlayerId,
    required this.moveOrder,
  });

  final String humanPlayerId;
  final NavalMoveOrder moveOrder;
}

/// Military units panel: game state updated after army split/combine.
/// SPEC/program/app-ui-wiring.md.
class LandArmiesUpdatedEvent extends SessionCommandEvent {
  LandArmiesUpdatedEvent({required this.game});

  final Game game;
}

/// Combine selected armies in the same province (shell applies colonizethis_logic).
class ArmyCombineRequestedEvent extends SessionCommandEvent {
  ArmyCombineRequestedEvent({
    required this.humanPlayerId,
    required this.armyIds,
  });

  final String humanPlayerId;
  final List<String> armyIds;
}

/// Split confirmed from split-army dialog (shell applies colonizethis_logic).
class ArmySplitRequestedEvent extends SessionCommandEvent {
  ArmySplitRequestedEvent({
    required this.humanPlayerId,
    required this.sourceArmyId,
    required this.unitIdsToMove,
  });

  final String humanPlayerId;
  final String sourceArmyId;
  final List<String> unitIdsToMove;
}

/// Move army dialog confirm: merges [moveOrder] into current-turn draft orders.
///
/// When [declareWarTargetFactionId] is set, the shell appends a same-turn
/// `declareWar` on that faction before applying [moveOrder] (invasion path).
class ArmyMoveRequestedEvent extends SessionCommandEvent {
  ArmyMoveRequestedEvent({
    required this.humanPlayerId,
    required this.moveOrder,
    this.declareWarTargetFactionId,
  });

  final String humanPlayerId;
  final ArmyMoveOrder moveOrder;

  /// Great Power / Minor / Tribe id to declare war on when the move required
  /// the invasion confirmation flow. Null for normal moves and when already at war.
  final String? declareWarTargetFactionId;
}

/// Train civilians dialog close: shell merges into current-turn orders draft.
class TrainCivilianBuildOrdersCommittedEvent extends SessionCommandEvent {
  TrainCivilianBuildOrdersCommittedEvent({required this.orders});

  final List<BuildUnitOrder> orders;
}

/// Train military dialog close: shell merges into current-turn orders draft.
class TrainMilitaryBuildOrdersCommittedEvent extends SessionCommandEvent {
  TrainMilitaryBuildOrdersCommittedEvent({required this.orders});

  final List<BuildUnitOrder> orders;
}

/// Immediate debug spawn at the human player's capital tile.
class SpawnDebugCivilianAtCapitalEvent extends SessionCommandEvent {
  const SpawnDebugCivilianAtCapitalEvent({
    required this.humanPlayerId,
    required this.unitType,
    this.count = 1,
  });

  final String humanPlayerId;
  final String unitType;
  final int count;
}

/// Immediate debug military regiment spawn at the human player's capital.
class SpawnDebugRegimentAtCapitalEvent extends SessionCommandEvent {
  const SpawnDebugRegimentAtCapitalEvent({
    required this.humanPlayerId,
    required this.regimentTypeId,
    this.count = 1,
  });

  final String humanPlayerId;
  final String regimentTypeId;
  final int count;
}

/// Immediate debug ship spawn into the human player's home fleet at capital.
class SpawnDebugShipAtCapitalHomeFleetEvent extends SessionCommandEvent {
  const SpawnDebugShipAtCapitalHomeFleetEvent({
    required this.humanPlayerId,
    required this.shipTypeId,
    this.count = 1,
  });

  final String humanPlayerId;
  final String shipTypeId;
  final int count;
}

/// Immediate debug treasury credit for the human player (no economy modifiers).
class CreditDebugTreasuryEvent extends SessionCommandEvent {
  const CreditDebugTreasuryEvent({
    required this.humanPlayerId,
    required this.requestedAmount,
    required this.creditedAmount,
  });

  final String humanPlayerId;
  final int requestedAmount;
  final int creditedAmount;
}

/// Immediate debug industrial worker-pool credit for the human player.
///
/// [workerTierId] is one of `WorkerPool` JSON field names:
/// `peasants`, `apprentices`, `journeymen`, `masters`.
class CreditDebugWorkerPoolEvent extends SessionCommandEvent {
  const CreditDebugWorkerPoolEvent({
    required this.humanPlayerId,
    required this.workerTierId,
    required this.requestedAmount,
    required this.creditedAmount,
  });

  final String humanPlayerId;
  final String workerTierId;
  final int requestedAmount;
  final int creditedAmount;
}

/// Immediate debug stockpile commodity credit for the human player.
class CreditDebugStockpileCommodityEvent extends SessionCommandEvent {
  const CreditDebugStockpileCommodityEvent({
    required this.humanPlayerId,
    required this.commodityId,
    required this.requestedAmount,
    required this.creditedAmount,
  });

  final String humanPlayerId;
  final String commodityId;
  final int requestedAmount;
  final int creditedAmount;
}

/// Immediate debug province ownership transfer for the active human player.
class FlipDebugProvinceOwnershipEvent extends SessionCommandEvent {
  const FlipDebugProvinceOwnershipEvent({
    required this.humanPlayerId,
    this.fullProvinceId,
    this.regionId,
    this.provinceDisplayName,
  }) : assert(
         (fullProvinceId != null &&
                 regionId == null &&
                 provinceDisplayName == null) ||
             (fullProvinceId == null &&
                 regionId != null &&
                 provinceDisplayName != null),
         'FlipDebugProvinceOwnershipEvent requires fullProvinceId OR regionId+provinceDisplayName.',
       );

  final String humanPlayerId;
  final String? fullProvinceId;
  final String? regionId;
  final String? provinceDisplayName;
}

/// Immediate debug province visibility reveal for the active human player.
class RevealDebugProvinceEvent extends SessionCommandEvent {
  const RevealDebugProvinceEvent({
    required this.humanPlayerId,
    required this.target,
    required this.targetIsFullProvinceId,
  });

  final String humanPlayerId;
  final String target;
  final bool targetIsFullProvinceId;
}

/// Request to append one diplomatic order for [playerId] in current-turn draft.
class AppendDiplomaticOrderRequestedEvent extends SessionCommandEvent {
  AppendDiplomaticOrderRequestedEvent({
    required this.playerId,
    required this.order,
  });

  final String playerId;
  final DiplomaticOrder order;
}

/// Request to remove one pending diplomatic order by [type] and [targetFactionId]
/// for [playerId] in current-turn draft.
class RemoveDiplomaticOrderRequestedEvent extends SessionCommandEvent {
  RemoveDiplomaticOrderRequestedEvent({
    required this.playerId,
    required this.type,
    required this.targetFactionId,
  });

  final String playerId;
  final DiplomaticOrderType type;
  final String targetFactionId;
}

/// Negotiation UI mood input for portrait transitions.
///
/// UI supplies deterministic negotiation inputs; session listeners compute the
/// next mood and emit [PortraitMoodEvent] when the mood changes.
class NegotiationMoodUpdateEvent extends SessionCommandEvent {
  const NegotiationMoodUpdateEvent({
    required this.leaderId,
    required this.currentMood,
    required this.offerQualityDelta,
    required this.stallCounter,
    required this.seed,
    this.durationMs = 1200,
  });

  final String leaderId;
  final String currentMood;
  final double offerQualityDelta;
  final int stallCounter;
  final int seed;
  final int durationMs;
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
    this.turnNewsDigest,
  });
  final String gameId;
  final int turnNumber;

  /// Prior-turn digest for the news dialog; null when victory was set this resolution.
  final TurnNewsDigest? turnNewsDigest;
}

/// Emitted when overture decisions are required; UI should show overture dialog.
class OvertureRequiredEvent extends GameToUIEvent {
  const OvertureRequiredEvent({required this.overtures});
  final List<Object> overtures; // OvertureOffer
}

/// Emitted when intervention choices are required (Diplomacy phase).
class InterventionRequiredEvent extends GameToUIEvent {
  const InterventionRequiredEvent({required this.prompts});
  final List<Object> prompts; // InterventionPrompt from colonizethis_logic
}

/// Emitted when human ally must accept or refuse call to arms after a GP war declaration.
class CallToArmsRequiredEvent extends GameToUIEvent {
  const CallToArmsRequiredEvent({required this.pending});

  /// [CallToArmsPending] from colonizethis_logic (kept as Object to avoid package cycle).
  final List<Object> pending;
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

/// Civilian work order completed. Mirrors colonizethis_logic WorkOrderCompletedEvent.
class AppWorkOrderCompletedEvent extends GameToUIEvent {
  const AppWorkOrderCompletedEvent({
    required this.playerId,
    required this.unitId,
    required this.workTarget,
    required this.targetTileKey,
    required this.provinceId,
    required this.turnNumber,
  });
  final String playerId;
  final String unitId;
  final String workTarget;
  final String targetTileKey;
  final String provinceId;
  final int turnNumber;
}

/// Player-scoped province discovery. Mirrors colonizethis_logic PlayerProvinceDiscoveredEvent.
class AppPlayerProvinceDiscoveredEvent extends GameToUIEvent {
  const AppPlayerProvinceDiscoveredEvent({
    required this.playerId,
    required this.provinceId,
    required this.turnNumber,
  });
  final String playerId;
  final String provinceId;
  final int turnNumber;
}

/// Player-scoped sea-zone charting. Mirrors colonizethis_logic PlayerSeaZoneDiscoveredEvent.
class AppPlayerSeaZoneDiscoveredEvent extends GameToUIEvent {
  const AppPlayerSeaZoneDiscoveredEvent({
    required this.playerId,
    required this.seaZoneId,
    required this.turnNumber,
  });
  final String playerId;
  final String seaZoneId;
  final int turnNumber;
}

/// Overture stage advanced. Mirrors colonizethis_logic OvertureAdvancedEvent.
class AppOvertureAdvancedEvent extends GameToUIEvent {
  const AppOvertureAdvancedEvent({
    required this.offererGpId,
    required this.targetFactionId,
    required this.newStage,
    required this.turnNumber,
  });
  final String offererGpId;
  final String targetFactionId;
  final String newStage;
  final int turnNumber;
}
