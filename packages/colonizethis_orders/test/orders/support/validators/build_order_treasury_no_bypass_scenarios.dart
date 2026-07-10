// Table-driven build-order treasury no-bypass guard scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_order_treasury_no_bypass_expectations.dart';

/// One row in [buildOrderTreasuryNoBypassScenarios].
class BuildOrderTreasuryNoBypassScenario implements RefsScenario {
  const BuildOrderTreasuryNoBypassScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final BuildOrderTreasuryNoBypassTarget target;
  @override
  final String? refs;
}

void runBuildOrderTreasuryNoBypassScenario(
  BuildOrderTreasuryNoBypassScenario scenario,
) {
  runBuildOrderTreasuryNoBypassExpectation(scenario.target);
}

/// Canonical scenarios for build-order treasury no-bypass guard.
List<BuildOrderTreasuryNoBypassScenario> buildOrderTreasuryNoBypassScenarios() =>
    const [
      BuildOrderTreasuryNoBypassScenario(
        label: 'peasant_levies is the cheapest, tech-free regiment (fixture pin)',
        target: BuildOrderTreasuryNoBypassTarget.cheapestRegimentFixturePin,
        refs: '#2924',
      ),
      BuildOrderTreasuryNoBypassScenario(
        label: 'AI player below cheapest regiment treasury is rejected (no bypass)',
        target: BuildOrderTreasuryNoBypassTarget.aiBelowTreasuryRejected,
        refs: '#2924',
      ),
      BuildOrderTreasuryNoBypassScenario(
        label: 'AI player at exactly the cheapest treasury is accepted (treasury gate is the sole blocker)',
        target: BuildOrderTreasuryNoBypassTarget.aiAtTreasuryAccepted,
        refs: '#2924',
      ),
      BuildOrderTreasuryNoBypassScenario(
        label: 'human player at zero treasury is rejected (no human waiver)',
        target: BuildOrderTreasuryNoBypassTarget.humanZeroTreasuryRejected,
        refs: '#2924',
      ),
      BuildOrderTreasuryNoBypassScenario(
        label: 'affordability gate is player-agnostic at zero treasury (human and AI both rejected)',
        target: BuildOrderTreasuryNoBypassTarget.playerAgnosticZeroTreasury,
        refs: '#2924',
      ),
    ];
