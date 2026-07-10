// Table-driven trade-interception scenarios (Refs #3939 phase 3).

import 'scenario_runner.dart';
import 'trade_interception_expectations.dart';

/// One row in [applyTradeInterceptionScenarios].
class ApplyTradeInterceptionScenario implements RefsScenario {
  const ApplyTradeInterceptionScenario({
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

void runApplyTradeInterceptionScenario(
  ApplyTradeInterceptionScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for [applyTradeInterception].
List<ApplyTradeInterceptionScenario> applyTradeInterceptionScenarios() => [
  applyTradeInterceptionScenario(
    label: 'returns as-is when overseasDelivered is empty',
    target: ApplyTradeInterceptionTarget.emptyOverseas,
  ),
  applyTradeInterceptionScenario(
    label: 'returns full delivered when no enemies at war',
    target: ApplyTradeInterceptionTarget.noEnemiesAtWar,
  ),
  applyTradeInterceptionScenario(
    label: 'returns full delivered when at war but no interceptor fleet',
    target: ApplyTradeInterceptionTarget.atWarNoInterceptor,
  ),
  applyTradeInterceptionScenario(
    label: 'reduces cargo when enemy has patrol fleet',
    target: ApplyTradeInterceptionTarget.enemyPatrolReduces,
  ),
  applyTradeInterceptionScenario(
    label: 'is deterministic for a fixed seed',
    target: ApplyTradeInterceptionTarget.deterministicSeed,
  ),
  applyTradeInterceptionScenario(
    label: 'enemy without privateering reduces cargo by the baseline',
    target: ApplyTradeInterceptionTarget.privateeringBaseline,
    refs: '#3470',
  ),
  applyTradeInterceptionScenario(
    label: 'enemy with privateering reduces cargo more (strictly less kept)',
    target: ApplyTradeInterceptionTarget.privateeringBoosted,
    refs: '#3470',
  ),
  applyTradeInterceptionScenario(
    label: 'privateering trade-raid result is deterministic for a fixed seed',
    target: ApplyTradeInterceptionTarget.privateeringDeterministic,
    refs: '#3470',
  ),
  applyTradeInterceptionScenario(
    label: 'can remove merchant ships when interception triggers and RNG hits',
    target: ApplyTradeInterceptionTarget.shipRemovalLoop,
  ),
];

/// One row in [tradeInterceptionScanScenarios].
class TradeInterceptionScanScenario implements RefsScenario {
  const TradeInterceptionScanScenario({
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

void runTradeInterceptionScanScenario(TradeInterceptionScanScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for [scanTradeInterceptionInputs].
List<TradeInterceptionScanScenario> tradeInterceptionScanScenarios() => [
  tradeInterceptionScanScenario(
    label: 'no enemy patrol/blockade fleets yields zero intercept score',
    target: TradeInterceptionScanTarget.noEnemyPatrol,
  ),
  tradeInterceptionScanScenario(
    label: 'player merchant ships counted; escorts feed escort strength',
    target: TradeInterceptionScanTarget.merchantEscortCount,
  ),
  tradeInterceptionScanScenario(
    label: 'enemy blockade fleet sets the blockade flag',
    target: TradeInterceptionScanTarget.enemyBlockade,
  ),
  tradeInterceptionScanScenario(
    label: 'privateering enemy scales intercept score above the baseline',
    target: TradeInterceptionScanTarget.privateeringScales,
  ),
];
