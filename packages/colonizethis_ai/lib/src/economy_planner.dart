// Economy planner: worker allocation and cargo preference. SPEC/ai/economy-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'ai_config.dart';
import 'seed_bundle.dart';

final Logger _log = Logger();

const String _kEconomyLogPrefix = 'ai/economy_planner';

/// Cargo preference for naval/build planners. SPEC/ai/economy-planner.md.
enum CargoPreference {
  none,
  preferCargo,
  strongCargo,
}

/// Result of the economy planner for one AI player.
class EconomyPlan {
  const EconomyPlan({
    required this.productionAssignments,
    required this.cargoPreference,
  });

  /// Labour assignments per recipe for the Production phase.
  final List<AssignedRecipe> productionAssignments;

  /// Preference for cargo capacity (join home fleet / build merchants).
  final CargoPreference cargoPreference;
}

/// Shortage target below which we consider a commodity "needed".
const int _kShortageThreshold = 8;

/// Weight for shortage component in recipe score.
const double _kShortageWeight = 2.0;

/// Weight for chain/luxury value.
const double _kChainWeight = 1.0;

/// Weight for agenda/personality modifier.
const double _kAgendaWeight = 0.5;

/// Runs the economy planner for one AI-controlled player. Deterministic given
/// [game], [view], [config], and [seeds]. Returns production assignments and
/// cargo preference. SPEC/ai/economy-planner.md.
EconomyPlan runEconomyPlanner({
  required Game game,
  required PlayerView view,
  required AIConfig config,
  required AISeedBundle seeds,
}) {
  final player = game.playerById(view.playerId);
  if (player == null) {
    _log.w('$_kEconomyLogPrefix: no player for ${view.playerId}');
    return const EconomyPlan(
      productionAssignments: [],
      cargoPreference: CargoPreference.none,
    );
  }

  final stockpile = player.stockpile;
  final workers = player.workerPool;
  final effectiveLabour = effectiveLabourForWorkers(
    workers: workers,
    stockpile: stockpile,
  );

  if (effectiveLabour <= 0) {
    return EconomyPlan(
      productionAssignments: [],
      cargoPreference: _cargoPreference(game, view.playerId, config),
    );
  }

  final assignments = _allocateLabour(
    stockpile: stockpile,
    workers: workers,
    effectiveLabour: effectiveLabour,
    config: config,
    seeds: seeds,
  );

  final cargoPref = _cargoPreference(game, view.playerId, config);
  _log.i(
    '$_kEconomyLogPrefix: economy plan playerId=${view.playerId} '
    'cargoPreference=$cargoPref productionAssignmentsCount=${assignments.length}',
  );
  return EconomyPlan(
    productionAssignments: assignments,
    cargoPreference: cargoPref,
  );
}

CargoPreference _cargoPreference(Game game, String playerId, AIConfig config) {
  final domainWeights = getDomainWeightsForLeader(config.leaderId);
  final agendaId = config.hiddenAgendaId;
  // Trade-oriented agendas/personalities favour cargo.
  final economyWeight = domainWeights.economy;
  if (economyWeight < 30) {
    _log.d('$_kEconomyLogPrefix: cargoPreference none economyWeight=$economyWeight');
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
    '$_kEconomyLogPrefix: cargoPreference eval playerId=$playerId '
    'economyWeight=$economyWeight agendaId=$agendaId tradeBias=$tradeBias result=$pref',
  );
  return pref;
}

List<AssignedRecipe> _allocateLabour({
  required Stockpile stockpile,
  required WorkerPool workers,
  required int effectiveLabour,
  required AIConfig config,
  required AISeedBundle seeds,
}) {
  final recipes = ProductionRecipesCatalog.all;
  final agendaId = config.hiddenAgendaId;
  Stockpile virtual = stockpile;
  var remainingLabour = effectiveLabour;
  final result = <AssignedRecipe>[];

  // Build feasible recipes with scores. Feasible = can run at least 1 full run.
  final candidates = <_ScoredRecipe>[];
  for (final recipe in recipes) {
    final labourPerOutput = recipe.labourPerOutput;
    if (labourPerOutput <= 0) continue;
    int maxByInputs = 999999;
    for (final entry in recipe.inputQuantities.entries) {
      final have = virtual.quantityOf(entry.key);
      final need = entry.value;
      if (need <= 0) continue;
      final runs = have ~/ need;
      if (runs < maxByInputs) maxByInputs = runs;
    }
    if (maxByInputs <= 0) continue;
    final maxByLabour = remainingLabour ~/ labourPerOutput;
    if (maxByLabour <= 0) continue;
    final feasibleRuns = maxByInputs < maxByLabour ? maxByInputs : maxByLabour;
    if (feasibleRuns <= 0) continue;

    final score = _scoreRecipe(
      recipe: recipe,
      stockpile: virtual,
      workers: workers,
      agendaId: agendaId,
    );
    candidates.add(_ScoredRecipe(recipe: recipe, score: score));
  }

  if (candidates.isEmpty) return result;

  _log.d(
    '$_kEconomyLogPrefix: recipe eval playerId=${config.leaderId} effectiveLabour=$effectiveLabour '
    'candidates=${candidates.map((c) => "${c.recipe.id}:${c.score.toStringAsFixed(2)}").toList()}',
  );

  // Sort by score descending; use seed for tie-break.
  candidates.sort((a, b) {
    final c = b.score.compareTo(a.score);
    if (c != 0) return c;
    return a.recipe.id.compareTo(b.recipe.id);
  });

  virtual = stockpile;
  remainingLabour = effectiveLabour;
  final labourByRecipe = <String, int>{};

  for (final scored in candidates) {
    if (remainingLabour <= 0) break;
    final recipe = scored.recipe;
    int maxByInputs = 999999;
    for (final entry in recipe.inputQuantities.entries) {
      final have = virtual.quantityOf(entry.key);
      final need = entry.value;
      if (need <= 0) continue;
      final runs = have ~/ need;
      if (runs < maxByInputs) maxByInputs = runs;
    }
    if (maxByInputs <= 0) continue;
    final maxByLabour = remainingLabour ~/ recipe.labourPerOutput;
    if (maxByLabour <= 0) continue;
    final runs = maxByInputs < maxByLabour ? maxByInputs : maxByLabour;
    if (runs <= 0) continue;

    final labourUsed = runs * recipe.labourPerOutput;
    labourByRecipe[recipe.id] = (labourByRecipe[recipe.id] ?? 0) + labourUsed;
    remainingLabour -= labourUsed;
    for (final entry in recipe.inputQuantities.entries) {
      virtual = virtual.applyDelta(entry.key, -entry.value * runs);
    }
    virtual = virtual.applyDelta(recipe.outputCommodityId, recipe.outputQuantity * runs);
  }

  for (final entry in labourByRecipe.entries) {
    result.add(AssignedRecipe(recipeId: entry.key, assignedLabour: entry.value));
  }

  _log.d(
    '$_kEconomyLogPrefix: allocation effectiveLabour=$effectiveLabour '
    'labourByRecipe=$labourByRecipe assignmentsCount=${result.length}',
  );
  return result;
}

class _ScoredRecipe {
  _ScoredRecipe({required this.recipe, required this.score});
  final ProductionRecipe recipe;
  final double score;
}

double _scoreRecipe({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required WorkerPool workers,
  required String agendaId,
}) {
  final outputId = recipe.outputCommodityId;
  final have = stockpile.quantityOf(outputId);

  // Shortage: prefer producing what we have little of.
  final shortage = have < _kShortageThreshold
      ? (_kShortageThreshold - have).toDouble()
      : 0.0;

  // Chain value: outputs that feed other recipes or are luxuries.
  double chain = 0.0;
  if (outputId == CommodityCatalog.refinedSugar.id) {
    chain = 1.0;
    if (workers.apprentices > 0) chain += 1.0;
  } else if (outputId == CommodityCatalog.cigars.id) {
    chain = 1.0;
    if (workers.journeymen > 0) chain += 1.0;
  } else if (outputId == CommodityCatalog.furHats.id) {
    chain = 1.0;
    if (workers.masters > 0) chain += 1.0;
  } else if (outputId == CommodityCatalog.lumber.id ||
      outputId == CommodityCatalog.castIron.id) {
    chain = 0.8; // Used in builds and other recipes.
  } else if (outputId == CommodityCatalog.fabric.id) {
    chain = 0.5; // Recruiting, builds.
  }

  // Agenda: warmonger favours military-related (castIron, lumber); industrial_trader favours trade goods.
  double agenda = 0.0;
  if (agendaId == 'warmonger' &&
      (outputId == CommodityCatalog.castIron.id ||
          outputId == CommodityCatalog.lumber.id)) {
    agenda = 1.0;
  } else if ((agendaId == 'industrial_trader' || agendaId == 'merchant') &&
      (outputId == CommodityCatalog.fabric.id ||
          outputId == CommodityCatalog.refinedSugar.id ||
          outputId == CommodityCatalog.cigars.id ||
          outputId == CommodityCatalog.furHats.id)) {
    agenda = 0.5;
  }

  return shortage * _kShortageWeight + chain * _kChainWeight + agenda * _kAgendaWeight;
}
