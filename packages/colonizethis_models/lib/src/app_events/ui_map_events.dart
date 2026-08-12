/// Map camera and locate UI actions (Refs #4334 wave 3).

import 'ui_action_event_base.dart';

/// Request to center/highlight a map tile. To close a units sheet first, emit [ClosePanelEvent]
/// before this event (same synchronous turn or after [SchedulerBinding] frame); do not dismiss sheets from the map widget.
class LocateMapTileEvent extends UIActionEvent {
  const LocateMapTileEvent({required this.tileKey, required this.regionId});

  final String tileKey;
  final String regionId;
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
