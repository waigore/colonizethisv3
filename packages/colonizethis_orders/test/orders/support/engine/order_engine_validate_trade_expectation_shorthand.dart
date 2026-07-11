// Compact order-engine validateTrade expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

const vetRegionId = 'oldWorld';

final vetTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: vetRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

const vetEmbassyOverture = [
  OvertureState(
    gpId: 'gp1',
    targetId: 'minor1',
    stage: OvertureStage.embassy,
    sinceTurn: 0,
  ),
];

Game vetGameWith({
  required Player player,
  List<OvertureState> overtures = const [],
}) => TestFixtures.minimalGame(
  id: 'g',
  turnNumber: 0,
  players: [player],
  overtureStates: overtures,
);

Player vetGp1({Stockpile? stockpile, int treasury = 0, bool isHuman = true}) =>
    Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: isHuman,
      stockpile: stockpile ?? Stockpile.empty,
      treasury: treasury,
    );

OrderEngine vetTradeEngine() => OrderEngine(projector: projectOrderEffects);

List<OrderValidationResult> vetValidate(Game game, OrderEngine engine) =>
    engine.validatePlayerOrdersWithContext(game, vetTopology, 'gp1');

OrderValidationResult vetAddTrade(
  Game game,
  OrderEngine engine,
  TradeOrder order,
) => engine.addTradeOrderWithContext(game, vetTopology, 'gp1', order);
