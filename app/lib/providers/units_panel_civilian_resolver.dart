import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'units_panel_session_cache.dart';

CivilianUnitsPanelOpenPathSnapshot resolveCivilianUnitsPanelOpenPath({
  required UnitsPanelSessionCache cache,
  required Game game,
  required Set<String> ownerIds,
  required Orders currentOrders,
  required bool useSessionCache,
}) {
  final revision = unitsPanelCivilianSessionRevision(
    game: game,
    ownerIds: ownerIds,
    currentOrders: currentOrders,
  );
  if (useSessionCache &&
      cache.state.civilianRevision == revision &&
      cache.state.civilianOpenPath != null) {
    return cache.state.civilianOpenPath!;
  }

  final provinceNames = ctAppPerfSync(
    'civilianUnits.provinceNames',
    () => provinceNamesByPrefixedId(game),
  );
  final oldWorldUnits = ctAppPerfSync(
    'civilianUnits.oldWorldList',
    () => civilianUnitsInRegionForOwners(
      game.worldState.oldWorld.units,
      ownerIds,
      provinceNames,
      currentOrders,
    ),
  );
  final newWorldUnits = ctAppPerfSync(
    'civilianUnits.newWorldList',
    () => civilianUnitsInRegionForOwners(
      game.worldState.newWorld.units,
      ownerIds,
      provinceNames,
      currentOrders,
    ),
  );
  final snapshot = CivilianUnitsPanelOpenPathSnapshot(
    provinceNames: provinceNames,
    oldWorldUnits: oldWorldUnits,
    newWorldUnits: newWorldUnits,
  );
  if (useSessionCache) {
    cache.state = UnitsPanelSessionCacheState(
      militaryRevision: cache.state.militaryRevision,
      militaryGroups: cache.state.militaryGroups,
      navalRevision: cache.state.navalRevision,
      navalTree: cache.state.navalTree,
      civilianRevision: revision,
      civilianOpenPath: snapshot,
    );
  }
  return snapshot;
}
