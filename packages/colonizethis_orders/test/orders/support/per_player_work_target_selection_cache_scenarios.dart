// Table-driven per-player work target selection cache scenarios (Refs #3949 wave 3).

import 'scenario_runner.dart';
import 'per_player_work_target_selection_cache_expectations.dart';

/// One row in [perPlayerWorkTargetSelectionCacheScenarios].
class PerPlayerWorkTargetSelectionCacheScenario implements RefsScenario {
  const PerPlayerWorkTargetSelectionCacheScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final PerPlayerWorkTargetSelectionCacheTarget target;
  @override
  final String? refs;
}

void runPerPlayerWorkTargetSelectionCacheScenario(
  PerPlayerWorkTargetSelectionCacheScenario scenario,
) {
  runPerPlayerWorkTargetSelectionCacheExpectation(scenario.target);
}

/// Canonical scenarios for PerPlayerWorkTargetSelectionCache family tests.
List<PerPlayerWorkTargetSelectionCacheScenario>
    perPlayerWorkTargetSelectionCacheScenarios() => const [
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'default strategies refresh runs all population paths',
            target: PerPlayerWorkTargetSelectionCacheTarget
                .defaultStrategiesRefreshAllPaths,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'sorted returns deterministic ordering',
            target:
                PerPlayerWorkTargetSelectionCacheTarget.sortedDeterministicOrdering,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'contains returns false for missing membership',
            target:
                PerPlayerWorkTargetSelectionCacheTarget.containsMissingMembership,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh replaces target membership on turn-boundary style update',
            target:
                PerPlayerWorkTargetSelectionCacheTarget.refreshReplacesOnTurnBoundary,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh keeps cache isolated per player',
            target:
                PerPlayerWorkTargetSelectionCacheTarget.refreshIsolatedPerPlayer,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh stores and reads prospect membership',
            target:
                PerPlayerWorkTargetSelectionCacheTarget.refreshProspectMembership,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh injects one shared incremental validator for all strategies',
            target: PerPlayerWorkTargetSelectionCacheTarget
                .refreshSharedIncrementalValidator,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh reuses caller-supplied playerOwnedProvinceIds when set (Refs #2394)',
            target: PerPlayerWorkTargetSelectionCacheTarget
                .refreshReusesPlayerOwnedProvinceIds,
            refs: '#2394',
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh built validator reuses snapshot playerView (Refs #2394)',
            target:
                PerPlayerWorkTargetSelectionCacheTarget.refreshValidatorReusesPlayerView,
            refs: '#2394',
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh reuses caller-supplied sharedCandidateValidator when set (Refs #2394)',
            target: PerPlayerWorkTargetSelectionCacheTarget
                .refreshReusesSharedCandidateValidator,
            refs: '#2394',
          ),
        ];
