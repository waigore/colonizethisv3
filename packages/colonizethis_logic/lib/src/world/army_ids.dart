import 'package:colonizethis_models/colonizethis_models.dart';

/// Home army id for a Great Power player. Parallels [homeFleetIdFor] in naval.dart.
String homeArmyIdFor(String playerId) => 'army_$playerId';

/// Deterministic id for a non-home army holding regiments in one province.
String fieldArmyIdFor(String ownerId, String fullProvinceId) =>
    'army_field_${ownerId}_${fullProvinceId.replaceAll('|', '_')}';

/// Total regiment slots across Home and field armies for [playerId].
///
/// Matches the `regimentCountForPlayer` walk in `colonizethis_ai` and the
/// H8 lock-recovery bootstrap gates in the treasury / economy planners.
int regimentCountForPlayerFromArmies(Game game, String playerId) {
  var count = 0;
  for (final army in game.worldState.armies) {
    if (army.ownerId == playerId) {
      count += army.regimentUnitIds.length;
    }
  }
  return count;
}
