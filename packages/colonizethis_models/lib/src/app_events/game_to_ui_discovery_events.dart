/// Discovery mirror Game-to-UI events (Refs #4334 wave 3).
/// SPEC/program/game-event-bridge.md

import 'game_to_ui_event_base.dart';

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
