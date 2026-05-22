import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodities.dart';
import 'data_validation_exception.dart';
import 'tech_ids.dart';

/// Worker recruit / train cost row for one [WorkerTier].
///
/// Recruit and train share one cost row per non-peasant tier; peasant has
/// only a recruit row (no peasant consumed). SPEC source of truth:
/// `SPEC/game/workers-and-population.md` § Recruiting, Training, and
/// Disbanding (cost table).
class WorkerActionEconomy {
  const WorkerActionEconomy({
    required this.targetTier,
    required this.treasuryCost,
    required this.materialCosts,
    required this.consumesPeasant,
    required this.requiredTechIds,
  });

  /// Tier added to the WorkerPool when the action resolves.
  final WorkerTier targetTier;

  /// Ducat cost deducted from the player's treasury when the action
  /// resolves (0 means free).
  final int treasuryCost;

  /// Commodity costs (id -> quantity) deducted from the stockpile.
  /// Positive integers only.
  final Map<CommodityId, int> materialCosts;

  /// When true, the resolver decrements `pool.peasants` by 1 in addition
  /// to incrementing [targetTier]. False only for the peasant recruit row.
  final bool consumesPeasant;

  /// Tech ids that must all be present in the player's `techUnlocked`
  /// for the action to be allowed. Empty for the peasant row.
  final List<String> requiredTechIds;
}

/// Authoritative worker action cost rows for v1.
///
/// Values are program-level (no JSON rulesets) and MUST match
/// `SPEC/game/workers-and-population.md` § Recruiting, Training, and
/// Disbanding (cost table). Disband is not a cost row — it is an
/// immediate Orders-phase action with no resource cost (see
/// `SPEC/game/workers-and-population.md` § Disband).
class WorkerActionEconomyCatalog {
  static final WorkerActionEconomy peasant = WorkerActionEconomy(
    targetTier: WorkerTier.peasant,
    treasuryCost: 0,
    materialCosts: {CommodityCatalog.fabric.id: 2},
    consumesPeasant: false,
    requiredTechIds: const [],
  );

  static final WorkerActionEconomy apprentice = WorkerActionEconomy(
    targetTier: WorkerTier.apprentice,
    treasuryCost: 200,
    materialCosts: {CommodityCatalog.paper.id: 2},
    consumesPeasant: true,
    requiredTechIds: const [
      kTechIdApprenticeWorkers,
      kTechIdSugarRefining,
    ],
  );

  static final WorkerActionEconomy journeyman = WorkerActionEconomy(
    targetTier: WorkerTier.journeyman,
    treasuryCost: 500,
    materialCosts: {CommodityCatalog.paper.id: 5},
    consumesPeasant: true,
    requiredTechIds: const [
      kTechIdTrainedJourneymen,
      kTechIdCigarProduction,
    ],
  );

  static final WorkerActionEconomy master = WorkerActionEconomy(
    targetTier: WorkerTier.master,
    treasuryCost: 1000,
    materialCosts: {CommodityCatalog.paper.id: 10},
    consumesPeasant: true,
    requiredTechIds: const [
      kTechIdMasterArtisans,
      kTechIdHatProduction,
    ],
  );

  /// All rows, ordered peasant → master so iteration matches the SPEC table.
  static final List<WorkerActionEconomy> all = [
    peasant,
    apprentice,
    journeyman,
    master,
  ];

  /// Fast lookup by target tier.
  static final Map<WorkerTier, WorkerActionEconomy> byTier = {
    for (final e in all) e.targetTier: e,
  };

  /// Throws [DataValidationException] when a tier somehow has no catalog row
  /// (defensive guard against stale enum or partial registration).
  static WorkerActionEconomy forTier(WorkerTier tier) {
    final row = byTier[tier];
    if (row == null) {
      throw DataValidationException(
        'WorkerActionEconomyCatalog has no row for tier: $tier',
      );
    }
    return row;
  }
}
