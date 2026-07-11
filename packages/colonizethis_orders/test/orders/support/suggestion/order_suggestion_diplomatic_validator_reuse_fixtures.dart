// Diplomatic validator-reuse scenario fixtures (Refs #2394, #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const _emptyTopology = MapTopology(nodes: [], edges: []);

/// Two GPs at peace: each target's non-economic pass accepts [alliance]; the
/// economic pass must rebind via [forBasePrefix], not rebuild validators.
Game dvrTwoGpPeaceGame() => ordersTwoGpEmptyGame(
  id: 'g_diplomatic_validator_reuse',
  players: ordersCommonTwoAiGps,
  state: RelationState.atPeace,
  level: RelationLevel.neutral,
);

Game dvrThreeGpPeaceGame() => ordersThreeGpEmptyGame(id: 'g_diplomatic_rebind');

MapTopology get dvrEmptyTopology => _emptyTopology;
