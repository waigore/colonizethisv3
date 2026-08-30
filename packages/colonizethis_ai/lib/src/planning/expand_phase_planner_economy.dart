import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart' show regimentCountForPlayer;
import 'cast_iron_labour_gate.dart'
    show isCastIronLabourPopulationBoundForLockRecoverySeller;
import 'expand_peace_frontier_helpers.dart';
import 'planning_helpers.dart';
import 'planning_imports.dart';

export 'expand_phase_planner_economy_peace_rebuild.dart';

/// EXPAND-phase economy directive from [planExpandEconomy] (Refs #2509 S5).
///
/// Flags compose. Contract: `SPEC/ai/economy-planner.md` and
/// `SPEC/ai/phase-planner-architecture.md`.
class ExpandEconomyPlan {
  const ExpandEconomyPlan({
    required this.forceCheapestRegimentBuild,
    required this.boostTreasuryRecoveryCargo,
    this.boostCastIronLabourPeasantRecruitment = false,
  });

  /// Shared "no override" plan for non-EXPAND callers and quota GPs.
  static const ExpandEconomyPlan defaultPlan = ExpandEconomyPlan(
    forceCheapestRegimentBuild: false,
    boostTreasuryRecoveryCargo: false,
    boostCastIronLabourPeasantRecruitment: false,
  );

  /// Drop the build-pass threshold and pick the cheapest regiment.
  final bool forceCheapestRegimentBuild;

  /// Raise overseas cargo preference (treasury below cheapest regiment).
  final bool boostTreasuryRecoveryCargo;

  /// Emit a peasant recruit before the build pass (castIron labour gate).
  final bool boostCastIronLabourPeasantRecruitment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpandEconomyPlan &&
          other.forceCheapestRegimentBuild == forceCheapestRegimentBuild &&
          other.boostTreasuryRecoveryCargo == boostTreasuryRecoveryCargo &&
          other.boostCastIronLabourPeasantRecruitment ==
              boostCastIronLabourPeasantRecruitment;

  @override
  int get hashCode => Object.hash(
    forceCheapestRegimentBuild,
    boostTreasuryRecoveryCargo,
    boostCastIronLabourPeasantRecruitment,
  );

  @override
  String toString() =>
      'ExpandEconomyPlan('
      'forceCheapestRegimentBuild: $forceCheapestRegimentBuild, '
      'boostTreasuryRecoveryCargo: $boostTreasuryRecoveryCargo, '
      'boostCastIronLabourPeasantRecruitment: '
      '$boostCastIronLabourPeasantRecruitment)';
}

/// EXPAND-phase economy directive (issue #2509 § planExpandEconomy).
///
/// Effective treasury includes [pendingRichesTreasuryDelta]. Arm C cargo
/// boost still fires under the geographic peer-war lock so the resource-need
/// NW floor in `phase_priority_weights.dart` stays coupled (Refs #2847).
ExpandEconomyPlan planExpandEconomy({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOwnOldWorldBelowConquestQuota(snapshot)) {
    return ExpandEconomyPlan.defaultPlan;
  }
  final player = game.playerById(snapshot.playerId);
  if (player == null) {
    return ExpandEconomyPlan.defaultPlan;
  }

  final hasInvadable = snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  final effectiveTreasury =
      player.treasury + pendingRichesTreasuryDelta(stockpile: player.stockpile);
  final cheapest = cheapestRegimentBuildTreasuryCost();

  // Arm A: regimentCount == 0 AND hasInvadable -> force rebuild
  // (no treasury gate per spec; the build pipeline still applies its
  // own affordability check, but the directive remains so the phase
  // planner cannot be silently overridden by a treasury hiccup).
  final armA = regimentCount == 0 && hasInvadable;

  // Arm B: 0 < regimentCount < min AND hasInvadable AND effective
  // treasury affords the cheapest regiment.
  final armB =
      regimentCount > 0 &&
      regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar &&
      hasInvadable &&
      effectiveTreasury >= cheapest;

  final futilityLock = expandIsGeographicPeerWarLockNoNwTreasuryRecovery(
    game: game,
    snapshot: snapshot,
  );

  // Arm D (Refs #2847 § H3): trap-band force rebuild without treasury
  // gate when overseas cargo recovery is futile.
  final armD =
      futilityLock &&
      regimentCount > 0 &&
      regimentCount < kBelowQuotaPeaceMinRegimentsBeforeDeclareWar &&
      hasInvadable;

  // Arm C: effective treasury below cheapest regiment cost (independent
  // of regimentCount per the spec literal wording — boosts cargo so a
  // GP in EXPAND with low cash always benefits from delivering riches,
  // matching the SPEC/ai/ai-architecture.md "Treasury recovery cargo"
  // intent). Fires under the geographic peer-war lock too: the cargo
  // signal is what the resource-need NW=0.60 weight floor consumes in
  // `phase_priority_weights.dart`, so suppressing the boost under the
  // lock also disables the override the issue's soft-phase design
  // depends on (Refs #2847 § Resource-need overrides). Cargo delivery
  // may be futile until the GP acquires its first NW colony, but the
  // signal correctly marks the GP as needing overseas income so
  // downstream NW scoring biases activate.
  final armC = effectiveTreasury < cheapest;

  final forceRebuild = armA || armB || armD;
  // Treasury-independent like the economy-planner fabric staging path: the
  // recruit must be eligible on population-bound gate turns even when the
  // EXPAND rebuild directive is inactive (no invadable frontier that turn).
  final boostCastIronLabourPeasantRecruitment =
      isCastIronLabourPopulationBoundForLockRecoverySeller(
        game: game,
        playerId: snapshot.playerId,
      );

  return ExpandEconomyPlan(
    forceCheapestRegimentBuild: forceRebuild,
    boostTreasuryRecoveryCargo: armC,
    boostCastIronLabourPeasantRecruitment:
        boostCastIronLabourPeasantRecruitment,
  );
}
