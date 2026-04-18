import 'package:colonizethis_data/colonizethis_data.dart' show isMilitaryUnit;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show fleetsInPortAtProvince;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../l10n/app_localizations.dart';
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
    for (final a in ws.armies) {
      if (a.id != o.armyId) continue;
      if (a.ownerId != humanPlayerId) continue;
      if (a.stationedProvinceId != provinceId) continue;
      out.add(
        l10n.province_pending_armyMove(
          _destinationProvinceLabel(game, o.destinationProvinceId),
        ),
      );
      break;
    }
  }

  final regMoves = orders.moveOrdersByPlayerId[humanPlayerId] ?? [];
  for (final o in regMoves) {
    Unit? u;
    for (final region in [ws.oldWorld, ws.newWorld]) {
      for (final c in region.units) {
        if (c.id == o.unitId) {
          u = c;
          break;
        }
      }
      if (u != null) break;
    }
    if (u == null) continue;
    if (!isMilitaryUnit(u.type)) continue;
    if (u.ownerId != humanPlayerId) continue;
    if (u.locationProvinceId != provinceId) continue;
    out.add(
      l10n.province_pending_regimentMove(
        _destinationProvinceLabel(game, o.destinationProvinceId),
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
  final fleetsHere = fleetsInPortAtProvince(ws, provinceId)
      .where((f) => f.ownerId == humanPlayerId)
      .map((f) => f.id)
      .toSet();

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
