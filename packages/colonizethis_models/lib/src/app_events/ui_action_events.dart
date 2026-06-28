part of '../app_events.dart';

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
