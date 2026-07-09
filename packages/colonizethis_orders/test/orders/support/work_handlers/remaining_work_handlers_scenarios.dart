// Table-driven remaining work handler scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'remaining_work_handlers_expectations.dart';

/// One row in [remainingWorkHandlersScenarios].
class RemainingWorkHandlersScenario implements RefsScenario {
  const RemainingWorkHandlersScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final RemainingWorkHandlersTarget target;
  @override
  final String? refs;
}

void runRemainingWorkHandlersScenario(RemainingWorkHandlersScenario scenario) {
  runRemainingWorkHandlersExpectation(scenario.target);
}

/// Canonical scenarios for remaining_work_handlers family tests.
List<RemainingWorkHandlersScenario> remainingWorkHandlersScenarios() => const [
      RemainingWorkHandlersScenario(
        label: 'supports only counter_spy',
        target: RemainingWorkHandlersTarget.supportsOnlyCounterSpy,
      ),
      RemainingWorkHandlersScenario(
        label: 'tryApply assigns counter_spy work for spy unit',
        target: RemainingWorkHandlersTarget.tryApplyCounterSpy,
      ),
      RemainingWorkHandlersScenario(
        label: 'supports only prospect',
        target: RemainingWorkHandlersTarget.supportsOnlyProspect,
      ),
      RemainingWorkHandlersScenario(
        label: 'tryApply returns false for non-mineral tile',
        target: RemainingWorkHandlersTarget.tryApplyProspectNonMineral,
      ),
      RemainingWorkHandlersScenario(
        label: 'returns false when unit already has currentWork',
        target: RemainingWorkHandlersTarget.standardWorkOrderAlreadyWorking,
      ),
      RemainingWorkHandlersScenario(
        label: 'skips fort level 2 when Mine Engineering not unlocked',
        target: RemainingWorkHandlersTarget.skipFortMissingTech,
      ),
      RemainingWorkHandlersScenario(
        label: 'each standard build handler supports only its target',
        target: RemainingWorkHandlersTarget.standardBuildSupportsOnlyTarget,
      ),
      RemainingWorkHandlersScenario(
        label: 'maps every standard and simple work target to a handler',
        target: RemainingWorkHandlersTarget.registryMapsAllTargets,
      ),
      RemainingWorkHandlersScenario(
        label: 'singleton handlers do not cross-support other simple targets',
        target: RemainingWorkHandlersTarget.singletonNoCrossSupport,
      ),
    ];
