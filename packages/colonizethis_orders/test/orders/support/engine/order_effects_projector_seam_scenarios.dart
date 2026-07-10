// Table-driven order-effects projector seam scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';
import 'order_effects_projector_seam_fixtures.dart';

void oepsRunUsesInjectedProjectorOutput() {
  oepsResetFakeProjectorInvocations();
  final game = oepsGameWithPlayer(oepsBasicPlayer());
  final engine = oepsEngineWithFakeProjector();
  final effects = engine.projectedEffects(game, oepsTopology, 'p1');
  expect(oepsFakeProjectorInvocations, 1);
  expect(effects.workerCount, 99);
  expect(effects.treasuryDelta, -42);
}

void oepsRunThrowsWhenNoProjectorInjected() {
  oepsResetFakeProjectorInvocations();
  final game = oepsGameWithPlayer(oepsBasicPlayer());
  final engine = oepsEngineWithoutProjector();
  expect(
    () => engine.projectedEffects(game, oepsTopology, 'p1'),
    throwsA(isA<StateError>()),
  );
}

void oepsRunThrowsWhenTradeOrderValidatedWithoutProjector() {
  oepsResetFakeProjectorInvocations();
  final game = oepsGameWithPlayer(oepsGpWithTimberStockpile());
  final engine = oepsEngineWithoutProjector()
    ..addTradeOrder('gp1', validatorOffer(CommodityCatalog.timber.id, 5));
  expect(
    () => engine.validatePlayerOrdersWithContext(game, oepsTopology, 'gp1'),
    throwsA(isA<StateError>()),
  );
}

void oepsRunUsesInjectedProjectorAndAcceptsValidOffer() {
  oepsResetFakeProjectorInvocations();
  final game = oepsGameWithPlayer(oepsGpWithTimberStockpile());
  final engine = oepsEngineWithFakeProjector()
    ..addTradeOrder('gp1', validatorOffer(CommodityCatalog.timber.id, 5));
  final results = engine.validatePlayerOrdersWithContext(
    game,
    oepsTopology,
    'gp1',
  );
  expect(oepsFakeProjectorInvocations, 1);
  expect(results, hasLength(1));
  expect(results.single.isAccepted, isTrue);
}

void oepsRunDoesNotInvokeProjectorWhenNoTradeOrderStaged() {
  oepsResetFakeProjectorInvocations();
  final game = oepsGameWithPlayer(oepsBasicPlayer());
  final engine = oepsEngineWithoutProjector()
    ..addMoveOrder(
      'p1',
      const MoveOrder(unitId: 'u1', destinationTileKey: '$oepsRegionId|P1|0|0'),
    );
  expect(
    () => engine.validatePlayerOrdersWithContext(game, oepsTopology, 'p1'),
    returnsNormally,
  );
}

/// Canonical scenarios for order_effects_projector_seam family tests.
List<RunnableScenario> orderEffectsProjectorSeamScenarios() => const [
  rs('uses the injected projector output', oepsRunUsesInjectedProjectorOutput, '#3290 C2'),
  rs('throws StateError when no projector was injected', oepsRunThrowsWhenNoProjectorInjected, '#3290 C2'),
  rs('throws StateError when a trade order is validated without a projector', oepsRunThrowsWhenTradeOrderValidatedWithoutProjector, '#3290 C2'),
  rs('uses the injected projector and accepts a valid offer', oepsRunUsesInjectedProjectorAndAcceptsValidOffer, '#3290 C2'),
  rs('does not invoke the projector when no trade order is staged', oepsRunDoesNotInvokeProjectorWhenNoTradeOrderStaged, '#3290 C2'),
];
