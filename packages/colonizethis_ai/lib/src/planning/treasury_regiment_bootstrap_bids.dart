import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'cast_iron_labour_gate.dart'
    show
        isCastIronLabourPeasantRecruitFabricMarketPathActive,
        isDomesticFabricProductionLabourInfeasible;
import 'planning_imports.dart';
import 'treasury_regiment_bootstrap.dart';

/// Lock-recovery seller regiment rebuild bid orchestration (Refs #4104 Slice B).

/// Parameter bag for [applyLockRecoverySellerRegimentRebuildBids] (Refs #3997).
final class LockRecoverySellerRegimentRebuildBidsInput {
  const LockRecoverySellerRegimentRebuildBidsInput({
    required this.isLockRecoverySeller,
    required this.rawTreasury,
    required this.threshold,
    required this.game,
    required this.playerId,
    required this.projected,
    required this.carryForwardBids,
    required this.need,
    required this.available,
  });

  final bool isLockRecoverySeller;
  final int rawTreasury;
  final int threshold;
  final Game game;
  final String playerId;
  final Stockpile projected;
  final Map<CommodityId, int> carryForwardBids;
  final Map<CommodityId, int> need;
  final Map<CommodityId, int> available;
}

void applyLockRecoverySellerRegimentRebuildBids(
  LockRecoverySellerRegimentRebuildBidsInput input,
) {
  if (!input.isLockRecoverySeller) {
    return;
  }
  final zeroRegimentRebuildPath =
      regimentCountForPlayer(input.game, input.playerId) == 0;
  // Refs #2847 § castIron-labour peasant-recruit fabric staging: the recruit
  // row costs 2 `fabric` while the regiment build input needs only 1, so a
  // seller holding one unit clears the regiment missing-input check yet still
  // cannot pay the recruit — wool / cotton feedstock must stay reserved until
  // `fabric >= 2` when the population-bound castIron labour path is active.
  final peasantRecruitFabricStaging =
      isCastIronLabourPeasantRecruitFabricMarketPathActive(
        game: input.game,
        playerId: input.playerId,
        projected: input.projected,
      );
  final castIronLabourPeasantRecruitMarketPath = peasantRecruitFabricStaging;
  if (!zeroRegimentRebuildPath && !castIronLabourPeasantRecruitMarketPath) {
    return;
  }
  // Refs #2847 § H8 production allocation: offer-side input staging is
  // **treasury-independent**. The economy planner now produces the cheapest
  // regiment's build input (`fabric`) and its recipe feedstock ahead of
  // treasury recovery (economy-planner.md § Regiment build-input production
  // priority), so the offer side must retain that staged input even while the
  // seller is still broke — otherwise the strong-cargo Path-F seller sells the
  // freshly produced `fabric` (and its `wool` / `cotton` feedstock) back into
  // the world market every turn and it never accumulates to the
  // `peasant_levies` build cost, leaving the seller trapped at zero regiments.
  // Both reservations only suppress surplus offers (no order is added, no
  // treasury is spent), are scoped to the below-quota zero-NW zero-regiment
  // band, and self-clear the turn a regiment lands (enclosing guard) or the
  // build input is on hand (feedstock self-clear), so the +6 OW baseline GPs
  // (gp1 / gp2) are never affected. SPEC/ai/treasury-planner.md
  // § Produced build-input retention + § Build-input feedstock reservation.
  if (zeroRegimentRebuildPath || castIronLabourPeasantRecruitMarketPath) {
    for (final buildInputId
        in RegimentEconomyCatalog.peasantLevies.buildInputs.keys) {
      input.available.remove(buildInputId);
    }
    for (final feedstockId in regimentBuildInputFeedstockIds(
      input.projected,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    )) {
      input.available.remove(feedstockId);
    }
  }
  // Refs #2847 § H8 bootstrap bids: market bids spend treasury (the buyer's
  // notional is debited on a match), so the build-input / feedstock / direct
  // bid arms below require a **recovered** treasury. A still-broke seller stays
  // offers-only (minus the staged input reservations above) until it crosses
  // the regiment cost. SPEC/ai/treasury-planner.md § Lock-recovery seller
  // regiment build-input bootstrap.
  if (input.rawTreasury < input.threshold) {
    return;
  }
  if (castIronLabourPeasantRecruitMarketPath &&
      isDomesticFabricProductionLabourInfeasible(
        game: input.game,
        playerId: input.playerId,
      )) {
    // Domestic `fabric_from_*` is material-feasible yet labour-walled
    // (`labourPerOutput == 2` > effective labour). Feedstock bids cannot unblock
    // the peasant recruit — buy finished `fabric` from affluent suppliers instead
    // (Refs #2847 § labour-infeasible fabric market path).
    addRegimentBuildInputDirectNeed(
      projected: input.projected,
      carryForwardBids: input.carryForwardBids,
      need: input.need,
      peasantRecruitFabricStaging: true,
    );
    return;
  }
  if (!zeroRegimentRebuildPath) {
    // Peasant-recruit fabric path with labour-feasible domestic conversion:
    // feedstock / direct bids only (no zero-regiment improvement-input chain).
    final feedstockStillMissing = addRegimentBuildInputFeedstockBootstrapNeed(
      feedstockCandidates: sortedRegimentBuildInputFeedstockIds(
        input.projected,
        peasantRecruitFabricStaging: peasantRecruitFabricStaging,
      ),
      projected: input.projected,
      carryForwardBids: input.carryForwardBids,
      need: input.need,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    );
    if (!feedstockStillMissing) {
      addRegimentBuildInputDirectNeed(
        projected: input.projected,
        carryForwardBids: input.carryForwardBids,
        need: input.need,
        peasantRecruitFabricStaging: peasantRecruitFabricStaging,
      );
    }
    return;
  }
  // Refs #2847 H8-extraction: improvement-input prerequisite. The seller's
  // routed Builder cannot extract its owned feedstock tile until it holds the
  // level-0 `build_improvement` material (lumber + cast iron) it has zero of —
  // a lumber / cast-iron deadlock with no domestic escape. Bid for those
  // improvement inputs first and suppress the downstream feedstock / fabric
  // bootstrap bids while any improvement-input deficit remains, so the single
  // bid slot targets the prerequisite supply. Self-clears once the inputs land
  // (or the tile is improved / a regiment is owned).
  if (addRegimentFeedstockImprovementInputNeed(
    game: input.game,
    playerId: input.playerId,
    projected: input.projected,
    carryForwardBids: input.carryForwardBids,
    need: input.need,
  )) {
    return;
  }
  final feedstockStillMissing = addRegimentBuildInputFeedstockBootstrapNeed(
    feedstockCandidates: sortedRegimentBuildInputFeedstockIds(
      input.projected,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    ),
    projected: input.projected,
    carryForwardBids: input.carryForwardBids,
    need: input.need,
    peasantRecruitFabricStaging: peasantRecruitFabricStaging,
  );
  if (!feedstockStillMissing) {
    addRegimentBuildInputDirectNeed(
      projected: input.projected,
      carryForwardBids: input.carryForwardBids,
      need: input.need,
      peasantRecruitFabricStaging: peasantRecruitFabricStaging,
    );
  }
}
