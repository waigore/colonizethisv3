import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'army_lookup.dart';
import 'army_membership.dart';
import 'army_migration_region.dart';
import 'unit_lookup.dart';

/// Removes dead unit ids from armies, drops empty non-home armies, assigns
/// orphan regiments.
WorldState reconcileArmiesAfterUnitsChanged(WorldState worldState, Game game) {
  final units = worldState.allUnitsById.values;
  final unitIds = <String>{for (final u in units) u.id};
  var armies = worldState.armies
      .map(
        (a) => a.copyWith(
          regimentUnitIds: a.regimentUnitIds
              .where(unitIds.contains)
              .toList(growable: false),
        ),
      )
      .where((a) => a.isHomeArmy || a.regimentUnitIds.isNotEmpty)
      .toList();

  final claimed = <String>{for (final a in armies) ...a.regimentUnitIds};
  final capitals = capitalProvinceIdByPlayer(game.players);

  for (final u in units) {
    if (!isMilitaryUnit(u.type) || claimed.contains(u.id)) continue;
    final cap = capitals[u.ownerId];
    final wantsHome = armyMembershipWantsHome(
      locationProvinceId: u.locationProvinceId,
      capitalProvinceId: cap,
    );
    final targetId = armyMembershipIdFor(
      ownerId: u.ownerId,
      locationProvinceId: u.locationProvinceId,
      capitalProvinceId: cap,
    );
    var target = firstArmyById(armies, targetId);
    if (target == null) {
      target = stationedMembershipArmy(
        id: targetId,
        ownerId: u.ownerId,
        regionId: regionIdForUnitInWorld(worldState, u),
        stationedProvinceId: u.locationProvinceId,
        regimentUnitIds: const [],
        isHomeArmy: wantsHome,
      );
      armies = [...armies, target];
    }
    final updated = target.copyWith(
      regimentUnitIds: [...target.regimentUnitIds, u.id],
    );
    armies = armies.map((a) => a.id == target!.id ? updated : a).toList();
    claimed.add(u.id);
  }

  armies.sort((a, b) => a.id.compareTo(b.id));
  return worldState.copyWith(armies: armies);
}
