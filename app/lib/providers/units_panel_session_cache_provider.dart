import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/panels/tree_builders/military_tree_builder.dart';
import '../features/game/widgets/panels/tree_builders/naval_tree_builder.dart';
import 'development_panel_projection_provider.dart'
    show developmentPanelOrdersRevision, developmentPanelWorldRevision;

typedef UnitsPanelStaticSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
});

typedef UnitsPanelMilitarySessionRevision = ({
  UnitsPanelStaticSessionRevision staticRevision,
  String humanPlayerId,
});

typedef UnitsPanelNavalSessionRevision = ({
  UnitsPanelStaticSessionRevision staticRevision,
  String humanPlayerId,
  int ordersRevision,
  String? locationScopeKeyFilter,
});

typedef NavalTreeSnapshot = List<
    ({
      String regionId,
      FleetRow? homeFleet,
      List<NavalTreeLocationNode> locations,
    })>;

class UnitsPanelSessionCacheState {
  const UnitsPanelSessionCacheState({
    this.militaryRevision,
    this.militaryGroups,
    this.navalRevision,
    this.navalTree,
  });

  final UnitsPanelMilitarySessionRevision? militaryRevision;
  final List<RegionMilitaryGroup>? militaryGroups;
  final UnitsPanelNavalSessionRevision? navalRevision;
  final NavalTreeSnapshot? navalTree;
}

/// Cross-visit cache for UNIT* panel tree projections (Refs #4688 Slice 3).
class UnitsPanelSessionCache {
  UnitsPanelSessionCacheState state = const UnitsPanelSessionCacheState();

  void reset() {
    state = const UnitsPanelSessionCacheState();
  }
}

final unitsPanelSessionCacheProvider = Provider<UnitsPanelSessionCache>(
  (ref) => UnitsPanelSessionCache(),
);

UnitsPanelStaticSessionRevision unitsPanelStaticSessionRevision({
  required Game game,
}) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: developmentPanelWorldRevision(game),
  );
}

UnitsPanelMilitarySessionRevision unitsPanelMilitarySessionRevision({
  required Game game,
  required String humanPlayerId,
}) {
  return (
    staticRevision: unitsPanelStaticSessionRevision(game: game),
    humanPlayerId: humanPlayerId,
  );
}

UnitsPanelNavalSessionRevision unitsPanelNavalSessionRevision({
  required Game game,
  required String humanPlayerId,
  required Orders draftOrders,
  String? locationScopeKeyFilter,
}) {
  return (
    staticRevision: unitsPanelStaticSessionRevision(game: game),
    humanPlayerId: humanPlayerId,
    ordersRevision: developmentPanelOrdersRevision(draftOrders),
    locationScopeKeyFilter: locationScopeKeyFilter,
  );
}

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
  );
  return groups;
}

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
  );
  return tree;
}
