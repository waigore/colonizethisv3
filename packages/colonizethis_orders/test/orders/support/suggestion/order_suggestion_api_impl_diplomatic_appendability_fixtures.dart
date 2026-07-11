// Fixtures for diplomatic appendability scenarios (Refs #3949 wave 3,
// #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const diplomaticAppendabilityEmptyTopology = MapTopology(nodes: [], edges: []);

Game diplomaticAppendabilityTwoGpNeutralGame() => ordersTwoGpEmptyGame(
  players: ordersCommonTwoGpAb,
  state: RelationState.atPeace,
  level: RelationLevel.neutral,
);

Game diplomaticAppendabilityTwoGpAlliedGame() => ordersTwoGpEmptyGame(
  players: ordersCommonTwoGpAb,
  state: RelationState.atPeace,
  level: RelationLevel.allied,
);
