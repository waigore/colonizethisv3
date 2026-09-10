import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/order_suggestion_api.dart'
    show DiplomaticPanelAction, enumerateDiplomaticPanelActionsForTarget;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show grantSubsidyShortcutAppliesToMinorTribeProvince;
import 'package:colonizethis_world/colonizethis_world.dart';

typedef ProvinceGrantSubsidyActionState = ({
  bool showControl,
  bool enabled,
  bool pending,
  String? ownerId,
  String? rejectionReason,
});

/// Validator-backed MAP20001 Political Grant Aid / Set Subsidy state
/// (Refs #4761).
abstract final class GameMapAreaProvinceActionStatesGrantSubsidy {
  static const ProvinceGrantSubsidyActionState hidden = (
    showControl: false,
    enabled: false,
    pending: false,
    ownerId: null,
    rejectionReason: null,
  );

  static ProvinceGrantSubsidyActionState compute({
    required Game game,
    required String humanPlayerId,
    required String provinceId,
    required MapTopology? topology,
    required Orders currentOrders,
    required DiplomaticOrderType type,
  }) {
    final ownerId = game.worldState.tryGetProvince(provinceId)?.ownerId;
    if (!grantSubsidyShortcutAppliesToMinorTribeProvince(
      game: game,
      playerId: humanPlayerId,
      provinceOwnerId: ownerId,
    )) {
      return hidden;
    }
    if (ownerId == null || ownerId.isEmpty) return hidden;

    final pending =
        currentOrders.diplomaticOrdersByPlayerId[humanPlayerId] ??
        const <DiplomaticOrder>[];
    final alreadyPending = pending.any(
      (candidate) =>
          candidate.type == type && candidate.targetFactionId == ownerId,
    );
    if (alreadyPending) {
      return (
        showControl: true,
        enabled: true,
        pending: true,
        ownerId: ownerId,
        rejectionReason: null,
      );
    }
    if (topology == null) return hidden;

    DiplomaticPanelAction? action;
    for (final candidate in enumerateDiplomaticPanelActionsForTarget(
      game: game,
      topology: topology,
      playerId: humanPlayerId,
      targetId: ownerId,
      currentOrders: currentOrders,
    )) {
      if (candidate.order.type == type) {
        action = candidate;
        break;
      }
    }
    if (action == null) return hidden;
    return (
      showControl: true,
      enabled: action.enabled,
      pending: false,
      ownerId: ownerId,
      rejectionReason: action.rejectionReason,
    );
  }
}
