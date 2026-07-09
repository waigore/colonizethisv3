part of 'order_engine_validate_diplomatic_expectations.dart';


void _secondGrantAidTowardSameTargetRejected() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final engine = OrderEngine();
  engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  final second = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  expect(second.status, OrderValidationStatus.rejected);
}

void _declarewarThenGrantAidTowardSameTargetRejected() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final engine = OrderEngine();
  engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: 'minor1',
    ),
  );
  final g = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  expect(g.status, OrderValidationStatus.rejected);
}
