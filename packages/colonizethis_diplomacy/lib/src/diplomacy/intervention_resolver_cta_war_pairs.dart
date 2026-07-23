import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'diplomacy_relation_lookup.dart';
import 'diplomacy_shared_helpers.dart';

/// GP–GP war pairs from declare-war orders that are at war after step 5.
List<({String aggressor, String defender})> gpGpWarPairsFromDeclareWarOrders(
  Game game,
  Map<String, List<DiplomaticOrder>> diploByPlayer,
  DiplomacyFactionMembership factionMembership,
) {
  final seen = <String>{};
  final out = <({String aggressor, String defender})>[];
  for (final e in diploByPlayer.entries) {
    final aggressor = e.key;
    if (!factionMembership.isGreatPower(aggressor)) continue;
    for (final o in e.value) {
      if (o.type != DiplomaticOrderType.declareWar) continue;
      final defender = o.targetFactionId;
      if (!factionMembership.isGreatPower(defender)) continue;
      if (!factionsAtWar(game, aggressor, defender)) continue;
      final key = '$aggressor|$defender';
      if (seen.add(key)) {
        out.add((aggressor: aggressor, defender: defender));
      }
    }
  }
  return out;
}
