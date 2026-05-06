import 'package:colonizethis_logic/colonizethis_logic.dart'
    show fleetsInPortAtProvince;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../l10n/l10n.dart';
import 'province_panel_labels.dart';

Province? _provinceById(Game game, String provinceId) {
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.id == provinceId) return p;
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.id == provinceId) return p;
  }
  return null;
}

String _destinationProvinceLabel(Game game, String provinceId) =>
    _provinceById(game, provinceId)?.displayName ?? provinceId;

Army? _findOwnedArmyInProvinceForOrder({
  required WorldState worldState,
  required ArmyMoveOrder order,
  required String ownerId,
  required String provinceId,
}) {
  for (final army in worldState.armies) {
    if (army.id != order.armyId) {
      continue;
    }
    if (army.ownerId != ownerId) {
      return null;
    }
    return army.stationedProvinceId == provinceId ? army : null;
  }
  return null;
}

Unit? _findUnitForMoveOrder(WorldState worldState, MoveOrder order) {
  for (final region in [worldState.oldWorld, worldState.newWorld]) {
    for (final unit in region.units) {
      if (unit.id == order.unitId) {
        return unit;
      }
    }
  }
  return null;
}

/// Pending land military orders for [humanPlayerId] affecting units/armies in [provinceId].
List<String> provincePanelPendingMilitaryLines({
  required Game game,
  required Orders orders,
  required String provinceId,
  required String humanPlayerId,
  required AppLocalizations l10n,
}) {
  final out = <String>[];
  final ws = game.worldState;

  final armyMoves = orders.armyMoveOrdersByPlayerId[humanPlayerId] ?? [];
  for (final o in armyMoves) {
    final army = _findOwnedArmyInProvinceForOrder(
      worldState: ws,
      order: o,
      ownerId: humanPlayerId,
      provinceId: provinceId,
    );
    if (army == null) {
      continue;
    }
    out.add(
      l10n.province_pending_armyMove(
        _destinationProvinceLabel(game, o.destinationProvinceId),
      ),
    );
  }

  final regMoves = orders.moveOrdersByPlayerId[humanPlayerId] ?? [];
  for (final o in regMoves) {
    final u = _findUnitForMoveOrder(ws, o);
    if (u == null) continue;
    if (u.ownerId != humanPlayerId) continue;
    if (u.locationProvinceId != provinceId) continue;
    final destProv = Unit.provinceIdFromTileKey(o.destinationTileKey);
    if (destProv == null) continue;
    out.add(
      l10n.province_pending_regimentMove(
        _destinationProvinceLabel(game, destProv),
      ),
    );
  }

  return out;
}

/// Pending naval move/mission orders for [humanPlayerId] for fleets in port at [provinceId].
List<String> provincePanelPendingNavalLines({
  required Game game,
  required Orders orders,
  required String provinceId,
  required String humanPlayerId,
  required AppLocalizations l10n,
}) {
  final out = <String>[];
  final ws = game.worldState;
  final fleetsHere = fleetsInPortAtProvince(
    ws,
    provinceId,
  ).where((f) => f.ownerId == humanPlayerId).map((f) => f.id).toSet();

  final navalMoves = orders.navalMoveOrdersByPlayerId[humanPlayerId] ?? [];
  for (final o in navalMoves) {
    if (!fleetsHere.contains(o.fleetId)) continue;
    if (o.isDock) {
      final pid = o.destinationPortProvinceId!;
      out.add(
        l10n.province_pending_fleetMovePort(
          _destinationProvinceLabel(game, pid),
        ),
      );
    } else {
      final z = o.destinationSeaZoneId!;
      final zLabel = ws.seaZoneDisplayNameById[z] ?? z;
      out.add(l10n.province_pending_fleetMoveSea(zLabel));
    }
  }

  final navalMissions =
      orders.navalMissionOrdersByPlayerId[humanPlayerId] ?? [];
  for (final o in navalMissions) {
    if (!fleetsHere.contains(o.fleetId)) continue;
    if (o.mission == 'none') continue;
    final mLabel = navalMissionDisplayLabel(l10n, o.mission);
    out.add(l10n.province_pending_fleetMission(mLabel));
  }

  return out;
}
