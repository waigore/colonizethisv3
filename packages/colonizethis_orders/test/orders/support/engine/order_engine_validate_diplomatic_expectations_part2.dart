part of 'order_engine_validate_diplomatic_expectations.dart';

void _secondGrantAidTowardSameTargetRejected() {
  final game = vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000);
  final engine = OrderEngine();
  vedSubmit(game, vedGrantAid(1000), engine: engine);
  final second = vedSubmit(game, vedGrantAid(1000), engine: engine);
  expect(second.status, OrderValidationStatus.rejected);
}

void _declarewarThenGrantAidTowardSameTargetRejected() {
  final game = vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000);
  final engine = OrderEngine();
  vedSubmit(game, vedDeclareWarMinor, engine: engine);
  final grant = vedSubmit(game, vedGrantAid(1000), engine: engine);
  expect(grant.status, OrderValidationStatus.rejected);
}
