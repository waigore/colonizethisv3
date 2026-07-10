// Scenario run tear-offs for order effects projector seam (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
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
