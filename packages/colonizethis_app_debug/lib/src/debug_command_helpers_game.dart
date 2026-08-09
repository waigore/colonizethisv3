import 'package:colonizethis_logic/colonizethis_logic.dart' show kRegionNewWorld;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Returns a copy of [game] with the player matching [playerId] replaced by
/// `mutate(player)`. Non-matching players are preserved in order.
Game updateDebugPlayer(
  Game game,
  String playerId,
  Player Function(Player player) mutate,
) {
  final updatedPlayers = game.players
      .map((p) => p.id == playerId ? mutate(p) : p)
      .toList(growable: false);
  return game.copyWith(players: updatedPlayers);
}

/// Appends [units] to the region-appropriate unit bucket (old/new world) of
/// [world], returning the updated [WorldState]. Used by spawn handlers to place
/// units in the correct region without duplicating the split-and-add idiom.
WorldState appendUnitsToRegion(
  WorldState world,
  String regionId,
  List<Unit> units,
) {
  final oldUnits = List<Unit>.from(world.oldWorld.units);
  final newUnits = List<Unit>.from(world.newWorld.units);
  if (regionId == kRegionNewWorld) {
    newUnits.addAll(units);
  } else {
    oldUnits.addAll(units);
  }
  return world.copyWith(
    oldWorld: RegionData(provinces: world.oldWorld.provinces, units: oldUnits),
    newWorld: RegionData(provinces: world.newWorld.provinces, units: newUnits),
  );
}

Player? findPlayerById(Game game, String playerId) {
  for (final candidate in game.players) {
    if (candidate.id == playerId) {
      return candidate;
    }
  }
  return null;
}

int nextCanonicalUnitSequence({required List<Unit> units}) {
  const prefix = 'unit_';
  var maxSeen = 0;
  for (final unit in units) {
    if (!unit.id.startsWith(prefix)) {
      continue;
    }
    final suffix = unit.id.substring(prefix.length);
    final seq = int.tryParse(suffix);
    if (seq != null && seq > maxSeen) {
      maxSeen = seq;
    }
  }
  return maxSeen + 1;
}

String mintCanonicalUnitId({
  required Set<String> usedUnitIds,
  required int nextSequence,
}) {
  var sequence = nextSequence;
  while (usedUnitIds.contains('unit_$sequence')) {
    sequence++;
  }
  final id = 'unit_$sequence';
  usedUnitIds.add(id);
  return id;
}
