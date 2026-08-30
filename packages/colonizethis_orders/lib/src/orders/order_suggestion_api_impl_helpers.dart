import 'package:colonizethis_data/colonizethis_data.dart';
import 'orders_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

List<T> suggestWithLog<T>(
  String method,
  String playerId,
  List<T> Function() run,
) {
  ordersLog.d('order suggestion API $method player=$playerId');
  return run();
}

/// Bundles the four standard suggest* parameters for delegation (Refs #3500).
class StandardSuggestContext {
  const StandardSuggestContext({
    required this.view,
    required this.game,
    required this.topology,
    required this.currentOrders,
  });

  final PlayerView view;
  final Game game;
  final MapTopology topology;
  final Orders currentOrders;

  List<T> loggedSuggest<T>(String method, List<T> Function() invoke) =>
      suggestWithLog(method, view.playerId, invoke);
}

StandardSuggestContext standardSuggestContext({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
}) => StandardSuggestContext(
  view: view,
  game: game,
  topology: topology,
  currentOrders: currentOrders,
);
