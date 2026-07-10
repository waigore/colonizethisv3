// Table-driven per-player work target selection cache scenarios (Refs #3949 wave 3).

import 'scenario_runner.dart';
import 'per_player_work_target_selection_cache_run_rows.dart';

/// One row in [perPlayerWorkTargetSelectionCacheScenarios].
class PerPlayerWorkTargetSelectionCacheScenario implements RefsScenario {
  const PerPlayerWorkTargetSelectionCacheScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runPerPlayerWorkTargetSelectionCacheScenario(
  PerPlayerWorkTargetSelectionCacheScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for PerPlayerWorkTargetSelectionCache family tests.
List<PerPlayerWorkTargetSelectionCacheScenario>
    perPlayerWorkTargetSelectionCacheScenarios() => const [
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'default strategies refresh runs all population paths',
            run: ppwtscRunDefaultStrategiesRefreshAllPaths,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'sorted returns deterministic ordering',
            run: ppwtscRunSortedDeterministicOrdering,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'contains returns false for missing membership',
            run: ppwtscRunContainsMissingMembership,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh replaces target membership on turn-boundary style update',
            run: ppwtscRunRefreshReplacesOnTurnBoundary,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh keeps cache isolated per player',
            run: ppwtscRunRefreshIsolatedPerPlayer,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh stores and reads prospect membership',
            run: ppwtscRunRefreshProspectMembership,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh injects one shared incremental validator for all strategies',
            run: ppwtscRunRefreshSharedIncrementalValidator,
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh reuses caller-supplied playerOwnedProvinceIds when set (Refs #2394)',
            run: ppwtscRunRefreshReusesPlayerOwnedProvinceIds,
            refs: '#2394',
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh built validator reuses snapshot playerView (Refs #2394)',
            run: ppwtscRunRefreshValidatorReusesPlayerView,
            refs: '#2394',
          ),
          PerPlayerWorkTargetSelectionCacheScenario(
            label: 'refresh reuses caller-supplied sharedCandidateValidator when set (Refs #2394)',
            run: ppwtscRunRefreshReusesSharedCandidateValidator,
            refs: '#2394',
          ),
        ];
