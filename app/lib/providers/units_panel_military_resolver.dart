import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../features/game/widgets/panels/tree_builders/military_tree_builder.dart';
import 'units_panel_session_cache.dart';

List<RegionMilitaryGroup> resolveUnitsPanelMilitaryGroups({
  required UnitsPanelSessionCache cache,
  required Game game,
  required String humanPlayerId,
}) {
  final revision = unitsPanelMilitarySessionRevision(
    game: game,
    humanPlayerId: humanPlayerId,
  );
  if (cache.state.militaryRevision == revision &&
      cache.state.militaryGroups != null) {
    return cache.state.militaryGroups!;
  }
  final groups = ctAppPerfSync(
    'militaryUnits.treeBuild',
    () => buildMilitaryGroups(game, humanPlayerId),
  );
  cache.state = UnitsPanelSessionCacheState(
    militaryRevision: revision,
    militaryGroups: groups,
    navalRevision: cache.state.navalRevision,
    navalTree: cache.state.navalTree,
    civilianRevision: cache.state.civilianRevision,
    civilianOpenPath: cache.state.civilianOpenPath,
  );
  return groups;
}
