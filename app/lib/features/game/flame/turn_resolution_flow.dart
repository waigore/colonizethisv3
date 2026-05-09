import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

TurnResolutionResult resolveNextTurnForGameScreen({
  required Game game,
  required Orders orders,
  required MapTopology topologyForAi,
  Map<String, TileMapResult>? tileMapByRegion,
  required TurnResolutionResult Function({
    required Orders orders,
    Orders? aiOrders,
    List<TurnTraceAiSection>? aiTraceSections,
  })
  runTurnResolution,
}) {
  final aiResult = generateOrdersForGameFullAI(
    game,
    topologyForAi,
    tileMapByRegion: tileMapByRegion,
  );
  return runTurnResolution(
    orders: orders,
    aiOrders: aiResult.orders,
    aiTraceSections: aiResult.aiTraceSections,
  );
}
