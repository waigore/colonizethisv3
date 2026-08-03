import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'cast_iron_labour_gate.dart'
    show isCastIronLabourPeasantRecruitFabricMarketPathActive;
import 'ai_commodity_ids.dart';
import 'planning_imports.dart';
import 'treasury_regiment_bootstrap.dart' show kDomesticProductionImprovementInputIds;
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
/// **offerable** to the world market this turn.
int otherGreatPowerOfferableFabricHeld(Game game, String playerId) {
  var total = 0;
  for (final player in game.players) {
    if (player.id == playerId) continue;
    if (isFabricOfferRetainingLockRecoverySeller(game, player.id)) continue;
    total += player.stockpile.quantityOf(kAiCommodityIds.fabric);
  }
  return total;
}
