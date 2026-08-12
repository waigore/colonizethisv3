/// Orders mirror Game-to-UI events (Refs #4334 wave 3).
/// SPEC/program/game-event-bridge.md

import '../order_kind.dart';
import 'game_to_ui_event_base.dart';

/// Order rejected during validation. Mirrors colonizethis_logic OrderRejectedEvent.
class AppOrderRejectedEvent extends GameToUIEvent {
  const AppOrderRejectedEvent({
    required this.playerId,
    required this.orderKind,
    required this.orderSummary,
    required this.reasonCode,
  });
  final String playerId;
  final OrderKind orderKind;
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
