import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show buildDiplomacyConfirmPreviewMessage;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../widgets/diplomacy/diplomacy_order_helpers.dart'
    show diplomacyActionLabel;
import '../map_state/game_map_area_state_logic.dart';

/// Builds the Offer Peace / Cancel pending-peace shortcut tap for MAP20001
/// Political when the province owner is at war with the human (Refs #4479).
VoidCallback? buildOfferPeaceShortcutTap({
  required ct_models.Game game,
  required String humanPlayerId,
  required String provinceId,
  required ct_models.Orders draftOrders,
  required MapTopology? topology,
  required bool isSeaZone,
  required bool enabled,
  required bool pending,
  required ct_models.DiplomaticOrder? order,
  required String targetName,
  required ct_models.AppEventBus bus,
}) {
  if (!enabled || order == null) return null;
  if (pending) {
    return () => bus.emit(
      ct_models.RemoveDiplomaticOrderRequestedEvent(
        playerId: humanPlayerId,
        type: ct_models.DiplomaticOrderType.offerPeace,
        targetFactionId: order.targetFactionId,
      ),
    );
  }
  return () {
    final state =
        GameMapAreaStateLogicProvinceActions.provinceOfferPeaceActionState(
      game: game,
      humanPlayerId: humanPlayerId,
      provinceId: provinceId,
      topology: topology,
      currentOrders: draftOrders,
      isSeaZone: isSeaZone,
    );
    if (!state.showOfferPeaceControl ||
        !state.offerPeaceEnabled ||
        state.offerPeacePending ||
        state.order == null) {
      return;
    }
    final validatedOrder = state.order!;
    bus.emit(
      ct_models.ConfirmDialogEvent(
        title: diplomacyActionLabel(validatedOrder),
        message: buildDiplomacyConfirmPreviewMessage(
          order: validatedOrder,
          game: game,
          humanPlayerId: humanPlayerId,
          targetDisplayName: targetName,
        ),
        onResult: (confirmed) {
          if (!confirmed) return;
          bus.emit(
            ct_models.AppendDiplomaticOrderRequestedEvent(
              playerId: humanPlayerId,
              order: validatedOrder,
            ),
          );
        },
      ),
    );
  };
}
