// Table-driven appendMilitaryRegimentToArmy armiesById scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'append_military_regiment_armies_by_id_run_rows.dart';

/// One row in [appendMilitaryRegimentArmiesByIdScenarios].
class AppendMilitaryRegimentArmiesByIdScenario implements RefsScenario {
  const AppendMilitaryRegimentArmiesByIdScenario({
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

void runAppendMilitaryRegimentArmiesByIdScenario(
  AppendMilitaryRegimentArmiesByIdScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for append_military_regiment_armies_by_id family tests.
List<AppendMilitaryRegimentArmiesByIdScenario>
    appendMilitaryRegimentArmiesByIdScenarios() => const [
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'create-new-army path matches with and without armiesById',
            run: amrRunCreateNewArmyPathEquivalence,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'append-existing-army path matches with and without armiesById',
            run: amrRunAppendExistingArmyPathEquivalence,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'mutates armiesById in place when appending to an existing army',
            run: amrRunMutatesArmiesByIdWhenAppending,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'mutates armiesById in place when creating a new army',
            run: amrRunMutatesArmiesByIdWhenCreating,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'multiple recruits with shared map match repeated scan-path runs',
            run: amrRunMultipleRecruitsWithSharedMap,
            refs: '#2394',
          ),
          AppendMilitaryRegimentArmiesByIdScenario(
            label: 'falls back to single-pass scan when armiesById lacks the entry',
            run: amrRunFallsBackWhenPartialMap,
            refs: '#2394',
          ),
        ];
