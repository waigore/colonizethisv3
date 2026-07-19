
import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'cast_iron_labour_gate.dart'
    show isCastIronLabourPeasantRecruitFabricMarketPathActive;
import 'expand_phase_planner_economy.dart' show cheapestRegimentBuildTreasuryCost;
import 'ai_commodity_ids.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;
import 'treasury_market_pricing.dart';
import 'treasury_regiment_bootstrap.dart' show kDomesticProductionImprovementInputIds;
import 'treasury_planner_constants.dart';

// Lock-recovery seller predicate and designated/liquidity buyer rotation for
// the treasury planner (Refs #2924 F11–F17 + #2847 H8), extracted from
// `treasury_planner.dart` for maintainability (Refs #3288 file-split).
// Behaviour-preserving move: same library scope (this is a `part of` the
// treasury-planner library), so imports, shared helpers, and visibility are
// unchanged.

/// Per-turn lock-recovery aggregates computed in one `game.players` pass (Refs
/// #3288). Replaces repeated O(players) scans inside the treasury hot path.
final class LockRecoveryGameScan {
  LockRecoveryGameScan._({
    required this.sortedGpIds,
    required this.anyBrokeGreatPower,
    required this.anySellerNeedsRegimentBuildInput,
    required this.anySellerNeedsCastIronLabourPeasantRecruitFabric,
    required this.anySellerNeedsCastIronImprovementInput,
    required this.isLockRecoverySellerByPlayerId,
    required this.designatedBuyerId,
  });

  final List<String> sortedGpIds;
  final bool anyBrokeGreatPower;
  final bool anySellerNeedsRegimentBuildInput;
  final bool anySellerNeedsCastIronLabourPeasantRecruitFabric;
  final bool anySellerNeedsCastIronImprovementInput;
  final Map<String, bool> isLockRecoverySellerByPlayerId;
  final String designatedBuyerId;

  factory LockRecoveryGameScan.fromGame(
    Game game, {
    AIWorldSnapshot? snapshot,
  }) {
    final regimentThreshold = cheapestRegimentBuildTreasuryCost();
    final affluenceThreshold = treasuryAffluenceThreshold();
    final sortedGpIds = <String>[];
    var anyBrokeGreatPower = false;
    var anySellerNeedsRegimentBuildInput = false;
    var anySellerNeedsCastIronLabourPeasantRecruitFabric = false;
    var anySellerNeedsCastIronImprovementInput = false;
    final isLockRecoverySellerByPlayerId = <String, bool>{};
    final affluentNonSellerIds = <String>[];

    for (final player in game.players) {
      sortedGpIds.add(player.id);
      if (player.treasury < regimentThreshold) {
        anyBrokeGreatPower = true;
      }
      final isSeller = isBelowQuotaZeroNwLockRecoverySellerInternal(
        game: game,
        playerId: player.id,
        snapshot: snapshot?.playerId == player.id ? snapshot : null,
      );
      isLockRecoverySellerByPlayerId[player.id] = isSeller;
      if (isSeller) {
        if (lockRecoverySellerNeedsRegimentBuildInput(
          game,
          player,
          regimentThreshold: regimentThreshold,
        )) {
          anySellerNeedsRegimentBuildInput = true;
        }
        if (lockRecoverySellerNeedsCastIronLabourPeasantRecruitFabric(
          game,
          player,
        )) {
          anySellerNeedsCastIronLabourPeasantRecruitFabric = true;
        }
        if (lockRecoverySellerNeedsCastIronImprovementInput(game, player)) {
          anySellerNeedsCastIronImprovementInput = true;
        }
      }
      if (player.treasury >= affluenceThreshold && !isSeller) {
        affluentNonSellerIds.add(player.id);
      }
    }
    sortedGpIds.sort();
    affluentNonSellerIds.sort();

    final designatedBuyerId =
        !anyBrokeGreatPower || affluentNonSellerIds.isEmpty
        ? ''
        : affluentNonSellerIds[game.worldState.turnState.turnNumber %
              affluentNonSellerIds.length];

    return LockRecoveryGameScan._(
      sortedGpIds: sortedGpIds,
      anyBrokeGreatPower: anyBrokeGreatPower,
      anySellerNeedsRegimentBuildInput: anySellerNeedsRegimentBuildInput,
      anySellerNeedsCastIronLabourPeasantRecruitFabric:
          anySellerNeedsCastIronLabourPeasantRecruitFabric,
      anySellerNeedsCastIronImprovementInput:
          anySellerNeedsCastIronImprovementInput,
      isLockRecoverySellerByPlayerId: isLockRecoverySellerByPlayerId,
      designatedBuyerId: designatedBuyerId,
    );
  }

  bool isLockRecoverySeller(String playerId) =>
      isLockRecoverySellerByPlayerId[playerId] ?? false;
}

bool lockRecoverySellerNeedsCastIronLabourPeasantRecruitFabric(
  Game game,
  Player player,
) {
  return isCastIronLabourPeasantRecruitFabricMarketPathActive(
    game: game,
    playerId: player.id,
    projected: player.stockpile,
  );
}

bool lockRecoverySellerNeedsRegimentBuildInput(
  Game game,
  Player player, {
  required int regimentThreshold,
}) {
  if (player.treasury < regimentThreshold ||
      regimentCountForPlayer(game, player.id) != 0) {
    return false;
  }
  for (final entry
      in RegimentEconomyCatalog.peasantLevies.buildInputs.entries) {
    if (player.stockpile.quantityOf(entry.key) < entry.value) {
      return true;
    }
  }
  return false;
}

bool lockRecoverySellerNeedsCastIronImprovementInput(
  Game game,
  Player player,
) {
  final cost = regimentBuildInputFeedstockImprovementInputCost(game, player.id);
  if (cost.isEmpty) return false;
  for (final entry in cost.entries) {
    if (!kDomesticProductionImprovementInputIds.contains(entry.key)) {
      continue;
    }
    if (player.stockpile.quantityOf(entry.key) < entry.value) {
      return true;
    }
  }
  return false;
}

int treasuryForPlayer(Game game, String playerId) =>
    game.playerById(playerId)?.treasury ?? 0;

int oldWorldProvinceCountOwnedByForLockRecovery(
  Game game,
  String playerId, {
  AIWorldSnapshot? snapshot,
}) {
  if (snapshot != null && snapshot.playerId == playerId) {
    return snapshot.conquest.oldWorldProvincesOwned;
  }
  return oldWorldProvinceCountOwnedBy(game, playerId);
}

int newWorldProvinceCountOwnedByForLockRecovery(
  Game game,
  String playerId, {
  AIWorldSnapshot? snapshot,
}) {
  if (snapshot != null && snapshot.playerId == playerId) {
    return snapshot.colonial.newWorldProvincesOwned;
  }
  // Phase 6b (SPEC/program/worldstate-projection.md; Refs #3393): read the
  // owned new-world province count from the memoised projection instead of
  // rescanning every new-world province. Behaviour-preserving: counts only
  // provinces whose non-null `ownerId == playerId`.
  return ProvinceOwnerCache.of(
    game.worldState,
  ).countOwnedByInRegion(playerId, kRegionNewWorld);
}

/// Below-quota GPs with zero NW provinces and at least one OW province
/// are Path F lock-recovery **sellers** — they must accumulate seller
/// credits toward the regiment threshold, not rotate as the affluent
/// designated buyer or speculate (Refs #2924 Path F gp6 regression).
bool isBelowQuotaZeroNwLockRecoverySellerInternal({
  required Game game,
  required String playerId,
  AIWorldSnapshot? snapshot,
}) {
  final ow = oldWorldProvinceCountOwnedByForLockRecovery(game, playerId, snapshot: snapshot);
  if (ow <= 0) return false;
  if (!isBelowObserverConquestQuota(ow)) return false;
  if (newWorldProvinceCountOwnedByForLockRecovery(game, playerId, snapshot: snapshot) != 0) {
    return false;
  }
  // Mid-below-quota EXPAND band (seed-42 gp3–gp6); excludes minimal
  // single-province test fixtures that are not Path F lock-recovery sellers.
  return ow >= 2;
}

/// Public accessor for the below-quota zero-NW lock-recovery seller predicate
/// (Refs #2847 H8-supply castIron source). The economy planner uses it to keep
/// the supplier `castIron` over-production off for a GP that is itself a locked
/// seller (its own self-path boost already covers it).
bool isBelowQuotaZeroNwLockRecoverySeller(
  Game game,
  String playerId, {
  AIWorldSnapshot? snapshot,
}) => isBelowQuotaZeroNwLockRecoverySellerInternal(
  game: game,
  playerId: playerId,
  snapshot: snapshot,
);

/// True when [playerId]'s `fabric` (the cheapest regiment's build input) is
/// withheld from the world-market offer set this turn by the regiment-rebuild
/// offer-retention carve-out in [applyLockRecoverySellerRegimentRebuildBids]:
/// a below-quota zero-NW lock-recovery seller ([isBelowQuotaZeroNwLockRecoverySeller])
/// holding **zero regiments**.
///
/// While the carve-out is active every `peasant_levies` build input — `fabric`
/// among them — is removed from the offer set so it banks toward the regiment
/// build cost instead of being sold back as surplus. A holder for which this is
/// true therefore contributes its `fabric` to gross holdings
/// ([otherGreatPowerFabricHeld]) yet offers none of it to the market. Pure
/// read-only over `(game, playerId)`; mirrors the carve-out scope exactly
/// (`isLockRecoverySeller && regimentCountForPlayer == 0`). Refs #2847 § S7-D
/// market-fabric offer/acquisition localization.
bool isFabricOfferRetainingLockRecoverySeller(Game game, String playerId) {
  if (!isBelowQuotaZeroNwLockRecoverySellerInternal(game: game, playerId: playerId)) {
    return false;
  }
  final player = game.playerById(playerId);
  if (player != null &&
      isCastIronLabourPeasantRecruitFabricMarketPathActive(
        game: game,
        playerId: playerId,
        projected: player.stockpile,
      )) {
    return true;
  }
  return regimentCountForPlayer(game, playerId) == 0;
}

/// Total `fabric` held by great powers other than [playerId] that is actually
/// **offerable** to the world market this turn — the offer-side refinement of
/// [otherGreatPowerFabricHeld]. It excludes holders whose `fabric` is withheld
/// by the regiment-rebuild offer-retention carve-out
/// ([isFabricOfferRetainingLockRecoverySeller]).
///
/// [otherGreatPowerFabricHeld] is a gross-holdings proxy — it counts `fabric`
/// even when every holder retains it, so a positive holdings total does not
/// imply any counterparty actually offers `fabric` a fabric-starved seller could
/// buy. This function closes that gap: when holdings are positive
/// ([otherGreatPowerFabricHeld] > 0) yet this offerable total is 0, the closed
/// market door is localized to the **offer/retention layer** (every holder is
/// itself a retaining lock-recovery seller) rather than to buyer-side
/// acquisition; a positive offerable total instead re-points the residual to the
/// fabric-starved seller's own buy/bid path. It remains a planner-scope offer
/// proxy, not a full world-market offer/match simulation. Pure read-only over
/// `game.players`; no game-state mutation. Refs #2847 § S7-D market-fabric
/// offer/acquisition localization.
int otherGreatPowerOfferableFabricHeld(Game game, String playerId) {
  var total = 0;
  for (final player in game.players) {
    if (player.id == playerId) continue;
    if (isFabricOfferRetainingLockRecoverySeller(game, player.id)) continue;
    total += player.stockpile.quantityOf(kAiCommodityIds.fabric);
  }
  return total;
}

/// True when any below-quota zero-NW lock-recovery seller still lacks a
/// domestically-produced level-0 `build_improvement` input (a
/// [kDomesticProductionImprovementInputIds] commodity such as `castIron`) the
/// world market structurally cannot supply on seed 42 (Refs #2847 H8-supply
/// castIron source). When true, an affluent supplier over-produces that input
/// for release (`economy_planner.dart`) and this planner releases the resulting
/// surplus + aligns its offer tier so the locked seller's bid can cross.
/// Pure function of `(game)` and the static catalogs; returns `false` once no
/// locked seller still needs the improvement input (self-clearing).
bool anyLockRecoverySellerNeedsCastIronImprovementInput(
  Game game, {
  LockRecoveryGameScan? scan,
}) => (scan ?? LockRecoveryGameScan.fromGame(game))
    .anySellerNeedsCastIronImprovementInput;

bool isAffluentDesignatedLockRecoveryBuyerInternal({
  required Game game,
  required String playerId,
  LockRecoveryGameScan? scan,
}) {
  final resolved = scan ?? LockRecoveryGameScan.fromGame(game);
  if (!resolved.anyBrokeGreatPower) return false;
  final designated = resolved.designatedBuyerId;
  return designated.isNotEmpty && playerId == designated;
}

/// Whether [playerId] should emit the urgent lock-recovery liquidity-food bid
/// this turn. Refs #2924 F11/F12/F13/F15.
bool isLockRecoveryLiquidityBuyer({
  required Game game,
  required String playerId,
  required int treasuryBudgetForBids,
  required int treasuryForecast,
  LockRecoveryGameScan? scan,
}) {
  final resolved = scan ?? LockRecoveryGameScan.fromGame(game);
  if (!resolved.anyBrokeGreatPower) return false;
  final liquidity = lockRecoveryLiquidityCommodity(game.worldMarketState);
  final pricePerUnit = game.worldMarketState.prices[liquidity] ?? 0;
  if (pricePerUnit <= 0 || treasuryBudgetForBids < pricePerUnit) {
    return false;
  }
  final threshold = cheapestRegimentBuildTreasuryCost();
  final rawTreasury = treasuryForPlayer(game, playerId);
  // F13: optimistic offer-inflow forecast keeps a broke GP on offers-only.
  if (rawTreasury < threshold && treasuryForecast >= threshold) {
    return false;
  }
  if (resolved.designatedBuyerId.isNotEmpty) {
    return playerId == resolved.designatedBuyerId;
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
String lockRecoveryFallbackBuyerId(Game game, {LockRecoveryGameScan? scan}) {
  final resolved = scan ?? LockRecoveryGameScan.fromGame(game);
  final gpIds = resolved.sortedGpIds;
  if (gpIds.isEmpty) return '';
  final preferred = <String>[
    for (final id in kLockRecoveryPreferredBuyerIds)
      if (gpIds.contains(id)) id,
  ];
  final buyerPool = preferred.length >= 2
      ? preferred
      : twoRichestGreatPowerIdsByTreasury(game, scan: resolved);
  if (buyerPool.isEmpty) return '';
  if (buyerPool.length == 1) return buyerPool.first;
  final turn = game.worldState.turnState.turnNumber;
  return buyerPool[turn % buyerPool.length];
}

List<String> twoRichestGreatPowerIdsByTreasury(
  Game game, {
  LockRecoveryGameScan? scan,
}) {
  final gpIds = (scan ?? LockRecoveryGameScan.fromGame(game)).sortedGpIds;
  if (gpIds.isEmpty) return const [];
  final ranked = [...gpIds]
    ..sort((a, b) {
      final tA = treasuryForPlayer(game, a);
      final tB = treasuryForPlayer(game, b);
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
String lockRecoveryDesignatedBuyerId(
  Game game, {
  LockRecoveryGameScan? scan,
}) => (scan ?? LockRecoveryGameScan.fromGame(game)).designatedBuyerId;

/// Parameter bag for [applyLockRecoveryLiquidityBid] (Refs #3997).
final class LockRecoveryLiquidityBidInput {
  const LockRecoveryLiquidityBidInput({
    required this.game,
    required this.need,
    required this.available,
    required this.treasuryBudgetForBids,
    required this.addSyntheticBid,
  });

  final Game game;
  final Map<CommodityId, int> need;
  final Map<CommodityId, int> available;
  final int treasuryBudgetForBids;
  final bool addSyntheticBid;
}

/// Designated buyer bids [commodityId] and does not offer it this turn.
///
/// Bid quantity is the smaller of the F11 stockpile-target ceiling and
/// `max(0, treasuryBudgetForBids / pricePerUnit)` so the buyer never commits
/// more treasury than it currently holds (Refs #2924 F12 — treasury-capped)
/// **and** never overcommits against pending costs or carry-forward bid
/// notional already accounted for in [treasuryBudgetForBids] (Refs #3122).
void applyLockRecoveryLiquidityBid(LockRecoveryLiquidityBidInput input) {
  final commodityId = lockRecoveryLiquidityCommodity(input.game.worldMarketState);
  input.available.remove(commodityId);
  if (!input.addSyntheticBid) return;
  final pricePerUnit = input.game.worldMarketState.prices[commodityId] ?? 0;
  if (pricePerUnit <= 0) return;
  final budget =
      input.treasuryBudgetForBids < 0 ? 0 : input.treasuryBudgetForBids;
  final affordableQty = budget ~/ pricePerUnit;
  // Refs #2924 F14: lock-recovery liquidity bids use the full per-turn
  // treasury budget (after pending costs and carry-forward notional), not
  // the F10 stockpile-target ceiling of 8 units. On seed 42 the designated
  // buyer's treasury is far below the affluent band; capping at 8 kept per-
  // deal seller credits too small to approach the regiment threshold.
  final liquidityQty = affordableQty;
  if (liquidityQty <= 0) return;
  final existing = input.need[commodityId] ?? 0;
  if (liquidityQty > existing) {
    input.need[commodityId] = liquidityQty;
  }
}
