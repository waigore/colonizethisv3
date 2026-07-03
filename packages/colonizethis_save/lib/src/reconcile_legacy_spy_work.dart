import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Legacy save migration: cancel in-progress `steal_tech` work (Refs #3834 R1).
/// Runs once on save load, not each turn.
Game reconcileLegacySpyWorkOrders(Game game) {
  var changed = false;

  RegionData reconcileRegion(RegionData region) {
    final nextUnits = <Unit>[];
    for (final u in region.units) {
      final cw = u.currentWork;
      if (cw?.workTarget == 'steal_tech') {
        changed = true;
        nextUnits.add(
          u.copyWith(
            currentWork: null,
            status: UnitStatus.idle,
          ),
        );
        continue;
      }
      nextUnits.add(u);
    }
    return RegionData(provinces: region.provinces, units: nextUnits);
  }

  final ws = game.worldState;
  final oldWorld = reconcileRegion(ws.oldWorld);
  final newWorld = reconcileRegion(ws.newWorld);
  if (!changed) return game;
  return game.updateWorldState(
    (w) => w.copyWith(oldWorld: oldWorld, newWorld: newWorld),
  );
}
