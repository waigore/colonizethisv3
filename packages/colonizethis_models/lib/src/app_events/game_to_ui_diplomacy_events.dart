/// Diplomacy and ownership mirror Game-to-UI events (Refs #4334 wave 3).
/// SPEC/program/game-event-bridge.md

import 'game_to_ui_event_base.dart';

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
