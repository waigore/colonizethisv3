/// Read-only diplomacy relation lookups for world-domain consumers (Refs #3290 Phase 0).
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/utils/expando_index.dart';

/// Normalizes faction pair for lookup (consistent ordering).
String pairKey(String a, String b) => a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';

/// Lazily built per [Game] instance (issue #2268 AC-4). A new [Game] from
/// [Game.copyWith] does not share expando state with the previous instance.
/// Routed through the shared [ExpandoIndex] utility (Refs #2836 AC 2).
final ExpandoIndex<Game, Map<String, DiplomacyRelation>>
_gameDiplomacyRelationsByPairKeyIndex =
    ExpandoIndex<Game, Map<String, DiplomacyRelation>>(
      'gameDiplomacyRelationsByPairKey',
      (game) {
        final map = <String, DiplomacyRelation>{};
        for (final r in game.diplomacyRelations) {
          map.putIfAbsent(pairKey(r.factionId1, r.factionId2), () => r);
        }
        return map;
      },
    );

Map<String, DiplomacyRelation> _diplomacyRelationsByPairKey(Game game) =>
    _gameDiplomacyRelationsByPairKeyIndex.get(game);

/// Returns relation for faction pair, or null if not found.
DiplomacyRelation? getRelation(
  Game game,
  String factionId1,
  String factionId2,
) {
  final key = pairKey(factionId1, factionId2);
  return _diplomacyRelationsByPairKey(game)[key];
}

/// True when [a] and [b] are at war according to [game.diplomacyRelations].
bool factionsAtWar(Game game, String a, String b) {
  final rel = getRelation(game, a, b);
  return rel?.atWar ?? false;
}

/// Undirected adjacency: for each faction id, the set of faction ids at war
/// with it (from [game.diplomacyRelations], using [DiplomacyRelation.atWar]).
///
/// Used by naval visibility, naval combat conflict detection, and sea trade
/// interception. Issue #2178 Phase A; keep in sync with [factionsAtWar].
Map<String, Set<String>> hostileFactionsByFaction(Game game) {
  final out = <String, Set<String>>{};
  for (final rel in game.diplomacyRelations) {
    if (!rel.atWar) continue;
    out.putIfAbsent(rel.factionId1, () => <String>{}).add(rel.factionId2);
    out.putIfAbsent(rel.factionId2, () => <String>{}).add(rel.factionId1);
  }
  return out;
}

/// Faction ids currently at war with [playerId] (empty if none or unknown).
Set<String> enemiesOf(Game game, String playerId) =>
    hostileFactionsByFaction(game)[playerId] ?? const <String>{};
