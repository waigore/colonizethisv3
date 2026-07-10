// Table-driven remaining work handler scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'remaining_work_handlers_run_rows.dart';

/// One row in [remainingWorkHandlersScenarios].
class RemainingWorkHandlersScenario implements RefsScenario {
  const RemainingWorkHandlersScenario({
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

void runRemainingWorkHandlersScenario(RemainingWorkHandlersScenario scenario) =>
    scenario.run();

/// Canonical scenarios for remaining_work_handlers family tests.
List<RemainingWorkHandlersScenario> remainingWorkHandlersScenarios() => const [
      RemainingWorkHandlersScenario(
        label: 'supports only counter_spy',
        run: rwhRunSupportsOnlyCounterSpy,
      ),
      RemainingWorkHandlersScenario(
        label: 'tryApply assigns counter_spy work for spy unit',
        run: rwhRunTryApplyCounterSpy,
      ),
      RemainingWorkHandlersScenario(
        label: 'supports only prospect',
        run: rwhRunSupportsOnlyProspect,
      ),
      RemainingWorkHandlersScenario(
        label: 'tryApply returns false for non-mineral tile',
        run: rwhRunTryApplyProspectNonMineral,
      ),
      RemainingWorkHandlersScenario(
        label: 'returns false when unit already has currentWork',
        run: rwhRunStandardWorkOrderAlreadyWorking,
      ),
      RemainingWorkHandlersScenario(
        label: 'skips fort level 2 when Mine Engineering not unlocked',
        run: rwhRunSkipFortMissingTech,
      ),
      RemainingWorkHandlersScenario(
        label: 'each standard build handler supports only its target',
        run: rwhRunStandardBuildSupportsOnlyTarget,
      ),
      RemainingWorkHandlersScenario(
        label: 'maps every standard and simple work target to a handler',
        run: rwhRunRegistryMapsAllTargets,
      ),
      RemainingWorkHandlersScenario(
        label: 'singleton handlers do not cross-support other simple targets',
        run: rwhRunSingletonNoCrossSupport,
      ),
    ];
