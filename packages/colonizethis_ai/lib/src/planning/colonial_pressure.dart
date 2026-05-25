import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart' as expand_phase_planner;

/// Invadable Old World frontier held only by Great Powers (no minor on border).
///
/// Delegates to [expand_phase_planner.isOldWorldGpOnlyInvadableFrontier]
/// (Refs #2509 S1).
bool isOldWorldGpOnlyInvadableFrontier({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.isOldWorldGpOnlyInvadableFrontier(
  game: game,
  snapshot: snapshot,
);

/// Any OW minor not yet at war that still holds provinces (EXPAND minor-first).
///
/// Delegates to [expand_phase_planner.hasUninvadedOldWorldMinor] (Refs #2509 S1).
bool hasUninvadedOldWorldMinor({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.hasUninvadedOldWorldMinor(
  game: game,
  snapshot: snapshot,
);

/// Below-quota OW expansion with a GP-only invadable frontier (seed-42 gp5/gp6).
///
/// Delegates to [expand_phase_planner.isStalledOldWorldGpBlockerFocus]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// EXPAND OW frontier helpers it composes (`isBelowObserverConquestQuota`
/// from `colonizethis_data` and `isOldWorldGpOnlyInvadableFrontier` from
/// `expand_phase_planner.dart`).
bool isStalledOldWorldGpBlockerFocus({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.isStalledOldWorldGpBlockerFocus(
  game: game,
  snapshot: snapshot,
);

/// Below-quota EXPAND GP at peace with all other Great Powers, with an invadable
/// Old World frontier and a positive but small standing regiment count.
///
/// Delegates to [expand_phase_planner.isBelowQuotaPeaceInsufficientRegiments]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// EXPAND-trap callers that share the insufficient-regiments / invadable-frontier
/// gate (Arm B of the legacy below-quota treasury-recovery composite).
bool isBelowQuotaPeaceInsufficientRegiments({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
}) => expand_phase_planner.isBelowQuotaPeaceInsufficientRegiments(
  oldWorldProvincesOwned: oldWorldProvincesOwned,
  regimentCount: regimentCount,
  atWarWithAnyGreatPower: atWarWithAnyGreatPower,
  hasInvadableProvinces: hasInvadableProvinces,
);

/// Minimum [RegimentEconomyCatalog] build treasury cost (deterministic catalog scan).
///
/// Delegates to [expand_phase_planner.cheapestRegimentBuildTreasuryCost]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// EXPAND-trap callers that govern the treasury affordability gate.
int cheapestRegimentBuildTreasuryCost() =>
    expand_phase_planner.cheapestRegimentBuildTreasuryCost();

/// Below-quota EXPAND GP at peace with insufficient regiments and effective
/// treasury (cash plus same-turn pending riches) below cheapest regiment build.
///
/// Triggers overseas cargo preference so auto-transport can deliver riches to
/// stockpile before the next build pass (Refs #2509).
///
/// Delegates to [expand_phase_planner.isBelowQuotaPeaceZeroRegimentsRebuild]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// EXPAND-trap callers that share the zero-regiments / invadable-frontier
/// gate.
bool isBelowQuotaPeaceZeroRegimentsRebuild({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool hasInvadableProvinces,
}) => expand_phase_planner.isBelowQuotaPeaceZeroRegimentsRebuild(
  oldWorldProvincesOwned: oldWorldProvincesOwned,
  regimentCount: regimentCount,
  hasInvadableProvinces: hasInvadableProvinces,
);

/// Below-quota EXPAND treasury-recovery composite (Arms A + B).
///
/// Delegates to [expand_phase_planner.isBelowQuotaPeaceTreasuryRecovery]
/// (Refs #2509 S1) so the canonical three-arm EXPAND-trap composite lives
/// alongside [expand_phase_planner.isBelowQuotaPeaceZeroRegimentsRebuild]
/// (Arm A) and [expand_phase_planner.isBelowQuotaPeaceInsufficientRegiments]
/// (Arm B) plus the [expand_phase_planner.cheapestRegimentBuildTreasuryCost]
/// affordability gate that all share an EXPAND-trap callsite contract.
bool isBelowQuotaPeaceTreasuryRecovery({
  required int oldWorldProvincesOwned,
  required int regimentCount,
  required bool atWarWithAnyGreatPower,
  required bool hasInvadableProvinces,
  required int treasury,
  required Stockpile stockpile,
}) => expand_phase_planner.isBelowQuotaPeaceTreasuryRecovery(
  oldWorldProvincesOwned: oldWorldProvincesOwned,
  regimentCount: regimentCount,
  atWarWithAnyGreatPower: atWarWithAnyGreatPower,
  hasInvadableProvinces: hasInvadableProvinces,
  treasury: treasury,
  stockpile: stockpile,
);

/// Both GPs in the 8–9 OW stalled band, below the observer quota, with similar holdings.
///
/// Delegates to [expand_phase_planner.isMutualBelowQuotaPlateauPeer]
/// (Refs #2509 S1).
bool isMutualBelowQuotaPlateauPeer({
  required int ownOw,
  required int partnerOw,
}) => expand_phase_planner.isMutualBelowQuotaPlateauPeer(
  ownOw: ownOw,
  partnerOw: partnerOw,
);

/// Peace other below-quota Great Powers in peer-stalled wars while minors remain
/// (exit mutual gp5/gp6 distraction; Refs #2509).
///
/// Delegates to [expand_phase_planner.belowQuotaPeerGpPeaceTargets]
/// (Refs #2509 S1) so the EXPAND-phase below-quota peer-stalled peace
/// decider survives the planned deletion of this file alongside the
/// canonical helpers it composes
/// ([expand_phase_planner.isOldWorldGpOnlyInvadableFrontier],
/// [expand_phase_planner.soleAtWarGreatPowerId],
/// [expand_phase_planner.isMutualBelowQuotaPlateauPeer], and
/// [expand_phase_planner.hasUninvadedOldWorldMinor]).
List<String> belowQuotaPeerGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.belowQuotaPeerGpPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace at-war minors that own no invadable OW provinces while still at default
/// start size (exit futile minor fronts before GP-blocker wars; seed-42 gp4).
///
/// Delegates to [expand_phase_planner.defaultStartFutileMinorPeaceTargets]
/// (Refs #2509 S1) so the EXPAND default-start futile-minor peace decider
/// survives the planned deletion of this file alongside the canonical
/// [expand_phase_planner.isOldWorldGpOnlyInvadableFrontier] band selector
/// it composes.
List<String> defaultStartFutileMinorPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.defaultStartFutileMinorPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// At default observer start size (7 OW), peace every Great Power war so the GP
/// can open a minor frontier (seed-42 gp4 zero-gain stall; Refs #2509).
///
/// Delegates to [expand_phase_planner.defaultStartGpPeaceTargets]
/// (Refs #2509 S1) so the EXPAND default-start GP-peace decider survives
/// the planned deletion of this file alongside the canonical
/// [expand_phase_planner.hasUninvadedOldWorldMinor],
/// [expand_phase_planner.isOldWorldGpOnlyInvadableFrontier], and
/// [expand_phase_planner.primaryInvadableOldWorldGpBlocker] helpers it
/// composes.
List<String> defaultStartGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.defaultStartGpPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace distracting GP wars at 8–9 OW while below the observer quota (hold gains;
/// seed-42 gp3; Refs #2509).
///
/// Delegates to [expand_phase_planner.nearQuotaHoldPeaceTargets]
/// (Refs #2509 S1) so the EXPAND near-quota hold-gains peace decider
/// survives the planned deletion of this file alongside the canonical
/// [expand_phase_planner.primaryInvadableOldWorldGpBlocker],
/// [expand_phase_planner.isOldWorldGpOnlyInvadableFrontier],
/// [expand_phase_planner.isMutualBelowQuotaPlateauPeer], and
/// [expand_phase_planner.hasUninvadedOldWorldMinor] helpers it composes.
List<String> nearQuotaHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.nearQuotaHoldPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// GP owning the most invadable Old World provinces (frontier blocker).
///
/// Delegates to [expand_phase_planner.primaryInvadableOldWorldGpBlocker]
/// (Refs #2509 S1).
String? primaryInvadableOldWorldGpBlocker({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.primaryInvadableOldWorldGpBlocker(
  game: game,
  snapshot: snapshot,
);

// `hasColonialAcquisitionTargets` and `isEarlyColonialExpansion` were
// relocated to `observer_goal_phase.dart` (Refs #2509 S1) — both
// `ColonialSummary` predicates must survive the planned deletion of this
// file. See also: `phase-planner-architecture.md` § Phase transition
// guards.

/// Sole at-war Great Power, if any.
///
/// Delegates to [expand_phase_planner.soleAtWarGreatPowerId] (Refs #2509 S1)
/// so the sole-GP-foe precondition shared by
/// [unwinnableSoleGpFrontierPeaceTarget], [consolidateGainsSoleGpPeaceTarget],
/// and [belowQuotaPeerGpPeaceTargets] survives the planned deletion of this
/// file alongside the EXPAND-phase peace deciders that consume it.
String? soleAtWarGreatPowerId({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    expand_phase_planner.soleAtWarGreatPowerId(game: game, snapshot: snapshot);

/// Whether peacing a below-quota sole-GP war leaves the active player a
/// pivot path back to OW expansion (uninvaded minor or minor-owned
/// invadable frontier).
///
/// Delegates to [expand_phase_planner.canPivotFromSoleGpWarAfterPeace]
/// (Refs #2509 S1) so the EXPAND-phase pivot guard consumed by
/// [unwinnableSoleGpFrontierPeaceTarget] survives the planned deletion of
/// this file alongside the sole-GP peace decider that calls it.
bool canPivotFromSoleGpWarAfterPeace({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.canPivotFromSoleGpWarAfterPeace(
  game: game,
  snapshot: snapshot,
);

/// Peace the sole GP enemy when below the observer OW quota and clearly outgunned.
///
/// Delegates to [expand_phase_planner.unwinnableSoleGpFrontierPeaceTarget]
/// (Refs #2509 S1) so the EXPAND-phase below-quota outgunned sole-GP peace
/// decider survives the planned deletion of this file alongside the
/// canonical helpers it composes (`soleAtWarGreatPowerId`,
/// `canPivotFromSoleGpWarAfterPeace`, `isOldWorldGpOnlyInvadableFrontier`).
String? unwinnableSoleGpFrontierPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.unwinnableSoleGpFrontierPeaceTarget(
  game: game,
  snapshot: snapshot,
);

/// Great Power wars already targeting [targetGpId] (resolved relations plus
/// same-turn declare-war orders from earlier Full AI players).
///
/// Delegates to [expand_phase_planner.greatPowerWarCountOnTarget]
/// (Refs #2509 S1) so the declare-war coordination helper survives the
/// planned deletion of this file alongside its EXPAND-phase callers in
/// `diplomatic_candidate_scoring_declare_war.dart` (war concentration
/// suppression).
int greatPowerWarCountOnTarget({
  required Game game,
  required String targetGpId,
  Orders? sameTurnPriorDiplomaticOrders,
}) => expand_phase_planner.greatPowerWarCountOnTarget(
  game: game,
  targetGpId: targetGpId,
  sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
);

/// True when [declarerFactionId] has a same-turn declare-war on [targetFactionId]
/// in [sameTurnPriorDiplomaticOrders] (earlier Full AI players).
///
/// Delegates to [expand_phase_planner.pendingDeclareWarFrom]
/// (Refs #2509 S1) so the same-turn declare-war ordering helper survives
/// the planned deletion of this file alongside the
/// `diplomatic_candidate_scoring_declare_war.dart` consumer that uses it
/// to suppress mutual declare-war dogpiles.
bool pendingDeclareWarFrom({
  required Orders? sameTurnPriorDiplomaticOrders,
  required String declarerFactionId,
  required String targetFactionId,
}) => expand_phase_planner.pendingDeclareWarFrom(
  sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
  declarerFactionId: declarerFactionId,
  targetFactionId: targetFactionId,
);

/// Peace at-war Great Powers that lead by [kUnwinnableSoleGpMinProvinceDeficit]
/// or more while below the observer quota (even with minor wars; Refs #2509).
///
/// Delegates to [expand_phase_planner.stalledBelowQuotaGpLeadPeaceTargets]
/// (Refs #2509 S1) so the EXPAND-phase below-quota lead-peace decider
/// survives the planned deletion of this file alongside the canonical
/// helpers it composes ([expand_phase_planner.isOldWorldGpOnlyInvadableFrontier]
/// and [expand_phase_planner.primaryInvadableOldWorldGpBlocker]).
List<String> stalledBelowQuotaGpLeadPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.stalledBelowQuotaGpLeadPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace every below-quota Great Power at war once this GP meets the observer
/// quota (stop mop-up wars after the frontier is cleared; Refs #2509).
///
/// Delegates to [expand_phase_planner.quotaMetBelowQuotaAtWarPeaceTargets]
/// (Refs #2509 S1) so the quota-met below-quota at-war peace decider
/// survives the planned deletion of this file alongside the canonical
/// [expand_phase_planner.consolidateGainsSoleGpPeaceTarget] sibling that
/// shares the quota-met outer guard and the GP-vs-GP at-war filter.
List<String> quotaMetBelowQuotaAtWarPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.quotaMetBelowQuotaAtWarPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace below-quota Great Powers while this GP meets the observer quota and the
/// victim does not own this GP's invadable OW frontier (Refs #2509).
///
/// Delegates to [expand_phase_planner.quotaMetFutileBelowQuotaGpPeaceTargets]
/// (Refs #2509 S1) so the narrower quota-met futile-peace decider
/// survives the planned deletion of this file alongside the broader
/// [expand_phase_planner.quotaMetBelowQuotaAtWarPeaceTargets] sibling
/// and the [expand_phase_planner.primaryInvadableOldWorldGpBlocker]
/// defensive backstop helper it composes.
List<String> quotaMetFutileBelowQuotaGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.quotaMetFutileBelowQuotaGpPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace every at-war Great Power when OW holdings are critically low and minors
/// remain on the map (avoid OW elimination; Refs #2509).
///
/// Peace all GP wars when critically weak (≤6 OW) or stalled with minors left.
///
/// Delegates to [expand_phase_planner.criticalOwHoldPeaceTargets]
/// (Refs #2509 S1) so the EXPAND-phase critical-hold peace decider
/// survives the planned deletion of this file alongside the canonical
/// sibling below-quota peace deciders (
/// [expand_phase_planner.stalledBelowQuotaGpLeadPeaceTargets],
/// [expand_phase_planner.unwinnableSoleGpFrontierPeaceTarget],
/// [expand_phase_planner.consolidateGainsSoleGpPeaceTarget]).
List<String> criticalOwHoldPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.criticalOwHoldPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace the sole GP enemy when the observer OW quota is met and this GP leads.
///
/// Delegates to [expand_phase_planner.consolidateGainsSoleGpPeaceTarget]
/// (Refs #2509 S1) so the quota-met consolidate-gains sole-GP peace decider
/// survives the planned deletion of this file alongside the canonical
/// [expand_phase_planner.soleAtWarGreatPowerId] precondition helper it
/// composes.
String? consolidateGainsSoleGpPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.consolidateGainsSoleGpPeaceTarget(
  game: game,
  snapshot: snapshot,
);

// `colonialBuildOrderThresholdCap(ColonialSummary)` was retired here
// (Refs #2509 S1). The legacy helper had two arms keyed on
// `hasColonialAcquisitionTargets(colonial)` and was only invoked by
// `_appendEconomyBuildOrders` inside the outer `if (colonialPressure)` guard,
// where `colonialPressure` is `resolvePhaseEconomyColonialPressureActive`
// (active only under COLONIAL). COLONIAL phase entry is itself gated on
// `hasColonialAcquisitionTargets` via `observerGoalPhaseFor`, so the second
// `kColonialBuildOrderThresholdWhenOwnedNw` fallback arm was structurally
// unreachable at the orchestrator's call site. The reachable behaviour now
// lives in `resolvePhaseEconomyColonialBuildOrderThresholdCap`
// (`phase_planner_economy_filter.dart`), which is the sole production caller
// of the colonial build-order threshold cap. See
// `SPEC/ai/phase-planner-dispatch.md` § Orchestrator economy build colonial
// -cap slice.
