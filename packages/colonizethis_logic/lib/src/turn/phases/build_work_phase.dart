import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../orders/orders_application.dart';
import '../trace/turn_trace_runtime.dart';

Game runBuildWorkPhase(
  Game game,
  Orders orders,
  MapTopology topology,
  Map<String, TileMapResult>? tileMapByRegion, {
  void Function(DialogueEvent)? onDialogue,
  WorkOrderTraceCallback? onWorkOrderTrace,
}) {
  return applyBuildAndWorkOrders(
    game,
    orders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    onDialogue: onDialogue,
    onWorkOrderTrace: onWorkOrderTrace,
  );
}
