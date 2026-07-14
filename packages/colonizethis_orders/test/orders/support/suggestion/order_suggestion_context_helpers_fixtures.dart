// Shared fixtures for order suggestion context helper scenarios (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../common/game_graphs.dart';

final oschMinimalGame = TestFixtures.minimalGame(
  id: 'g1',
  turnNumber: 1,
  players: const [Player(id: 'gp1', displayName: 'P1', isHuman: true)],
);

const oschEmptyTopology = MapTopology(nodes: [], edges: []);

Game oschDiplomacyGame() =>
    ordersTwoGpEmptyGame(id: 'g1', turnNumber: 1, players: ordersCommonTwoGpAb);

const oschAllianceCandidate = DiplomaticOrder(
  type: DiplomaticOrderType.alliance,
  targetFactionId: 'gp2',
);
