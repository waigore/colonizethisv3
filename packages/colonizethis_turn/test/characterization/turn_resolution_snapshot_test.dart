import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../support/turn_resolver_test_harness.dart';
import 'turn_resolution_snapshot_cases.dart';

void main() {
  group('Turn resolution characterization', () {
    test('full turn with extraction, movement, and combat is deterministic', () {
      final topology = turnSnapshotThreeProvinceTopology();
      final game = turnSnapshotExtractionMovementGame();
      final orders = turnSnapshotExtractionMovementOrders();
      final extracted = turnSnapshotExtractionByPlayer();

      final next = resolveTurnComplete(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: extracted,
      );

      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.turnState.phase, TurnPhase.orders);

      final movedUnit = next.worldState.oldWorld.units
          .where((u) => u.id == 'inf1')
          .firstOrNull;
      expect(movedUnit, isNotNull);
      expect(movedUnit!.locationProvinceId, '$turnSnapshotOw|P2');

      final p1 = next.playerById('p1')!;
      final p2 = next.playerById('p2')!;
      expect(p1.stockpile.quantityOf('grain'), lessThanOrEqualTo(13));
      expect(p2.stockpile.quantityOf('grain'), lessThanOrEqualTo(6));
    });

    test('empty orders still advance turn', () {
      final next = resolveTurnComplete(
        game: turnSnapshotEmptyTurnGame(),
        topology: turnSnapshotEmptyTurnTopology(),
        orders: const Orders(),
      );
      expect(next.worldState.turnState.turnNumber, 6);
    });

    test('resolveTurn (WorldState only) advances turn deterministically', () {
      final state = WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 10),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      );
      final next = resolveTurn(state);
      expect(next.turnState.turnNumber, 11);
      expect(next.turnState.phase, TurnPhase.orders);
    });

    test('phase sequence is correct', () {
      expect(turnResolutionSequence, [
        TurnPhase.orders,
        TurnPhase.extraction,
        TurnPhase.richesToTreasury,
        TurnPhase.consumption,
        TurnPhase.production,
        TurnPhase.diplomacy,
        TurnPhase.spyResolution,
        TurnPhase.research,
        TurnPhase.movement,
        TurnPhase.minorRegimentUpgrade,
        TurnPhase.navalInterceptionCombat,
        TurnPhase.combat,
        TurnPhase.buildWork,
        TurnPhase.worldMarket,
        TurnPhase.endOfTurn,
      ]);
    });

    test('combat phase resolves when units collide', () {
      final topology = turnSnapshotCombatTopology();
      final next = resolveTurnComplete(
        game: turnSnapshotCombatGame(),
        topology: topology,
        orders: turnSnapshotCombatOrders(),
      );

      expect(next.worldState.turnState.turnNumber, 1);
      final provinceB = next.worldState.oldWorld.provinces
          .firstWhere((p) => p.id == '$turnSnapshotOw|B');
      expect(provinceB.ownerId, 'p1');
    });
  });
}
