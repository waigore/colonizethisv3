import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show grantOrSubsidyDialogId;
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../map_state/game_map_area_state_logic.dart';

/// Grant Aid / Set Subsidy / Cancel taps for MAP20001 Political (Refs #4761).
VoidCallback? buildGrantOrSubsidyShortcutTap({
  required ct_models.Game game,
  required String humanPlayerId,
  required String provinceId,
  required ct_models.Orders draftOrders,
  required MapTopology? topology,
  required bool enabled,
  required bool pending,
  required String? ownerId,
  required ct_models.DiplomaticOrderType type,
  required ct_models.AppEventBus bus,
}) {
  if (!enabled || ownerId == null || ownerId.isEmpty) return null;
  if (pending) {
    return () => bus.emit(
      ct_models.RemoveDiplomaticOrderRequestedEvent(
        playerId: humanPlayerId,
        type: type,
        targetFactionId: ownerId,
      ),
    );
  }
  return () {
    final state = type == ct_models.DiplomaticOrderType.setSubsidy
        ? GameMapAreaStateLogicProvinceActions.provinceSetSubsidyActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            provinceId: provinceId,
            topology: topology,
            currentOrders: draftOrders,
          )
        : GameMapAreaStateLogicProvinceActions.provinceGrantAidActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            provinceId: provinceId,
            topology: topology,
            currentOrders: draftOrders,
          );
    if (!state.enabled || state.pending || state.ownerId == null) return;
    bus.emit(
      ct_models.OpenDialogEvent(grantOrSubsidyDialogId, {
        'targetFactionId': state.ownerId,
        'isSubsidy': type == ct_models.DiplomaticOrderType.setSubsidy,
      }),
    );
  };
}

({VoidCallback? onGrantAidTap, VoidCallback? onSetSubsidyTap})
buildGrantSubsidyShortcutTaps({
  required ct_models.Game game,
  required String humanPlayerId,
  required String provinceId,
  required ct_models.Orders draftOrders,
  required MapTopology? topology,
  required bool grantAidEnabled,
  required bool grantAidPending,
  required String? grantAidOwnerId,
  required bool setSubsidyEnabled,
  required bool setSubsidyPending,
  required String? setSubsidyOwnerId,
  required ct_models.AppEventBus bus,
}) {
  return (
    onGrantAidTap: buildGrantOrSubsidyShortcutTap(
      game: game,
      humanPlayerId: humanPlayerId,
      provinceId: provinceId,
      draftOrders: draftOrders,
      topology: topology,
      enabled: grantAidEnabled,
      pending: grantAidPending,
      ownerId: grantAidOwnerId,
      type: ct_models.DiplomaticOrderType.grantAid,
      bus: bus,
    ),
    onSetSubsidyTap: buildGrantOrSubsidyShortcutTap(
      game: game,
      humanPlayerId: humanPlayerId,
      provinceId: provinceId,
      draftOrders: draftOrders,
      topology: topology,
      enabled: setSubsidyEnabled,
      pending: setSubsidyPending,
      ownerId: setSubsidyOwnerId,
      type: ct_models.DiplomaticOrderType.setSubsidy,
      bus: bus,
    ),
  );
}
