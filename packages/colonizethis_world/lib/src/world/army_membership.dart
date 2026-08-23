import 'package:colonizethis_models/colonizethis_models.dart';

import 'army_ids.dart';

/// Home vs field army id for a regiment stationed at [locationProvinceId].
///
/// When the owner's capital matches the location, the unit belongs to the
/// Home Army; otherwise it belongs to the field army for that province.
String armyMembershipIdFor({
  required String ownerId,
  required String locationProvinceId,
  required String? capitalProvinceId,
}) {
  if (capitalProvinceId != null && locationProvinceId == capitalProvinceId) {
    return homeArmyIdFor(ownerId);
  }
  return fieldArmyIdFor(ownerId, locationProvinceId);
}

/// True when a regiment at [locationProvinceId] belongs on the Home Army.
bool armyMembershipWantsHome({
  required String locationProvinceId,
  required String? capitalProvinceId,
}) => capitalProvinceId != null && locationProvinceId == capitalProvinceId;

/// Stationed army row used by ensure/rebuild and reconcile membership paths.
Army stationedMembershipArmy({
  required String id,
  required String ownerId,
  required String regionId,
  required String stationedProvinceId,
  required List<String> regimentUnitIds,
  required bool isHomeArmy,
}) => Army(
  id: id,
  ownerId: ownerId,
  regionId: regionId,
  stationedProvinceId: stationedProvinceId,
  regimentUnitIds: regimentUnitIds,
  isHomeArmy: isHomeArmy,
);

/// Capital province id by player id (players with no capital omitted).
Map<String, String> capitalProvinceIdByPlayer(Iterable<Player> players) => {
  for (final p in players)
    if (p.capitalProvinceId != null) p.id: p.capitalProvinceId!,
};
