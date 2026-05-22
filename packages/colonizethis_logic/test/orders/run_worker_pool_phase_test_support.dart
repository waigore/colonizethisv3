/// Shared fixtures for `runWorkerPoolPhase` resolver tests
/// (`run_worker_pool_phase_test.dart`,
/// `run_worker_pool_phase_ordering_test.dart`). Refs #2692 S4.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const recruitTestPlayerId = 'p1';
const recruitTestOtherPlayerId = 'p2';
const recruitTestCapProvinceId = 'oldWorld|P1';

Game gameWithPlayer({
  required WorkerPool workerPool,
  required Stockpile stockpile,
  required int treasury,
  Map<String, bool> techUnlocked = const {},
  List<Player>? extraPlayers,
}) {
  final player = Player(
    id: recruitTestPlayerId,
    displayName: 'P1',
    isHuman: true,
    capitalProvinceId: recruitTestCapProvinceId,
    stockpile: stockpile,
    workerPool: workerPool,
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(
      provinces: [
        Province(
          id: recruitTestCapProvinceId,
          regionId: 'oldWorld',
          ownerId: recruitTestPlayerId,
        ),
      ],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  return Game(id: 'g', worldState: world, players: [player, ...?extraPlayers]);
}

Stockpile stockpileOf({int fabric = 0, int paper = 0}) {
  var s = const Stockpile();
  if (fabric > 0) {
    s = s.applyDelta(CommodityCatalog.fabric.id, fabric);
  }
  if (paper > 0) {
    s = s.applyDelta(CommodityCatalog.paper.id, paper);
  }
  return s;
}

Player playerOf(Game game, String id) =>
    game.players.firstWhere((p) => p.id == id);
