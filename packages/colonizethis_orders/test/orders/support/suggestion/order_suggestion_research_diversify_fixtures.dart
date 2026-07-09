// Shared research diversification scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const researchDiversifyPlayerId = 'gp1';
const researchDiversifyTopology = MapTopology(nodes: [], edges: []);

/// Mirror of the implementation's private bucket mapping for assertions.
String researchCategoryBucketOf(String category) {
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

Game researchDiversifyGameFor(Player player) => Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [player],
    );

/// Greedy-sorted researchable pool from an empty unlocked state.
List<TechDefinition> researchDiversifyGreedyPool() {
  final pool =
      researchableTechIds(const <String, bool>{})
          .map((id) => techCatalog[id]!)
          .toList()
        ..sort((a, b) {
          final eraCmp = a.era.compareTo(b.era);
          if (eraCmp != 0) return eraCmp;
          final costCmp = a.cost.compareTo(b.cost);
          if (costCmp != 0) return costCmp;
          return a.id.compareTo(b.id);
        });
  return pool;
}
