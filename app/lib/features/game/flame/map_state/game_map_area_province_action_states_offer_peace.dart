import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show getRelation;
import 'package:colonizethis_logic/order_suggestion_api.dart'
    show DiplomaticPanelAction, enumerateDiplomaticPanelActionsForTarget;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show WorldStateProvinceLookup;

/// MAP20001 Political owner standing + wartime Offer Peace (Refs #4479).
typedef ProvinceOwnerStandingOfferPeaceState = ({
  bool showStanding,
  bool atWar,
  bool showAllianceBadge,
  bool showOfferPeaceControl,
  bool offerPeaceEnabled,
  bool offerPeacePending,
  String? ownerId,
  String? rejectionReason,
  DiplomaticOrder? order,
});

/// Validator-backed MAP20001 Political standing / Offer Peace state.
abstract final class GameMapAreaProvinceActionStatesOfferPeace {
  static const ProvinceOwnerStandingOfferPeaceState hidden = (
    showStanding: false,
    atWar: false,
    showAllianceBadge: false,
    showOfferPeaceControl: false,
    offerPeaceEnabled: false,
    offerPeacePending: false,
    ownerId: null,
    rejectionReason: null,
    order: null,
  );

  static ProvinceOwnerStandingOfferPeaceState compute({
    required Game game,
    required String humanPlayerId,
    required String provinceId,
    required MapTopology? topology,
    required Orders currentOrders,
    required bool isSeaZone,
  }) {
    if (isSeaZone) return hidden;
    final ownerId = game.worldState.tryGetProvince(provinceId)?.ownerId;
    if (ownerId == null || ownerId.isEmpty) return hidden;
    if (ownerId == humanPlayerId) return hidden;

    final relation = getRelation(game, humanPlayerId, ownerId);
    if (relation == null) return hidden;

    final atWar = relation.atWar;
    final showAllianceBadge = relation.formalAlliance;
    if (!atWar) {
      return (
        showStanding: true,
        atWar: false,
        showAllianceBadge: showAllianceBadge,
        showOfferPeaceControl: false,
        offerPeaceEnabled: false,
        offerPeacePending: false,
        ownerId: ownerId,
        rejectionReason: null,
        order: null,
      );
    }

    final order = DiplomaticOrder(
      type: DiplomaticOrderType.offerPeace,
      targetFactionId: ownerId,
    );
    final pending =
        currentOrders.diplomaticOrdersByPlayerId[humanPlayerId] ??
        const <DiplomaticOrder>[];
    final alreadyPending = pending.any(
      (candidate) =>
          candidate.type == DiplomaticOrderType.offerPeace &&
          candidate.targetFactionId == ownerId,
    );
    if (alreadyPending) {
      return (
        showStanding: true,
        atWar: true,
        showAllianceBadge: showAllianceBadge,
        showOfferPeaceControl: true,
        offerPeaceEnabled: true,
        offerPeacePending: true,
        ownerId: ownerId,
        rejectionReason: null,
        order: order,
      );
    }
    if (topology == null) {
      return (
        showStanding: true,
        atWar: true,
        showAllianceBadge: showAllianceBadge,
        showOfferPeaceControl: false,
        offerPeaceEnabled: false,
        offerPeacePending: false,
        ownerId: ownerId,
        rejectionReason: null,
        order: null,
      );
    }

    DiplomaticPanelAction? action;
    for (final candidate in enumerateDiplomaticPanelActionsForTarget(
      game: game,
      topology: topology,
      playerId: humanPlayerId,
      targetId: ownerId,
      currentOrders: currentOrders,
    )) {
      if (candidate.order.type == DiplomaticOrderType.offerPeace) {
        action = candidate;
        break;
      }
    }
    if (action == null) {
      return (
        showStanding: true,
        atWar: true,
        showAllianceBadge: showAllianceBadge,
        showOfferPeaceControl: false,
        offerPeaceEnabled: false,
        offerPeacePending: false,
        ownerId: ownerId,
        rejectionReason: null,
        order: null,
      );
    }
    return (
      showStanding: true,
      atWar: true,
      showAllianceBadge: showAllianceBadge,
      showOfferPeaceControl: true,
      offerPeaceEnabled: action.enabled,
      offerPeacePending: false,
      ownerId: ownerId,
      rejectionReason: action.rejectionReason,
      order: action.order,
    );
  }
}
