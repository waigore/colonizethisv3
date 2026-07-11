// Shared fixtures for worker-pool phase scenarios (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

/// Canonical ids for worker-pool phase expectation bodies.
abstract final class WppIds {
  static const player1 = 'p1';
  static const player2 = 'p2';
}

const wppApprenticeTech = {
  kTechIdApprenticeWorkers: true,
  kTechIdSugarRefining: true,
};

const wppJourneymanTech = {
  kTechIdTrainedJourneymen: true,
  kTechIdCigarProduction: true,
};

const wppMasterTech = {kTechIdMasterArtisans: true, kTechIdHatProduction: true};

Game wppEmptyWorldGame({required List<Player> players}) =>
    TestFixtures.minimalGame(id: 'g', turnNumber: 0, players: players);

Player wppPlayer({
  String id = WppIds.player1,
  String displayName = 'P',
  bool isHuman = true,
  Stockpile? stockpile,
  WorkerPool? workerPool,
  int treasury = 0,
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: id,
    displayName: displayName,
    isHuman: isHuman,
    stockpile: stockpile ?? const Stockpile(),
    workerPool: workerPool ?? const WorkerPool(),
    treasury: treasury,
    techUnlocked: techUnlocked ?? const {},
  );
}

Orders wppRecruitOrders(String playerId, List<WorkerTier> tiers) {
  return Orders(
    recruitWorkerOrdersByPlayerId: {
      playerId: tiers
          .map((tier) => RecruitWorkerOrder(targetTier: tier))
          .toList(growable: false),
    },
  );
}

Game wppApply(Game game, Orders orders) =>
    applyBuildAndWorkOrders(game, orders);

Player wppPlayerAfter(Game game, Orders orders, String playerId) =>
    wppApply(game, orders).players.firstWhere((p) => p.id == playerId);
