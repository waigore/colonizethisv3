import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show OvertureStageChain;
export 'order_suggestion_probe.dart';

final orderSuggestionLog = CtLogger('orders.order_suggestion');

Orders appendDiplomaticOrderForTrial(
  Orders orders,
  String playerId,
  DiplomaticOrder order,
) {
  final prev =
      orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[];
  return orders.copyWith(
    diplomaticOrdersByPlayerId: {
      ...orders.diplomaticOrdersByPlayerId,
      playerId: [...prev, order],
    },
  );
}
