import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_validate_diplomatic_test_support.dart';

void main() {
  group('OrderEngine validateDiplomatic aid and subsidy rules', () {
    test('grantAid requires embassy and sufficient treasury', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.tradeConsulate,
        treasury: 5000,
      );
      final noEmbassy = OrderEngine().addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: 'minor1',
          amount: 1000,
        ),
      );
      expect(noEmbassy.status, OrderValidationStatus.rejected);
      expect(noEmbassy.reason, contains('Embassy required'));

      final gameWithEmbassy = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.embassy,
        treasury: 500,
      );
      final insufficient = OrderEngine().addDiplomaticOrderWithContext(
        gameWithEmbassy,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: 'minor1',
          amount: 1000,
        ),
      );
      expect(insufficient.status, OrderValidationStatus.rejected);
      expect(insufficient.reason, contains('Insufficient treasury'));
    });

    test('grantAid rejects amounts not a multiple of £1000', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.embassy,
        treasury: 5000,
      );
      final bad = OrderEngine().addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: 'minor1',
          amount: 1500,
        ),
      );
      expect(bad.status, OrderValidationStatus.rejected);
      expect(bad.reason, contains('multiple'));
    });

    test('grantAid then setSubsidy toward same target both accepted', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.embassy,
        treasury: 5000,
      );
      final eng = OrderEngine();
      final g = eng.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.grantAid,
          targetFactionId: 'minor1',
          amount: 1000,
        ),
      );
      expect(g.status, OrderValidationStatus.accepted);
      final s = eng.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'minor1',
          amount: 1000,
        ),
      );
      expect(s.status, OrderValidationStatus.accepted);
    });

    test('setSubsidy requires consulate or embassy and sufficient treasury', () {
      final gameNoOverture = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.none,
        treasury: 100,
      );
      final noConsulate = OrderEngine().addDiplomaticOrderWithContext(
        gameNoOverture,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'minor1',
          amount: 100,
        ),
      );
      expect(noConsulate.status, OrderValidationStatus.rejected);
      expect(noConsulate.reason, contains('Consulate or Embassy required'));

      final gameLowTreasury = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.tradeConsulate,
        treasury: 10,
      );
      final insufficient = OrderEngine().addDiplomaticOrderWithContext(
        gameLowTreasury,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'minor1',
          amount: 500,
        ),
      );
      expect(insufficient.status, OrderValidationStatus.rejected);
      expect(insufficient.reason, contains('Insufficient treasury'));
    });

    test('setSubsidy rejects amount not a multiple of 100', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.tradeConsulate,
        treasury: 5000,
      );
      final engine = OrderEngine();
      final r = engine.addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'minor1',
          amount: 150,
        ),
      );
      expect(r.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('multiple'));
    });

    test('second grantAid toward same target rejected', () {
      final game = gpMinorBaseGame(
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
    });

    test('declareWar then grantAid toward same target rejected', () {
      final game = gpMinorBaseGame(
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
    });
  });
}
