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
          amount: 10,
        ),
      );
      expect(s.status, OrderValidationStatus.accepted);
    });

    test('setSubsidy requires an embassy (Refs #3753 R2)', () {
      // No overture at all is rejected for the embassy prerequisite. A valid
      // percent is supplied so validation reaches the embassy check.
      final gameNoOverture = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.none,
        treasury: 5000,
      );
      final noOverture = OrderEngine().addDiplomaticOrderWithContext(
        gameNoOverture,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'minor1',
          amount: 10,
        ),
      );
      expect(noOverture.status, OrderValidationStatus.rejected);
      expect(noOverture.reason, contains('Embassy required'));

      // A Trade Consulate alone is no longer sufficient for SetSubsidy.
      final gameConsulateOnly = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.tradeConsulate,
        treasury: 5000,
      );
      final consulateOnly = OrderEngine().addDiplomaticOrderWithContext(
        gameConsulateOnly,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'minor1',
          amount: 10,
        ),
      );
      expect(consulateOnly.status, OrderValidationStatus.rejected);
      expect(consulateOnly.reason, contains('Embassy required'));
    });

    test('setSubsidy with an embassy is accepted regardless of treasury '
        '(no upfront cost, Refs #3753 R3)', () {
      final gameLowTreasury = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.embassy,
        treasury: 10,
      );
      final accepted = OrderEngine().addDiplomaticOrderWithContext(
        gameLowTreasury,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'minor1',
          amount: 20,
        ),
      );
      // Percent subsidies charge nothing upfront, so even a near-empty treasury
      // is accepted.
      expect(accepted.status, OrderValidationStatus.accepted);
    });

    test('setSubsidy with an embassy and a valid percent is accepted', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.embassy,
        treasury: 5000,
      );
      final accepted = OrderEngine().addDiplomaticOrderWithContext(
        game,
        emptyTopology,
        'gp1',
        const DiplomaticOrder(
          type: DiplomaticOrderType.setSubsidy,
          targetFactionId: 'minor1',
          amount: 5,
        ),
      );
      expect(accepted.status, OrderValidationStatus.accepted);
    });

    test('setSubsidy rejects a percent outside 5-20 in steps of 5', () {
      final game = gpMinorBaseGame(
        relationState: RelationState.atPeace,
        overtureStage: OvertureStage.embassy,
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
          amount: 7,
        ),
      );
      expect(r.status, OrderValidationStatus.rejected);
      expect(r.reason, contains('steps of'));
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
