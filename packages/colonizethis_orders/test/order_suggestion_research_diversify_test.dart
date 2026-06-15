import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Full-AI category diversification for `suggestResearchOrders` (Refs #3472).
/// Free slot 0 stays greedy-cheapest; free slots >= 1 prefer the highest-weight
/// AI bucket not represented by lower slots. The default (`categoryDiversify
/// Weight == 0`) preserves pure greedy selection for human / simple-AI callers.
/// SPEC/program/order-suggestions.md § Research orders.
void main() {
  const playerId = 'gp1';
  const topology = MapTopology(nodes: [], edges: []);

  // Mirror of the implementation's private bucket mapping for assertions.
  String bucketOf(String category) {
    switch (category) {
      case 'naval':
      case 'transport':
        return 'naval';
      case 'military':
        return 'military';
      case 'gathering':
      case 'labour':
        return 'economic';
      default:
        return 'exploration';
    }
  }

  Game gameFor(Player player) => Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
  );

  // Greedy-sorted researchable pool from an empty unlocked state.
  List<TechDefinition> greedyPool() {
    final pool =
        researchableTechIds(
          const <String, bool>{},
        ).map((id) => techCatalog[id]!).toList()..sort((a, b) {
          final eraCmp = a.era.compareTo(b.era);
          if (eraCmp != 0) return eraCmp;
          final costCmp = a.cost.compareTo(b.cost);
          if (costCmp != 0) return costCmp;
          return a.id.compareTo(b.id);
        });
    return pool;
  }

  group('suggestResearchOrders category diversification', () {
    test('slot 1 takes the highest-weight unrepresented bucket (AC9)', () {
      final pool = greedyPool();
      final slot0Bucket = bucketOf(pool.first.category);

      // Choose a target bucket present in the remaining pool that differs from
      // slot 0's bucket; weight it strictly highest so it wins selection.
      final altTech = pool
          .skip(1)
          .firstWhere(
            (t) => bucketOf(t.category) != slot0Bucket,
            orElse: () => pool.first,
          );
      final targetBucket = bucketOf(altTech.category);
      expect(
        targetBucket,
        isNot(slot0Bucket),
        reason: 'fixture needs at least two distinct buckets in the era-1 pool',
      );

      final weights = {
        'naval': 10,
        'military': 10,
        'economic': 10,
        'exploration': 10,
      };
      weights[targetBucket] = 100;

      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 1000,
        researchSlots: 2,
      );
      final game = gameFor(player);
      final view = buildPlayerView(game, topology, playerId);

      final suggestions = suggestResearchOrders(
        view,
        game,
        topology,
        const Orders(),
        researchNavalWeight: weights['naval']!,
        researchMilitaryWeight: weights['military']!,
        researchEconomicWeight: weights['economic']!,
        researchExplorationWeight: weights['exploration']!,
        researchSeed: 7,
        categoryDiversifyWeight: 100,
      );

      expect(suggestions.length, 2, reason: 'two empty slots filled');
      final slot1 = suggestions.firstWhere((o) => o.slotIndex == 1);
      expect(
        bucketOf(techCatalog[slot1.techId]!.category),
        targetBucket,
        reason:
            'slot 1 diversifies into the highest-weight unrepresented bucket',
      );

      final slot0 = suggestions.firstWhere((o) => o.slotIndex == 0);
      expect(
        slot0.techId,
        pool.first.id,
        reason: 'slot 0 keeps the greedy-cheapest pick',
      );
    });

    test('weight 0 is identical to the greedy default (negative control)', () {
      final player = const Player(
        id: playerId,
        displayName: 'GP',
        isHuman: false,
        treasury: 1000,
        researchSlots: 3,
      );
      final game = gameFor(player);
      final view = buildPlayerView(game, topology, playerId);

      final greedy = suggestResearchOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final diversifyOff = suggestResearchOrders(
        view,
        game,
        topology,
        const Orders(),
        researchNavalWeight: 100,
        researchMilitaryWeight: 90,
        researchEconomicWeight: 80,
        researchExplorationWeight: 70,
        researchSeed: 5,
        categoryDiversifyWeight: 0,
      );

      expect(
        diversifyOff.map((o) => '${o.slotIndex}:${o.techId}').toList(),
        greedy.map((o) => '${o.slotIndex}:${o.techId}').toList(),
        reason: 'zero diversify weight disables diversification (pure greedy)',
      );
    });
  });
}
