// Consolidated OrderEngine validateTrade runners (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/engine/order_engine_validate_trade_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('OrderEngine validation pass — TradeOrder (#2989 A8)', () {
    runLabeledScenarios(
      orderEngineValidateTradeScenarios(),
      runRunnableScenario,
    );
  });
}
