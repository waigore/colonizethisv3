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

void wppExpectRecruitPeasantFromFabric({int fabric = 3}) {
  final p = wppAfter(
    wppPlayer(stockpile: wppStock({CommodityCatalog.fabric.id: fabric})),
    [WorkerTier.peasant],
  );
  wppExpect(
    p,
    peasants: 1,
    stock: {CommodityCatalog.fabric.id: fabric - 2},
    treasury: 0,
  );
}

void wppExpectApprenticeTrainSkippedWhenUnaffordable({
  required int paper,
  required int peasants,
  required int treasury,
}) {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: paper}),
      workerPool: WorkerPool(peasants: peasants),
      treasury: treasury,
      techUnlocked: wppApprenticeTech,
    ),
    [WorkerTier.apprentice],
  );
  wppExpect(
    p,
    peasants: peasants,
    apprentices: 0,
    stock: {CommodityCatalog.paper.id: paper},
    treasury: treasury,
  );
}

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

void wppExpectJourneymanTrain2692S9() {
  wppExpectJourneymanTrain(
    paper: 8,
    peasants: 2,
    treasury: 700,
    expectedPeasants: 1,
    expectedPaper: 3,
    expectedTreasury: 200,
    peasantsReason: 'one peasant consumed',
    journeymenReason: 'one journeyman added',
    stockReasons: {
      CommodityCatalog.paper.id: '5 paper deducted per SPEC § Recruiting cost table',
    },
    treasuryReason: '500 ducats deducted per SPEC § Recruiting cost table',
  );
}

void wppExpectMasterTrain2692S9() {
  wppExpectMasterTrain(
    paper: 12,
    peasants: 1,
    treasury: 1200,
    expectedPeasants: 0,
    expectedPaper: 2,
    expectedTreasury: 200,
    peasantsReason: 'one peasant consumed',
    mastersReason: 'one master added',
    stockReasons: {
      CommodityCatalog.paper.id: '10 paper deducted per SPEC § Recruiting cost table',
    },
    treasuryReason: '1000 ducats deducted per SPEC § Recruiting cost table',
  );
}

void wppExpectMasterTrainSkipped2692S9TechGate() {
  wppExpectMasterTrainSkipped(
    paper: 12,
    peasants: 1,
    treasury: 1200,
    techUnlocked: const {kTechIdMasterArtisans: true},
  );
}

void wppExpectSequentialPeasantThenApprentice2692S9() {
  wppExpectSequentialTiers(
    stock: {
      CommodityCatalog.fabric.id: 2,
      CommodityCatalog.paper.id: 2,
    },
    peasants: 0,
    treasury: 200,
    tiers: [WorkerTier.peasant, WorkerTier.apprentice],
    expectedPeasants: 0,
    expectedApprentices: 1,
    expectedStock: {
      CommodityCatalog.fabric.id: 0,
      CommodityCatalog.paper.id: 0,
    },
    expectedTreasury: 0,
    peasantsReason:
        'recruited peasant immediately consumed by the apprentice train',
    apprenticesReason: 'one apprentice added',
    stockReasons: {
      CommodityCatalog.fabric.id: 'peasant recruit consumed 2 fabric',
      CommodityCatalog.paper.id: 'apprentice train consumed 2 paper',
    },
    treasuryReason: 'apprentice train consumed 200 ducats',
  );
}

void wppExpectSequentialApprenticeSkipThenPeasant2692S9() {
  wppExpectSequentialTiers(
    stock: {
      CommodityCatalog.fabric.id: 4,
      CommodityCatalog.paper.id: 4,
    },
    peasants: 1,
    treasury: 400,
    tiers: [WorkerTier.apprentice, WorkerTier.apprentice, WorkerTier.peasant],
    expectedPeasants: 1,
    expectedApprentices: 1,
    expectedStock: {
      CommodityCatalog.paper.id: 2,
      CommodityCatalog.fabric.id: 2,
    },
    expectedTreasury: 200,
    peasantsReason:
        'apprentice consumed initial peasant; peasant recruit added 1',
    apprenticesReason: 'only the first apprentice train fired; second skipped',
    stockReasons: {
      CommodityCatalog.paper.id: 'one apprentice consumed 2 paper; second order did not',
      CommodityCatalog.fabric.id: 'trailing peasant recruit still consumed 2 fabric',
    },
    treasuryReason: 'only one apprentice train deducted treasury',
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
