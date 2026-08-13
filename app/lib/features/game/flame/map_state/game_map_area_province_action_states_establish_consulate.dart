import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/order_suggestion_api.dart'
    show DiplomaticPanelAction, enumerateDiplomaticPanelActionsForTarget;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show explorerConsulateGateBlocksMinorTribeProvince;
import 'package:colonizethis_world/colonizethis_world.dart';

typedef ProvinceEstablishConsulateActionState = ({
  bool showControl,
  bool enabled,
  bool pending,
  String? ownerId,
  String? rejectionReason,
  DiplomaticOrder? order,
});

/// Validator-backed MAP20001 Political Consulate shortcut state (Refs #4346).
abstract final class GameMapAreaProvinceActionStatesEstablishConsulate {
  static const ProvinceEstablishConsulateActionState hidden = (
    showControl: false,
    enabled: false,
    pending: false,
    ownerId: null,
    rejectionReason: null,
    order: null,
  );

  static ProvinceEstablishConsulateActionState compute({
    required Game game,
    required String humanPlayerId,
    required String provinceId,
    required MapTopology? topology,
    required Orders currentOrders,
  }) {
    final ownerId = game.worldState.tryGetProvince(provinceId)?.ownerId;
    if (!explorerConsulateGateBlocksMinorTribeProvince(
      game: game,
      playerId: humanPlayerId,
      provinceOwnerId: ownerId,
    )) {
      return hidden;
    }
    if (ownerId == null || ownerId.isEmpty) return hidden;

    final order = DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: ownerId,
      overtureStage: OvertureStage.tradeConsulate,
    );
    final pending =
        currentOrders.diplomaticOrdersByPlayerId[humanPlayerId] ??
        const <DiplomaticOrder>[];
    final alreadyPending = pending.any(
      (candidate) =>
          candidate.type == DiplomaticOrderType.establishOverture &&
          candidate.targetFactionId == ownerId &&
          candidate.overtureStage == OvertureStage.tradeConsulate,
    );
    if (alreadyPending) {
      return (
        showControl: true,
        enabled: true,
        pending: true,
        ownerId: ownerId,
        rejectionReason: null,
        order: order,
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
      if (candidate.order.type == DiplomaticOrderType.establishOverture &&
          candidate.order.overtureStage == OvertureStage.tradeConsulate) {
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
      order: action.order,
    );
  }
}
