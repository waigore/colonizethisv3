// Table-driven upgrade_town Minor/Tribe scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'upgrade_town_minor_tribe_run_rows.dart';

/// One row in [upgradeTownMinorTribeScenarios].
class UpgradeTownMinorTribeScenario implements RefsScenario {
  const UpgradeTownMinorTribeScenario({
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

void runUpgradeTownMinorTribeScenario(UpgradeTownMinorTribeScenario scenario) =>
    scenario.run();

/// Canonical scenarios for upgrade_town_minor_tribe family tests.
List<UpgradeTownMinorTribeScenario> upgradeTownMinorTribeScenarios() => const [
      UpgradeTownMinorTribeScenario(
        label: 'prefilter includes minor town tile when embassy and peace',
        run: utmtRunPrefilterIncludesMinorTownWhenEmbassyAndPeace,
      ),
      UpgradeTownMinorTribeScenario(
        label: 'precheck rejects upgrade_town when at war with tribe',
        run: utmtRunPrecheckRejectsUpgradeTownWhenAtWarWithTribe,
      ),
    ];
