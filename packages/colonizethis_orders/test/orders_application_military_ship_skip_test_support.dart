import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void expectShipBuildSpentButNoFleet({
  required Game next,
  required Player baselinePlayer,
  required Stockpile baselineStockpile,
  required int buildTreasuryCost,
  required Map<String, int> buildInputs,
}) {
  expect(next.worldState.fleets, isEmpty);
  final nextPlayer = next.players.single;
  expect(nextPlayer.treasury, baselinePlayer.treasury - buildTreasuryCost);
  expect(nextPlayer.workerPool.peasants, 0);
  for (final entry in buildInputs.entries) {
    expect(
      nextPlayer.stockpile.quantityOf(entry.key),
      baselineStockpile.quantityOf(entry.key) - entry.value,
    );
  }
}
