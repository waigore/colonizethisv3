import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../features/game/widgets/panels/tree_builders/naval_tree_builder.dart';
import 'units_panel_session_cache.dart';

NavalTreeSnapshot resolveUnitsPanelNavalTree({
  required UnitsPanelSessionCache cache,
  required Game game,
  required String humanPlayerId,
  required MapTopology topology,
  required Orders draftOrders,
  required AppLocalizations l10n,
  Map<String, TileMapResult>? tileMapByRegion,
  Map<String, MapTopology>? topologyByRegion,
  String? locationScopeKeyFilter,
}) {
  final revision = unitsPanelNavalSessionRevision(
    game: game,
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    locationScopeKeyFilter: locationScopeKeyFilter,
  );
  if (cache.state.navalRevision == revision && cache.state.navalTree != null) {
    return cache.state.navalTree!;
  }
  final tree = ctAppPerfSync(
    'navalUnits.treeBuild',
    () => buildNavalTree(
      game,
      humanPlayerId,
      topology,
      draftOrders,
      l10n,
      tileMapByRegion: tileMapByRegion,
      topologyByRegion: topologyByRegion,
      locationScopeKeyFilter: locationScopeKeyFilter,
    ),
  );
  cache.state = UnitsPanelSessionCacheState(
    militaryRevision: cache.state.militaryRevision,
    militaryGroups: cache.state.militaryGroups,
    navalRevision: revision,
    navalTree: tree,
    civilianRevision: cache.state.civilianRevision,
    civilianOpenPath: cache.state.civilianOpenPath,
  );
  return tree;
}
