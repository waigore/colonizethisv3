// Table-driven OrderEngine validator-injection scenarios (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_engine_validator_injection_fixtures.dart';

void oeviRunFactoryAllowsInjectedValidators() {
  final game = oeviMinimalSinglePlayerGame();
  final topology = oeviEmptyTopology();
  final engine = oeviEngineWithInjectedMoveValidator();
  final results = engine.validatePlayerOrdersWithContext(game, topology, 'p1');
  expect(results, hasLength(1));
  expect(results.single.isAccepted, isFalse);
  expect(results.single.reason, 'Injected move validator rejection');
}

void oeviRunValidateBuildsSixValidatorBundles() {
  var factoryCalls = 0;
  final game = oeviDefaultGame();
  final topology = oeviEmptyTopology();
  final engine = oeviEngineWithCountingFactory(() => factoryCalls++);
  engine.validatePlayerOrdersWithContext(game, topology, 'h1');
  expect(factoryCalls, 6);
}

/// Canonical scenarios for order_engine_validator_injection family tests.
List<RunnableScenario> orderEngineValidatorInjectionScenarios() => const [
  RunnableScenario(
    label: 'OrderEngine validator factory allows injected validators',
    run: oeviRunFactoryAllowsInjectedValidators,
  ),
  RunnableScenario(
    label:
        'validatePlayerOrdersWithContext builds six validator bundles (shared move+army, then fresh per later category; #2391 AC7, #2692 S4)',
    run: oeviRunValidateBuildsSixValidatorBundles,
    refs: '#2391 AC7',
  ),
];
