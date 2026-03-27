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
    case DiplomaticOrderType.establishOverture:
      return order.overtureStage != null
          ? diplomacyOvertureStageShortLabel(order.overtureStage!)
          : 'Overture';
    case DiplomaticOrderType.grantAid:
      return order.amount != null
          ? 'Grant Aid (£${order.amount})'
          : 'Grant Aid';
    case DiplomaticOrderType.setSubsidy:
      return order.amount != null
          ? 'Subsidy (£${order.amount})'
          : 'Set Subsidy';
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
  ) {
    final list = List<DiplomaticOrder>.from(
      diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[],
    )..add(order);
    return copyWith(
      diplomaticOrdersByPlayerId: {
        ...diplomaticOrdersByPlayerId,
        playerId: list,
      },
    );
  }

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
