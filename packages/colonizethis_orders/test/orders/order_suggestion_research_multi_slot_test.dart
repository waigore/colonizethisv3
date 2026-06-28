import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Multi-slot research suggestion behavior for the Full-AI research planner
/// (Refs #3472). The suggestion layer is funding-agnostic: it enumerates
/// assignable slots, preserves in-progress research, and fills remaining slots
/// with distinct researchable techs. Funding is left as a placeholder for the
/// planner. SPEC/program/order-suggestions.md § Research orders.
void main() {
  group('suggestResearchOrders multi-slot', () {
    Game gameFor(Player player) => Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [player],
    );

    const topology = MapTopology(nodes: [], edges: []);

    test('fills every empty slot with a distinct researchable tech', () {
      const playerId = 'gp1';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 1000,
        researchSlots: 3,
      );
      final game = gameFor(player);
      final view = buildPlayerView(game, topology, playerId);

      final suggestions = suggestResearchOrders(
        view,
        game,
        topology,
        const Orders(),
      );

      expect(
        suggestions.length,
        greaterThanOrEqualTo(2),
        reason: 'multiple era-1 techs are researchable from an empty state',
      );
      expect(
        suggestions.length,
        lessThanOrEqualTo(3),
        reason: 'never exceeds the player research slot count',
      );

      final slotIndices = suggestions.map((o) => o.slotIndex).toSet();
      expect(
        slotIndices.length,
        suggestions.length,
        reason: 'each suggestion targets a distinct slot',
      );
      for (final slot in slotIndices) {
        expect(slot, inInclusiveRange(0, 2));
      }

      final techIds = suggestions.map((o) => o.techId).toSet();
      expect(
        techIds.length,
        suggestions.length,
        reason: 'each suggestion targets a distinct tech',
      );
    });

    test('re-emits in-progress research so the resolver preserves progress', () {
      const playerId = 'gp1';
      // Pick a real researchable tech and mark it in-progress (not unlocked).
      final researchable = researchableTechIds(const <String, bool>{}).toList()
        ..sort();
      expect(researchable, isNotEmpty);
      final inProgressTechId = researchable.first;

      final player = Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 1000,
        researchSlots: 3,
        researchProgressByTechId: {inProgressTechId: 25},
      );
      final game = gameFor(player);
      final view = buildPlayerView(game, topology, playerId);

      final suggestions = suggestResearchOrders(
        view,
        game,
        topology,
        const Orders(),
      );

      expect(
        suggestions.map((o) => o.techId),
        contains(inProgressTechId),
        reason: 'in-progress techs must be re-emitted to keep their progress',
      );
    });

    test('returns no suggestions when there are zero research slots', () {
      const playerId = 'gp1';
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 1000,
        researchSlots: 0,
      );
      final game = gameFor(player);
      final view = buildPlayerView(game, topology, playerId);

      final suggestions = suggestResearchOrders(
        view,
        game,
        topology,
        const Orders(),
      );

      expect(suggestions, isEmpty);
    });

    test('does not re-suggest a tech already assigned by a pending order', () {
      const playerId = 'gp1';
      final researchable = researchableTechIds(const <String, bool>{}).toList()
        ..sort();
      expect(researchable.length, greaterThanOrEqualTo(2));
      final pendingTechId = researchable.first;

      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 1000,
        researchSlots: 3,
      );
      final game = gameFor(player);
      final view = buildPlayerView(game, topology, playerId);

      final pending = Orders(
        researchOrdersByPlayerId: {
          playerId: [
            ResearchOrder(
              slotIndex: 0,
              techId: pendingTechId,
              funding: ResearchFundingLevel.medium,
            ),
          ],
        },
      );

      final suggestions = suggestResearchOrders(view, game, topology, pending);

      expect(
        suggestions.map((o) => o.techId),
        isNot(contains(pendingTechId)),
        reason: 'a tech already taken by a pending order is not re-suggested',
      );
      expect(
        suggestions.map((o) => o.slotIndex),
        isNot(contains(0)),
        reason: 'slot 0 is already taken by the pending order',
      );
    });
  });
}
