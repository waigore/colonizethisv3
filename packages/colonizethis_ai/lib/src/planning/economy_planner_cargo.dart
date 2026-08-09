import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'expand_phase_planner.dart' hide cheapestRegimentBuildTreasuryCost;
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'planning_helpers.dart' show isAtWarWithAnyGreatPower;
import 'planning_imports.dart';

final _log = packageLogger('economy_planner_cargo');

/// Cargo preference and below-quota peace treasury-recovery helpers
/// (Refs #4104 Slice B).

CargoPreference economyPlannerCargoPreference(
  Game game,
  String playerId,
  AIConfig config, {
  ColonialSummary colonial = const ColonialSummary(),
  bool belowQuotaPeaceTreasuryRecovery = false,
}) {
  final domainWeights = resolveDomainWeights(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  final agendaId = config.hiddenAgendaId;
  // Trade-oriented agendas/personalities favour cargo.
  var economyWeight = domainWeights.economy;
  if (belowQuotaPeaceTreasuryRecovery) {
    economyWeight += kBelowQuotaPeaceTreasuryRecoveryCargoBoost;
  }
  if (colonial.invadableNewWorldProvinceIdsSorted.isNotEmpty ||
      colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty) {
    economyWeight += kColonialCargoPreferenceEconomyBoost;
  }
  if (colonial.newWorldProvincesOwned == 0 &&
      colonial.adjacentNewWorldOwnerFactionIdsSorted.isNotEmpty) {
    economyWeight += kColonialCargoPreferenceNoNwColoniesBoost;
  }
  if (economyWeight < 30) {
    _log.d('cargoPreference none economyWeight=$economyWeight');
    return CargoPreference.none;
  }
  // Strong when economy is high and agenda is trade-related.
  final tradeBias = agendaId == 'industrial_trader' || agendaId == 'merchant'
      ? 20
      : agendaId == 'navigator'
      ? 15
      : 0;
  final pref = economyWeight >= 70 + tradeBias
      ? CargoPreference.strongCargo
      : economyWeight >= 50 + tradeBias
      ? CargoPreference.preferCargo
      : CargoPreference.none;
  _log.d(
    'cargoPreference eval playerId=$playerId '
    'economyWeight=$economyWeight agendaId=$agendaId tradeBias=$tradeBias result=$pref',
  );
  return pref;
}

/// Resolves the EXPAND-phase "below-quota peace treasury recovery" cargo
/// boost trigger for `runEconomyPlanner`.
///
/// When [phasePlan] is supplied (Refs #2509 S5), the resolver routes the
/// two rebuild-trap arms through the phase-planner economy resolvers
/// instead of the legacy `colonial_pressure.dart` predicates:
///
/// - Zero-regiments rebuild arm ->
///   [resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive]
/// - Insufficient-regiments + treasury arm ->
///   [resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive]
///   paired with the same effective-treasury threshold used by the legacy
///   compute (`treasury + pendingRichesTreasuryDelta(...) <
///   cheapestRegimentBuildTreasuryCost()`).
///
/// Phase-derived `bool` is field-equal to the legacy
/// [isBelowQuotaPeaceTreasuryRecovery] compute under EXPAND / COLONIAL-lite
/// because both phases require
/// `oldWorldProvincesOwned < kObserverConquestMinOwProvincesPerGp` at
/// entry via [observerGoalPhaseFor], satisfying the legacy
/// `isBelowObserverConquestQuota` guard structurally. Under COLONIAL and
/// DEVELOP the phase resolvers collapse to `false`, mirroring the
/// suppression matrix established for the orchestrator's economy
/// build-pass slice (`_appendEconomyBuildOrders`).
///
/// When [phasePlan] is `null`, the helper falls back to the legacy
/// compute so test callers and other unmigrated entry points that
/// pre-date the S5 threading stay behaviour-equal on the
/// no-`phasePlan` path. When [snapshot] is `null`, the cargo boost
/// cannot be evaluated and the return is `false` (matches the prior
/// guard).
bool resolveBelowQuotaPeaceTreasuryRecovery({
  required Game game,
  required PlayerView view,
  required AIWorldSnapshot? snapshot,
  required PhasePlanOutcome? phasePlan,
  required int treasury,
  required Stockpile stockpile,
}) {
  if (snapshot == null) {
    return false;
  }
  final regimentCount = regimentCountForPlayer(game, view.playerId);
  final atWarWithAnyGreatPower = isAtWarWithAnyGreatPower(game, snapshot);
  final hasInvadableProvinces =
      snapshot.conquest.invadableProvinceIdsSorted.isNotEmpty;
  if (phasePlan == null) {
    return isBelowQuotaPeaceTreasuryRecovery(
      oldWorldProvincesOwned: snapshot.conquest.oldWorldProvincesOwned,
      regimentCount: regimentCount,
      atWarWithAnyGreatPower: atWarWithAnyGreatPower,
      hasInvadableProvinces: hasInvadableProvinces,
      treasury: treasury,
      stockpile: stockpile,
    );
  }
  if (resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive(
    phasePlan: phasePlan,
    regimentCount: regimentCount,
    hasInvadableProvinces: hasInvadableProvinces,
  )) {
    return true;
  }
  if (!resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive(
    phasePlan: phasePlan,
    regimentCount: regimentCount,
    atWarWithAnyGreatPower: atWarWithAnyGreatPower,
    hasInvadableProvinces: hasInvadableProvinces,
  )) {
    return false;
  }
  final effectiveTreasury =
      treasury + pendingRichesTreasuryDelta(stockpile: stockpile);
  return effectiveTreasury < cheapestRegimentBuildTreasuryCost();
}
