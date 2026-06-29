import 'package:colonizethis_logic/colonizethis_logic.dart'
    show ordersWithAppendedDiplomaticOrder;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared short label for diplomacy action buttons and confirmation prompts.
String diplomacyActionLabel(DiplomaticOrder order) {
  switch (order.type) {
    case DiplomaticOrderType.declareWar:
      return 'Declare War';
    case DiplomaticOrderType.offerPeace:
      return 'Offer Peace';
    case DiplomaticOrderType.alliance:
      return 'Alliance';
    case DiplomaticOrderType.breakAlliance:
      return 'Break Alliance';
    case DiplomaticOrderType.establishOverture:
      return order.overtureStage != null
          ? diplomacyOvertureStageShortLabel(order.overtureStage!)
          : 'Overture';
    case DiplomaticOrderType.grantAid:
      return 'Grant Aid';
    case DiplomaticOrderType.setSubsidy:
      return order.amount != null
          ? 'Set Subsidy (£${order.amount})'
          : 'Set Subsidy';
    case DiplomaticOrderType.establishFtp:
      return 'Establish FTP';
    case DiplomaticOrderType.boycott:
      return 'Boycott';
    case DiplomaticOrderType.revokeBoycott:
      return 'Revoke Boycott';
  }
}

/// Compact overture stage name used in diplomacy action labels.
String diplomacyOvertureStageShortLabel(OvertureStage stage) {
  return switch (stage) {
    OvertureStage.none => 'Overture',
    OvertureStage.tradeConsulate => 'Consulate',
    OvertureStage.embassy => 'Embassy',
    OvertureStage.nap => 'NAP',
    OvertureStage.joinEmpire => 'Join Empire',
  };
}

extension DiplomacyOrderMutations on Orders {
  Orders appendDiplomaticOrderForPlayer(
    String playerId,
    DiplomaticOrder order,
  ) => ordersWithAppendedDiplomaticOrder(this, playerId, order);

  Orders removeDiplomaticOrderForPlayer(
    String playerId, {
    required DiplomaticOrderType type,
    required String targetFactionId,
  }) {
    final list =
        List<DiplomaticOrder>.from(
          diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[],
        )..removeWhere(
          (o) => o.type == type && o.targetFactionId == targetFactionId,
        );
    return copyWith(
      diplomaticOrdersByPlayerId: {
        ...diplomaticOrdersByPlayerId,
        playerId: list,
      },
    );
  }
}
