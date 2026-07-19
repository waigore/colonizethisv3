// Shared fixtures for expand_phase_planner_economy pin cases (Refs #4079 Slice D).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

const String kExpandEconomyGp1 = 'gp1';
const String kExpandEconomyGp2 = 'gp2';

/// Build a `Stockpile` whose [pendingRichesTreasuryDelta] equals
/// approximately [targetCash] (cash from spices at `spicesBasePrice = 50`).
/// Spices are chosen so the math is `qty × 50`; the helper rounds up to the
/// nearest whole spice unit so the resulting delta is always `>= targetCash`.
Stockpile expandEconomyStockpileWithPendingRiches(int targetCash) {
  if (targetCash <= 0) {
    return Stockpile.empty;
  }
  const pricePerSpice = 50;
  final qty = (targetCash + pricePerSpice - 1) ~/ pricePerSpice;
  return Stockpile(quantities: {'spices': qty});
}

/// Construct a [Player] with explicit treasury and stockpile so each
/// test can pin effective-treasury behaviour against arm B / arm C
/// boundaries without depending on default `Player` construction
/// changes elsewhere.
Player expandEconomyPlayer({
  String id = kExpandEconomyGp1,
  String displayName = 'GP1',
  int treasury = 0,
  Stockpile stockpile = Stockpile.empty,
}) {
  return Player(
    id: id,
    displayName: displayName,
    isHuman: false,
    treasury: treasury,
    stockpile: stockpile,
  );
}
