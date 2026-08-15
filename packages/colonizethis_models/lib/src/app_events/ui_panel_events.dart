/// Panel open/close UI actions (Refs #4334 wave 3).

import 'ui_action_event_base.dart';

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
    this.engineerOnly = false,
    this.railBuilderOnly = false,
    this.merchantOnly = false,
    this.prospectShortcutTargetTileKey,
    this.exploreShortcutTargetTileKey,
    this.buildImprovementShortcutTargetTileKey,
    this.buildRoadShortcutTargetTileKey,
    this.buildFortShortcutTargetTileKey,
    this.buildPortShortcutTargetTileKey,
    this.buildRailShortcutTargetTileKey,
    this.purchaseLandShortcutTargetTileKey,
    this.upgradeTownShortcutTargetTileKey,
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

  /// Optional panel filter mode for engineer-only rows.
  final bool engineerOnly;

  /// Optional panel filter mode for Rail Builder-only rows (Refs #4383).
  final bool railBuilderOnly;

  /// Optional panel filter mode for merchant-only rows.
  final bool merchantOnly;

  /// Optional tile key used by the province prospect shortcut flow.
  final String? prospectShortcutTargetTileKey;

  /// Optional tile key used by the province explore shortcut flow.
  final String? exploreShortcutTargetTileKey;

  /// Optional tile key used by the province build-improvement shortcut flow.
  final String? buildImprovementShortcutTargetTileKey;

  /// Optional tile key used by the province build-road shortcut flow.
  final String? buildRoadShortcutTargetTileKey;

  /// Optional tile key used by the province build-fort shortcut flow.
  final String? buildFortShortcutTargetTileKey;

  /// Optional tile key used by the province build-port shortcut flow.
  final String? buildPortShortcutTargetTileKey;

  /// Optional tile key used by the province build-railroad shortcut flow.
  final String? buildRailShortcutTargetTileKey;

  /// Optional tile key used by the province purchase-land shortcut flow.
  final String? purchaseLandShortcutTargetTileKey;

  /// Optional tile key used by the province upgrade-town shortcut flow.
  final String? upgradeTownShortcutTargetTileKey;
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

/// Map fleet-marker shortcut: routes to Naval Units (Home Fleet), Move (in
/// port), or mission + Sail (at sea) (Refs #4343).
class OpenNavalMissionMenuEvent extends UIActionEvent {
  const OpenNavalMissionMenuEvent({
    required this.locationScopeKey,
    required this.fleetIds,
    this.initialSelectedFleetId,
    this.tileScopeTileKey,
  });

  final String locationScopeKey;
  final List<String> fleetIds;
  final String? initialSelectedFleetId;
  final String? tileScopeTileKey;
}

/// Map army-stack marker shortcut: field armies with destinations → overlay
/// Move; non-empty Home Army in the stack otherwise → detach-then-move;
/// empty Home-only → Military Units panel (Refs #4384, #4407).
class OpenArmyStackMarkerEvent extends UIActionEvent {
  const OpenArmyStackMarkerEvent({
    required this.provinceId,
    required this.armyIds,
    required this.fieldArmyIds,
    required this.tileKey,
  });

  final String provinceId;
  final List<String> armyIds;
  final List<String> fieldArmyIds;
  final String tileKey;
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

/// Emitted when a typed units panel route is dismissed.
class UnitsPanelClosedEvent extends UIActionEvent {
  const UnitsPanelClosedEvent(this.panel);

  final String panel;
}

/// Request to open the province/sea zone detail overlay for [provinceId].
/// Emitted by the map widget when user taps a town or port icon.
/// SPEC/ui/town-port-icons.md.
class OpenProvinceDetailPanelEvent extends UIActionEvent {
  const OpenProvinceDetailPanelEvent(this.provinceId);
  final String provinceId;
}

/// Request to open the province/tile detail panel for a concrete map tile key.
class OpenMapTileDetailEvent extends UIActionEvent {
  const OpenMapTileDetailEvent({required this.tileKey});

  final String tileKey;
}
