import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Default sim_game AI. SPEC/program/sim-game-default-ai.md.
///
/// Given the current [game] state, a single [player], and the global
/// [topology], returns that player's Orders for one turn. Behaviour is
/// deliberately simple and reproducible: units move to adjacent provinces
/// using a pseudo-random but deterministic choice per unit; build/work orders
/// are currently omitted.
Orders defaultSimGameAi({
  required Game game,
  required Player player,
  required MapTopology topology,
  required int baseSeed,
}) {
  final turnNumber = game.worldState.turnState.turnNumber;
  final rng = Random(_hashSeed(baseSeed, player.id, turnNumber));

  final neighbours = _provinceNeighboursFromTopology(topology);

  final allUnits = <Unit>[
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ]
      .where((u) => u.ownerId == player.id)
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  final moveOrders = <MoveOrder>[];

  for (final unit in allUnits) {
    final adj = List<String>.from(neighbours[unit.provinceId] ?? const <String>[]);
    if (adj.isEmpty) continue;

    // Shuffle adjacent provinces deterministically for this unit.
    _shuffleWithUnitContext(adj, rng, unit.id);
    final dest = adj.first;

    moveOrders.add(
      MoveOrder(
        unitId: unit.id,
        destinationProvinceId: dest,
      ),
    );
  }

  return Orders(
    moveOrdersByPlayerId: {
      player.id: moveOrders,
    },
  );
}

/// Builds a map of province id -> neighbouring province ids using only P–P edges.
Map<String, Set<String>> _provinceNeighboursFromTopology(MapTopology topology) {
  final provinces = <String>{};
  for (final n in topology.nodes) {
    if (n.type == TopologyNodeType.province) {
      provinces.add(n.id);
    }
  }

  final neighbours = <String, Set<String>>{
    for (final id in provinces) id: <String>{},
  };

  for (final edge in topology.edges) {
    final a = edge.id1;
    final b = edge.id2;
    if (!provinces.contains(a) || !provinces.contains(b)) continue;
    neighbours[a]!.add(b);
    neighbours[b]!.add(a);
  }

  return neighbours;
}

int _hashSeed(int baseSeed, String playerId, int turnNumber) {
  // Simple mixing of baseSeed, playerId hashCode, and turn number. This is not
  // cryptographic; it just spreads values enough for deterministic RNG use.
  const int prime = 0x9E3779B1;
  var h = baseSeed ^ (turnNumber * prime);
  h ^= playerId.hashCode * prime;
  return h & 0x7fffffff;
}

void _shuffleWithUnitContext(List<String> list, Random baseRng, String unitId) {
  if (list.length <= 1) return;
  // Derive a per-unit RNG so shuffling order is stable per (player, turn, unit).
  final seed = baseRng.nextInt(0x7fffffff) ^ unitId.hashCode;
  final rng = Random(seed & 0x7fffffff);
  for (var i = list.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
}

