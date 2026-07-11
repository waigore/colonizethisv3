// Shared research diversification scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

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

Game researchDiversifyGameFor(Player player) =>
    TestFixtures.minimalGame(id: 'g1', turnNumber: 1, players: [player]);

/// Greedy-sorted researchable pool from an empty unlocked state.
List<TechDefinition> researchDiversifyGreedyPool() {
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
