import 'package:colonizethis_models/colonizethis_models.dart';

typedef _OrdersByPlayer<T> = Map<String, List<T>>;

_OrdersByPlayer<T> _appendOrdersByPlayer<T>(
  _OrdersByPlayer<T> source,
  String playerId,
  List<T> list,
) {
  final existing = source[playerId] ?? const [];
  return {...source, playerId: [...existing, ...list]};
}

extension OrdersAppendExtension on Orders {
  Orders appendMoveOrders(String playerId, List<MoveOrder> list) => copyWith(
    moveOrdersByPlayerId: _appendOrdersByPlayer(
      moveOrdersByPlayerId,
      playerId,
      list,
    ),
  );

  Orders appendBuildOrders(String playerId, List<BuildUnitOrder> list) =>
      copyWith(
        buildUnitOrdersByPlayerId: _appendOrdersByPlayer(
          buildUnitOrdersByPlayerId,
          playerId,
          list,
        ),
      );

  Orders appendWorkOrders(String playerId, List<WorkOrder> list) => copyWith(
    workOrdersByPlayerId: _appendOrdersByPlayer(
      workOrdersByPlayerId,
      playerId,
      list,
    ),
  );

  Orders appendResearchOrders(String playerId, List<ResearchOrder> list) =>
      copyWith(
        researchOrdersByPlayerId: _appendOrdersByPlayer(
          researchOrdersByPlayerId,
          playerId,
          list,
        ),
      );

  Orders appendNavalMoveOrders(String playerId, List<NavalMoveOrder> list) =>
      copyWith(
        navalMoveOrdersByPlayerId: _appendOrdersByPlayer(
          navalMoveOrdersByPlayerId,
          playerId,
          list,
        ),
      );

  Orders appendNavalMissionOrders(
    String playerId,
    List<NavalMissionOrder> list,
  ) => copyWith(
    navalMissionOrdersByPlayerId: _appendOrdersByPlayer(
      navalMissionOrdersByPlayerId,
      playerId,
      list,
    ),
  );

  Orders appendDiplomaticOrders(String playerId, List<DiplomaticOrder> list) =>
      copyWith(
        diplomaticOrdersByPlayerId: _appendOrdersByPlayer(
          diplomaticOrdersByPlayerId,
          playerId,
          list,
        ),
      );
}
