part of 'expand_phase_planner.dart';

/// The single deterministic **primary** Old World feedstock-tile acquisition
/// target province id the flagged below-quota zero-NW lock-recovery seller
/// [AIWorldSnapshot.playerId] should pursue **by conquest** this EXPAND turn,
/// or `null` when none applies (Refs #2847 § H8-extraction seller
/// feedstock-tile acquisition target wiring; `SPEC/ai/economy-planner.md`
/// § EXPAND feedstock-tile acquisition target wiring).
///
/// AI-side wiring for the topology-free logic pick contract
/// `sellerFeedstockTileAcquisitionTarget` exposed via the logic `ai_api`
/// contract entrypoint.
/// The logic contract intersects the seller's feedstock candidate list with a
/// caller-supplied `acquirableProvinceIds` set and picks the lowest acquirable
/// province id, but it cannot know which Old World provinces the EXPAND planner
/// can actually reach by conquest this turn. This function supplies that
/// topology-derived acquirable set: it treats the EXPAND conquest frontier —
/// [ConquestSummary.invadableProvinceIdsSorted], the topology-derived
/// ascending-sorted Old World provinces the active player can invade this turn
/// — as the acquirable target set and returns the logic contract's primary
/// pick over it.
///
/// The conquest frontier is the EXPAND acquisition channel; purchasable-land
/// targets are a COLONIAL-phase concern and are not exposed in the EXPAND
/// [ConquestSummary], so this wiring stays scoped to conquest reach. No new
/// topology scan is performed — the already-computed
/// [ConquestSummary.invadableProvinceIdsSorted] is reused — and no adjacency is
/// derived here.
///
/// Returns `null` for every player whose acquisition residual is inactive (so
/// the +6 Old World conquest baseline GPs gp1/gp2 are never targeted), when the
/// conquest frontier is empty, or when no feedstock candidate is invadable this
/// turn. Changes no emitted order on its own — the order-emission wiring is a
/// later slice that consumes this target. Pure and deterministic over
/// `(game, snapshot)` and the static `ProductionRecipesCatalog`; performs no
/// I/O and no logging, and adds no `ai_victory_config.dart` constant.
String? expandSellerFeedstockTileAcquisitionTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final acquirable = snapshot.conquest.invadableProvinceIdsSorted.toSet();
  if (acquirable.isEmpty) return null;
  return sellerFeedstockTileAcquisitionTarget(
    game,
    snapshot.playerId,
    acquirable,
  );
}
