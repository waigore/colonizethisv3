// Table-driven build-order treasury no-bypass guard scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_order_treasury_no_bypass_run_rows.dart';

/// One row in [buildOrderTreasuryNoBypassScenarios].
class BuildOrderTreasuryNoBypassScenario implements RefsScenario {
  const BuildOrderTreasuryNoBypassScenario({
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

void runBuildOrderTreasuryNoBypassScenario(
  BuildOrderTreasuryNoBypassScenario scenario,
) =>
    scenario.run();

/// Canonical scenarios for build-order treasury no-bypass guard.
List<BuildOrderTreasuryNoBypassScenario> buildOrderTreasuryNoBypassScenarios() =>
    [
      BuildOrderTreasuryNoBypassScenario(
        label: 'peasant_levies is the cheapest, tech-free regiment (fixture pin)',
        run: botnbRunCheapestRegimentFixturePin,
        refs: '#2924',
      ),
      BuildOrderTreasuryNoBypassScenario(
        label: 'AI player below cheapest regiment treasury is rejected (no bypass)',
        run: botnbRunAiBelowTreasuryRejected,
        refs: '#2924',
      ),
      BuildOrderTreasuryNoBypassScenario(
        label: 'AI player at exactly the cheapest treasury is accepted (treasury gate is the sole blocker)',
        run: botnbRunAiAtTreasuryAccepted,
        refs: '#2924',
      ),
      BuildOrderTreasuryNoBypassScenario(
        label: 'human player at zero treasury is rejected (no human waiver)',
        run: botnbRunHumanZeroTreasuryRejected,
        refs: '#2924',
      ),
      BuildOrderTreasuryNoBypassScenario(
        label: 'affordability gate is player-agnostic at zero treasury (human and AI both rejected)',
        run: botnbRunPlayerAgnosticZeroTreasury,
        refs: '#2924',
      ),
    ];
