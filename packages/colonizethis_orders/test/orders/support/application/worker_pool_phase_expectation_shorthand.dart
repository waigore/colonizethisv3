// Compact worker-pool phase expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'worker_pool_phase_fixtures.dart';

Stockpile wppStock(Map<String, int> quantities) =>
    Stockpile(quantities: quantities);

Player wppAfter(Player player, List<WorkerTier> tiers) => wppPlayerAfter(
  wppEmptyWorldGame(players: [player]),
  wppRecruitOrders(WppIds.player1, tiers),
  WppIds.player1,
);

void wppExpect(
  Player p, {
  int? peasants,
  int? apprentices,
  int? journeymen,
  int? masters,
  Map<String, int>? stock,
  int? treasury,
  String? peasantsReason,
  String? apprenticesReason,
  String? journeymenReason,
  String? mastersReason,
  String? treasuryReason,
  Map<String, String>? stockReasons,
}) {
  if (peasants != null) {
    expect(p.workerPool.peasants, peasants, reason: peasantsReason);
  }
  if (apprentices != null) {
    expect(p.workerPool.apprentices, apprentices, reason: apprenticesReason);
  }
  if (journeymen != null) {
    expect(p.workerPool.journeymen, journeymen, reason: journeymenReason);
  }
  if (masters != null) {
    expect(p.workerPool.masters, masters, reason: mastersReason);
  }
  if (stock != null) {
    for (final entry in stock.entries) {
      expect(
        p.stockpile.quantityOf(entry.key),
        entry.value,
        reason: stockReasons?[entry.key],
      );
    }
  }
  if (treasury != null) {
    expect(p.treasury, treasury, reason: treasuryReason);
  }
}

void wppExpectApprenticeTrain({
  required int paper,
  required int peasants,
  required int treasury,
  required int expectedPeasants,
  required int expectedPaper,
  required int expectedTreasury,
  Map<String, bool>? techUnlocked,
}) {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: paper}),
      workerPool: WorkerPool(peasants: peasants),
      treasury: treasury,
      techUnlocked: techUnlocked ?? wppApprenticeTech,
    ),
    [WorkerTier.apprentice],
  );
  wppExpect(
    p,
    peasants: expectedPeasants,
    apprentices: 1,
    stock: {CommodityCatalog.paper.id: expectedPaper},
    treasury: expectedTreasury,
  );
}

void wppExpectJourneymanTrain({
  required int paper,
  required int peasants,
  required int treasury,
  required int expectedPeasants,
  required int expectedPaper,
  required int expectedTreasury,
  String? peasantsReason,
  String? journeymenReason,
  Map<String, String>? stockReasons,
  String? treasuryReason,
}) {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: paper}),
      workerPool: WorkerPool(peasants: peasants),
      treasury: treasury,
      techUnlocked: wppJourneymanTech,
    ),
    [WorkerTier.journeyman],
  );
  wppExpect(
    p,
    peasants: expectedPeasants,
    journeymen: 1,
    stock: {CommodityCatalog.paper.id: expectedPaper},
    treasury: expectedTreasury,
    peasantsReason: peasantsReason,
    journeymenReason: journeymenReason,
    stockReasons: stockReasons,
    treasuryReason: treasuryReason,
  );
}

void wppExpectMasterTrain({
  required int paper,
  required int peasants,
  required int treasury,
  required int expectedPeasants,
  required int expectedPaper,
  required int expectedTreasury,
  String? peasantsReason,
  String? mastersReason,
  Map<String, String>? stockReasons,
  String? treasuryReason,
}) {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: paper}),
      workerPool: WorkerPool(peasants: peasants),
      treasury: treasury,
      techUnlocked: wppMasterTech,
    ),
    [WorkerTier.master],
  );
  wppExpect(
    p,
    peasants: expectedPeasants,
    masters: 1,
    stock: {CommodityCatalog.paper.id: expectedPaper},
    treasury: expectedTreasury,
    peasantsReason: peasantsReason,
    mastersReason: mastersReason,
    stockReasons: stockReasons,
    treasuryReason: treasuryReason,
  );
}

void wppExpectMasterTrainSkipped({
  required int paper,
  required int peasants,
  required int treasury,
  required Map<String, bool> techUnlocked,
}) {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: paper}),
      workerPool: WorkerPool(peasants: peasants),
      treasury: treasury,
      techUnlocked: techUnlocked,
    ),
    [WorkerTier.master],
  );
  wppExpect(
    p,
    peasants: peasants,
    masters: 0,
    stock: {CommodityCatalog.paper.id: paper},
    treasury: treasury,
    peasantsReason: 'peasant not consumed',
    mastersReason: 'master not added',
    stockReasons: {CommodityCatalog.paper.id: 'no paper deducted'},
    treasuryReason: 'no treasury deducted',
  );
}

void wppExpectSequentialTiers({
  required Map<String, int> stock,
  required int peasants,
  required int treasury,
  required List<WorkerTier> tiers,
  required int expectedPeasants,
  required int expectedApprentices,
  required Map<String, int> expectedStock,
  required int expectedTreasury,
  String? peasantsReason,
  String? apprenticesReason,
  Map<String, String>? stockReasons,
  String? treasuryReason,
  Map<String, bool>? techUnlocked,
}) {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock(stock),
      workerPool: WorkerPool(peasants: peasants),
      treasury: treasury,
      techUnlocked: techUnlocked ?? wppApprenticeTech,
    ),
    tiers,
  );
  wppExpect(
    p,
    peasants: expectedPeasants,
    apprentices: expectedApprentices,
    stock: expectedStock,
    treasury: expectedTreasury,
    peasantsReason: peasantsReason,
    apprenticesReason: apprenticesReason,
    stockReasons: stockReasons,
    treasuryReason: treasuryReason,
  );
}

void wppExpectMultiPlayerApprenticeIsolation() {
  final apprenticePlayer = wppPlayer(
    stockpile: wppStock({CommodityCatalog.paper.id: 4}),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 300,
    techUnlocked: wppApprenticeTech,
  );
  final game = wppEmptyWorldGame(
    players: [
      apprenticePlayer,
      wppPlayer(
        id: WppIds.player2,
        displayName: 'B',
        isHuman: false,
        stockpile: wppStock({CommodityCatalog.paper.id: 4}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 300,
        techUnlocked: wppApprenticeTech,
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      WppIds.player1: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
      WppIds.player2: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
    },
  );
  final result = wppApply(game, orders);
  for (final playerId in [WppIds.player1, WppIds.player2]) {
    final p = result.players.firstWhere((p) => p.id == playerId);
    wppExpect(
      p,
      peasants: 1,
      apprentices: 1,
      stock: {CommodityCatalog.paper.id: 2},
      treasury: 100,
    );
  }
}
