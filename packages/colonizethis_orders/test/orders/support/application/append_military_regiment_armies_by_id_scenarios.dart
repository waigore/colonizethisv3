// Table-driven appendMilitaryRegimentToArmy armiesById scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'append_military_regiment_armies_by_id_expectations.dart';

/// One row in [appendMilitaryRegimentArmiesByIdScenarios].
class AppendMilitaryRegimentArmiesByIdScenario implements RefsScenario {
  const AppendMilitaryRegimentArmiesByIdScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final AppendMilitaryRegimentArmiesByIdTarget target;
  @override
  final String? refs;
}

void runAppendMilitaryRegimentArmiesByIdScenario(
  AppendMilitaryRegimentArmiesByIdScenario scenario,
) {
  runAppendMilitaryRegimentArmiesByIdExpectation(scenario.target);
}

/// Canonical scenarios for append_military_regiment_armies_by_id family tests.
List<AppendMilitaryRegimentArmiesByIdScenario>
    appendMilitaryRegimentArmiesByIdScenarios() => const [
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'create-new-army path matches with and without armiesById',
            target: AppendMilitaryRegimentArmiesByIdTarget.createNewArmyPathEquivalence,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'append-existing-army path matches with and without armiesById',
            target:
                AppendMilitaryRegimentArmiesByIdTarget.appendExistingArmyPathEquivalence,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'mutates armiesById in place when appending to an existing army',
            target: AppendMilitaryRegimentArmiesByIdTarget.mutatesArmiesByIdWhenAppending,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'mutates armiesById in place when creating a new army',
            target: AppendMilitaryRegimentArmiesByIdTarget.mutatesArmiesByIdWhenCreating,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'multiple recruits with shared map match repeated scan-path runs',
            target: AppendMilitaryRegimentArmiesByIdTarget.multipleRecruitsWithSharedMap,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'falls back to single-pass scan when armiesById lacks the entry',
            target: AppendMilitaryRegimentArmiesByIdTarget.fallsBackWhenPartialMap,
            refs: '#2394',
          ),
        ];
