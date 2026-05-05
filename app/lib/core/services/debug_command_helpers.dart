import 'package:colonizethis_models/colonizethis_models.dart';

typedef DebugCommandResult = ({Game? game, String message});

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
