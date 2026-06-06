part of 'treasury_planner.dart';

// Lock-recovery seller predicate and designated/liquidity buyer rotation for
// the treasury planner (Refs #2924 F11–F17 + #2847 H8), extracted from
// `treasury_planner.dart` for maintainability (Refs #3288 file-split).
// Behaviour-preserving move: same library scope (this is a `part of` the
// treasury-planner library), so imports, shared helpers, and visibility are
// unchanged.

int _treasuryForPlayer(Game game, String playerId) =>
    game.playerById(playerId)?.treasury ?? 0;

int _oldWorldProvinceCountOwnedBy(
  Game game,
  String playerId, {
  AIWorldSnapshot? snapshot,
}) {
  if (snapshot != null && snapshot.playerId == playerId) {
    return snapshot.conquest.oldWorldProvincesOwned;
  }
  return oldWorldProvinceCountOwnedBy(game, playerId);
}

int _newWorldProvinceCountOwnedBy(
  Game game,
  String playerId, {
  AIWorldSnapshot? snapshot,
}) {
  if (snapshot != null && snapshot.playerId == playerId) {
    return snapshot.colonial.newWorldProvincesOwned;
  }
  var count = 0;
  for (final province in game.worldState.newWorld.provinces) {
    if (province.ownerId == playerId) count++;
  }
  return count;
}

/// Below-quota GPs with zero NW provinces and at least one OW province
/// are Path F lock-recovery **sellers** — they must accumulate seller
/// credits toward the regiment threshold, not rotate as the affluent
/// designated buyer or speculate (Refs #2924 Path F gp6 regression).
bool _isBelowQuotaZeroNwLockRecoverySeller({
  required Game game,
  required String playerId,
  AIWorldSnapshot? snapshot,
}) {
  final ow = _oldWorldProvinceCountOwnedBy(
    game,
    playerId,
    snapshot: snapshot,
  );
  if (ow <= 0) return false;
  if (!isBelowObserverConquestQuota(ow)) return false;
  if (_newWorldProvinceCountOwnedBy(game, playerId, snapshot: snapshot) != 0) {
    return false;
  }
  // Mid-below-quota EXPAND band (seed-42 gp3–gp6); excludes minimal
  // single-province test fixtures that are not Path F lock-recovery sellers.
  return ow >= 2;
}

/// True when any below-quota zero-NW lock-recovery seller still needs the
/// H8 regiment build-input bootstrap path (Refs #2847 H8-supply market).
bool _anyLockRecoverySellerNeedsRegimentBuildInput(Game game) {
  final threshold = cheapestRegimentBuildTreasuryCost();
  for (final player in game.players) {
    if (!_isBelowQuotaZeroNwLockRecoverySeller(
      game: game,
      playerId: player.id,
    )) {
      continue;
    }
    if (player.treasury < threshold) continue;
    if (regimentCountForPlayer(game, player.id) > 0) continue;
    for (final entry
        in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
      if (player.stockpile.quantityOf(entry.key) < entry.value) {
        return true;
      }
    }
  }
  return false;
}

/// Public accessor for the below-quota zero-NW lock-recovery seller predicate
/// (Refs #2847 H8-supply castIron source). The economy planner uses it to keep
/// the supplier `castIron` over-production off for a GP that is itself a locked
/// seller (its own self-path boost already covers it).
bool isBelowQuotaZeroNwLockRecoverySeller(
  Game game,
  String playerId, {
  AIWorldSnapshot? snapshot,
}) =>
    _isBelowQuotaZeroNwLockRecoverySeller(
      game: game,
      playerId: playerId,
      snapshot: snapshot,
    );

/// True when any below-quota zero-NW lock-recovery seller still lacks a
/// domestically-produced level-0 `build_improvement` input (a
/// [kDomesticProductionImprovementInputIds] commodity such as `castIron`) the
/// world market structurally cannot supply on seed 42 (Refs #2847 H8-supply
/// castIron source). When true, an affluent supplier over-produces that input
/// for release (`economy_planner.dart`) and this planner releases the resulting
/// surplus + aligns its offer tier so the locked seller's bid can cross.
/// Pure function of `(game)` and the static catalogs; returns `false` once no
/// locked seller still needs the improvement input (self-clearing).
bool anyLockRecoverySellerNeedsCastIronImprovementInput(Game game) {
  for (final player in game.players) {
    if (!_isBelowQuotaZeroNwLockRecoverySeller(
      game: game,
      playerId: player.id,
    )) {
      continue;
    }
    final cost = regimentBuildInputFeedstockImprovementInputCost(
      game,
      player.id,
    );
    if (cost.isEmpty) continue;
    for (final entry in cost.entries) {
      if (!kDomesticProductionImprovementInputIds.contains(entry.key)) {
        continue;
      }
      if (player.stockpile.quantityOf(entry.key) < entry.value) {
        return true;
      }
    }
  }
  return false;
}

/// Sorted Great Power ids for deterministic per-turn buyer rotation.
List<String> _sortedGreatPowerIds(Game game) {
  final ids = <String>[
    for (final player in game.players) player.id,
  ]..sort();
  return ids;
}

/// True iff at least one Great Power has `player.treasury <
/// cheapestRegimentBuildTreasuryCost()`. The lock-recovery liquidity bid is
/// only useful when at least one broke GP needs buy-side demand for its
/// urgent offers. Refs #2924 F12.
bool _anyBrokeGreatPower(Game game) {
  final threshold = cheapestRegimentBuildTreasuryCost();
  for (final player in game.players) {
    if (player.treasury < threshold) return true;
  }
  return false;
}

bool _isAffluentDesignatedLockRecoveryBuyer({
  required Game game,
  required String playerId,
}) {
  if (!_anyBrokeGreatPower(game)) return false;
  final gpIds = _sortedGreatPowerIds(game);
  final affluent = <String>[
    for (final id in gpIds)
      if (_treasuryForPlayer(game, id) >= treasuryAffluenceThreshold() &&
          !_isBelowQuotaZeroNwLockRecoverySeller(game: game, playerId: id))
        id,
  ];
  if (affluent.isEmpty) return false;
  final designated = lockRecoveryDesignatedBuyerId(game);
  return designated.isNotEmpty && playerId == designated;
}

/// Whether [playerId] should emit the urgent lock-recovery liquidity-food bid
/// this turn. Refs #2924 F11/F12/F13/F15.
bool isLockRecoveryLiquidityBuyer({
  required Game game,
  required String playerId,
  required int treasuryBudgetForBids,
  required int treasuryForecast,
}) {
  if (!_anyBrokeGreatPower(game)) return false;
  final liquidity = _lockRecoveryLiquidityCommodity(game.worldMarketState);
  final pricePerUnit = game.worldMarketState.prices[liquidity] ?? 0;
  if (pricePerUnit <= 0 || treasuryBudgetForBids < pricePerUnit) {
    return false;
  }
  final threshold = cheapestRegimentBuildTreasuryCost();
  final rawTreasury = _treasuryForPlayer(game, playerId);
  // F13: optimistic offer-inflow forecast keeps a broke GP on offers-only.
  if (rawTreasury < threshold && treasuryForecast >= threshold) {
    return false;
  }
  final gpIds = _sortedGreatPowerIds(game);
  final affluent = <String>[
    for (final id in gpIds)
      if (_treasuryForPlayer(game, id) >= treasuryAffluenceThreshold() &&
          !_isBelowQuotaZeroNwLockRecoverySeller(game: game, playerId: id))
        id,
  ];
  if (affluent.isNotEmpty) {
    final designated = lockRecoveryDesignatedBuyerId(game);
    return designated.isNotEmpty && playerId == designated;
  }
  // F15: when no GP is affluent, logic-phase minor auto-bids (`world_market_phase`
  // / `computeLockRecoveryMinorAutoBids`) fund liquidity-food purchases. GP buyers
  // would spend scarce treasury on grain instead of accumulating seller credits.
  return false;
}

/// Preferred liquidity buyers when no GP is affluent (6-GP observer order).
/// gp1/gp2 exit EXPAND earlier on seed 42 than gp3–gp6; keeping buys on these
/// factions prevents stuck EXPAND sellers from spending their own treasury.
const List<String> kLockRecoveryPreferredBuyerIds = ['gp1', 'gp2'];

/// Buyer when no GP meets [treasuryAffluenceThreshold]: rotate among
/// [kLockRecoveryPreferredBuyerIds] present in the game, else the two
/// richest-by-treasury GPs.
String lockRecoveryFallbackBuyerId(Game game) {
  final gpIds = _sortedGreatPowerIds(game);
  if (gpIds.isEmpty) return '';
  final preferred = <String>[
    for (final id in kLockRecoveryPreferredBuyerIds)
      if (gpIds.contains(id)) id,
  ];
  final buyerPool = preferred.length >= 2
      ? preferred
      : _twoRichestGreatPowerIdsByTreasury(game);
  if (buyerPool.isEmpty) return '';
  if (buyerPool.length == 1) return buyerPool.first;
  final turn = game.worldState.turnState.turnNumber;
  return buyerPool[turn % buyerPool.length];
}

List<String> _twoRichestGreatPowerIdsByTreasury(Game game) {
  final gpIds = _sortedGreatPowerIds(game);
  if (gpIds.isEmpty) return const [];
  final ranked = [...gpIds]
    ..sort((a, b) {
      final tA = _treasuryForPlayer(game, a);
      final tB = _treasuryForPlayer(game, b);
      if (tA != tB) return tB.compareTo(tA);
      return a.compareTo(b);
    });
  return ranked.take(2).toList();
}

/// One GP per turn acts as the market buyer for the lock-recovery food
/// commodity so other GPs' urgent offers can clear. Refs #2924 F11.
///
/// Rotates only among GPs at or above [treasuryAffluenceThreshold] so a
/// broke designated buyer does not waste the single `bidTypeCap` slot on
/// grain bids its treasury cannot fund while other GPs' urgent offers
/// starve (seed-42 gp4/gp6 `totalDealsAsSeller == 0` diagnostic). When no
/// GP meets the affluence band, [isLockRecoveryLiquidityBuyer] admits every
/// GP whose per-turn bid budget can fund at least one liquidity-food unit
/// (F15) instead of using this rotation.
///
/// Returns the empty string when no Great Power is broke — every GP is
/// already at or above the regiment threshold and the F1–F5 / F10 paths
/// handle the steady state without a synthetic grain bid. Refs #2924 F12.
String lockRecoveryDesignatedBuyerId(Game game) {
  if (!_anyBrokeGreatPower(game)) return '';
  final gpIds = _sortedGreatPowerIds(game);
  if (gpIds.isEmpty) return '';
  final threshold = treasuryAffluenceThreshold();
  final affluent = <String>[
    for (final id in gpIds)
      if (_treasuryForPlayer(game, id) >= threshold &&
          !_isBelowQuotaZeroNwLockRecoverySeller(game: game, playerId: id))
        id,
  ];
  if (affluent.isEmpty) return '';
  final turn = game.worldState.turnState.turnNumber;
  return affluent[turn % affluent.length];
}

/// Designated buyer bids [commodityId] and does not offer it this turn.
///
/// Bid quantity is the smaller of the F11 stockpile-target ceiling and
/// `max(0, treasuryBudgetForBids / pricePerUnit)` so the buyer never commits
/// more treasury than it currently holds (Refs #2924 F12 — treasury-capped)
/// **and** never overcommits against pending costs or carry-forward bid
/// notional already accounted for in [treasuryBudgetForBids] (Refs #3122).
void _applyLockRecoveryLiquidityBid({
  required String playerId,
  required Game game,
  required Map<CommodityId, int> need,
  required Map<CommodityId, int> available,
  required Map<CommodityId, int> carryForwardBids,
  required int treasuryBudgetForBids,
  required int treasuryForecast,
  required bool addSyntheticBid,
}) {
  final commodityId = _lockRecoveryLiquidityCommodity(game.worldMarketState);
  available.remove(commodityId);
  if (!addSyntheticBid) return;
  final pricePerUnit = game.worldMarketState.prices[commodityId] ?? 0;
  if (pricePerUnit <= 0) return;
  final budget =
      treasuryBudgetForBids < 0 ? 0 : treasuryBudgetForBids;
  final affordableQty = budget ~/ pricePerUnit;
  // Refs #2924 F14: lock-recovery liquidity bids use the full per-turn
  // treasury budget (after pending costs and carry-forward notional), not
  // the F10 stockpile-target ceiling of 8 units. On seed 42 the designated
  // buyer's treasury is far below the affluent band; capping at 8 kept per-
  // deal seller credits too small to approach the regiment threshold.
  final liquidityQty = affordableQty;
  if (liquidityQty <= 0) return;
  final existing = need[commodityId] ?? 0;
  if (liquidityQty > existing) {
    need[commodityId] = liquidityQty;
  }
}
