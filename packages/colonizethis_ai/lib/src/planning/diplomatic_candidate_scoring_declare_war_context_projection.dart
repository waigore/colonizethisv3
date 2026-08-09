import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'diplomatic_candidate_scoring_shared.dart';
import 'planning_imports.dart';

extension DeclareWarTargetContextProjection on DeclareWarTargetContext {
    bool get targetIsGreatPower => game.playerById(order.targetFactionId) != null;
  
    /// Whether the active player is *not* already at war with the declare-war
    /// target.
    ///
    /// Single source of truth for the
    /// `!snapshot.threats.atWarWith.contains(order.targetFactionId)` guard
    /// repeated across the adjacent-GP and war-concentration suppression
    /// branches (Refs #3717 diplomatic-scoring dedup). Pure projection over
    /// [snapshot] / [order]; byte-identical to the inline checks it replaces
    /// (Refs #2509 Must-have #7).
    bool get targetNotAlreadyAtWar =>
        !snapshot.threats.atWarWith.contains(order.targetFactionId);
  
    /// Whether the target is an adjacent, invadable Old-World minor nation: a
    /// non-tribe minor the active player borders and can currently invade.
    ///
    /// Single source of truth for the
    /// `isMinorTarget && !isTribeTarget && isAdjacentOwner &&
    /// invadableOwners.contains(order.targetFactionId)` projection repeated
    /// across the declare-war OW-conquest bonus branches (Refs #3717
    /// diplomatic-scoring dedup). Equivalent to
    /// `isAdjacentOwner && ownsInvadableOwMinor` — [ownsInvadableOwMinor]
    /// already folds the minor / non-tribe / invadable trio — so this getter is
    /// a pure projection over precomputed fields and is byte-identical to the
    /// inline checks it replaces (Refs #2509 Must-have #7).
    bool get isAdjacentInvadableOwMinor =>
        isAdjacentOwner && ownsInvadableOwMinor;
  
    /// Whether the declare-war target faction currently owns at least one of the
    /// active player's invadable Old-World provinces.
    ///
    /// Single source of truth for the
    /// `invadableOwners.contains(order.targetFactionId)` projection repeated
    /// across the declare-war suppression and bonus scoring branches (Refs #3717
    /// diplomatic-scoring dedup). Pure projection over [invadableOwners] /
    /// [order]; byte-identical to the inline checks it replaces (Refs #2509
    /// Must-have #7).
    bool get targetIsInvadableOwner =>
        invadableOwners.contains(order.targetFactionId);
  
    /// Number of provinces the declare-war target faction currently owns.
    ///
    /// Single source of truth for the
    /// `provinceCountOwnedBy(game, order.targetFactionId)` projection repeated
    /// across the declare-war suppression and bonus scoring branches (Refs #3717
    /// declare-war OW-conquest scoring-skeleton dedup). Backed by the O(1)
    /// memoised [ProvinceOwnerCache.countOwnedBy] lookup, so reading it is a pure
    /// projection over [game] / [order]; byte-identical to the inline calls it
    /// replaces (Refs #2509 Must-have #7).
    int get targetProvinceCount =>
        provinceCountOwnedBy(game, order.targetFactionId);
  
    /// Whether the active player's war-likelihood personality threshold is at or
    /// below the declare-war low-war-likelihood band
    /// (`thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold`).
    ///
    /// Single source of truth for the low-war-likelihood predicate repeated
    /// across the declare-war suppression and bonus scoring branches (Refs #3717
    /// diplomatic-scoring dedup). Pure projection over [thresholds];
    /// byte-identical to the inline comparisons it replaces (Refs #2509
    /// Must-have #7).
    bool get lowWarLikelihood =>
        thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold;
}
