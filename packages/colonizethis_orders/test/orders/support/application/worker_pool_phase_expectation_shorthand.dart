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
