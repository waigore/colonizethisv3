import 'package:colonizethis_logic/order_suggestion_api.dart';

import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import 'planning_imports.dart';

/// Shared inputs for domain planners. Built once per orchestrator pass.
class PlannerContext {
  const PlannerContext({
    required this.nationId,
    required this.view,
    required this.game,
    required this.topology,
    required this.orders,
    required this.config,
    required this.primaryGoal,
    required this.seeds,
    required this.suggestionAPI,
    this.snapshot,
    Map<String, String>? provinceOwnerCache,
    this.currentTurn,
  }) : _provinceOwnerCache = provinceOwnerCache;

  final String nationId;
  final PlayerView view;
  final Game game;
  final MapTopology topology;
  final Orders orders;
  final AIConfig config;
  final StrategicGoal primaryGoal;
  final AISeedBundle seeds;
  final OrderSuggestionAPI suggestionAPI;
  final AIWorldSnapshot? snapshot;
  final int? currentTurn;

  final Map<String, String>? _provinceOwnerCache;

  /// Province owner map; computed once per context when not supplied.
  Map<String, String> get provinceOwner =>
      _provinceOwnerCache ?? getProvinceOwnerMap(game);

  /// Returns a copy with updated [orders], reusing cached derived state.
  PlannerContext withOrders(Orders orders) => PlannerContext(
        nationId: nationId,
        view: view,
        game: game,
        topology: topology,
        orders: orders,
        config: config,
        primaryGoal: primaryGoal,
        seeds: seeds,
        suggestionAPI: suggestionAPI,
        snapshot: snapshot,
        provinceOwnerCache: _provinceOwnerCache,
        currentTurn: currentTurn,
      );

  PersonalityDomainWeights get domainWeights =>
      getDomainWeightsForLeader(config.personalityId);

  /// Resolves domain weight from [primaryGoal] and personality weights.
  ///
  /// [kind] selects the goal→weight mapping used by move/conquest/army (default),
  /// naval, diplomacy, or research planners.
  int resolveWeightForDomain({
    DomainWeightKind kind = DomainWeightKind.militaryEconomyOrBase,
    int base = 50,
  }) {
    final weights = domainWeights;
    switch (kind) {
      case DomainWeightKind.militaryEconomyOrBase:
        if (primaryGoal == StrategicGoal.conquer ||
            primaryGoal == StrategicGoal.defend) {
          return weights.military;
        }
        if (primaryGoal == StrategicGoal.expand) {
          return weights.economy;
        }
        return base;
      case DomainWeightKind.militaryOrBase:
        if (primaryGoal == StrategicGoal.conquer ||
            primaryGoal == StrategicGoal.defend ||
            primaryGoal == StrategicGoal.expand) {
          return weights.military;
        }
        return base;
      case DomainWeightKind.diplomacyOrBase:
        if (primaryGoal == StrategicGoal.diplomacy ||
            primaryGoal == StrategicGoal.conquer ||
            primaryGoal == StrategicGoal.trade) {
          return weights.diplomacy;
        }
        return base;
      case DomainWeightKind.research:
        return weights.research;
    }
  }
}

/// Goal→weight mapping variants used by domain planners.
enum DomainWeightKind {
  militaryEconomyOrBase,
  militaryOrBase,
  diplomacyOrBase,
  research,
}
