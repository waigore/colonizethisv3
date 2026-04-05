import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../orders/orders_application.dart';

Game runBuildWorkPhase(
  Game game,
  Orders orders,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion, {
  void Function(DialogueEvent)? onDialogue,
}) {
  return applyBuildAndWorkOrders(
    game,
    orders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
  );
}
