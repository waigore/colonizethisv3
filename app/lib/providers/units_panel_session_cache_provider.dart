import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/game/widgets/panels/tree_builders/military_tree_builder.dart';
import '../features/game/widgets/panels/tree_builders/naval_tree_builder.dart';
import '../features/game/widgets/units/civilian/civilian_units_sort.dart';
import 'panel_session_revision.dart'
    show panelOrdersRevision, panelWorldRevision;

typedef UnitsPanelStaticSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
});

typedef UnitsPanelMilitarySessionRevision = ({
  UnitsPanelStaticSessionRevision staticRevision,
  String humanPlayerId,
  int militaryContentRevision,
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

typedef UnitsPanelCivilianSessionRevision = ({
  UnitsPanelStaticSessionRevision staticRevision,
  String ownerIdsKey,
  int ordersRevision,
});

class CivilianUnitsPanelOpenPathSnapshot {
  const CivilianUnitsPanelOpenPathSnapshot({
    required this.provinceNames,
    required this.oldWorldUnits,
    required this.newWorldUnits,
  });

  final Map<String, String> provinceNames;
  final List<Unit> oldWorldUnits;
  final List<Unit> newWorldUnits;
}

class UnitsPanelSessionCacheState {
  const UnitsPanelSessionCacheState({
    this.militaryRevision,
    this.militaryGroups,
    this.navalRevision,
    this.navalTree,
    this.civilianRevision,
    this.civilianOpenPath,
  });

  final UnitsPanelMilitarySessionRevision? militaryRevision;
  final List<RegionMilitaryGroup>? militaryGroups;
  final UnitsPanelNavalSessionRevision? navalRevision;
  final NavalTreeSnapshot? navalTree;
  final UnitsPanelCivilianSessionRevision? civilianRevision;
  final CivilianUnitsPanelOpenPathSnapshot? civilianOpenPath;
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
    worldRevision: panelWorldRevision(game),
  );
}

int unitsPanelMilitaryContentRevision(Game game, String humanPlayerId) {
  final armyHashes = <int>[];
  for (final army in game.worldState.armies) {
    if (army.ownerId != humanPlayerId) continue;
    armyHashes.add(
      Object.hash(
        army.id,
        army.isHomeArmy,
        army.stationedProvinceId,
        Object.hashAll(army.regimentUnitIds),
      ),
    );
  }
  armyHashes.sort();
  return Object.hash(game.worldState.nextArmySeq, Object.hashAll(armyHashes));
}

UnitsPanelMilitarySessionRevision unitsPanelMilitarySessionRevision({
  required Game game,
  required String humanPlayerId,
}) {
  return (
    staticRevision: unitsPanelStaticSessionRevision(game: game),
    humanPlayerId: humanPlayerId,
    militaryContentRevision: unitsPanelMilitaryContentRevision(
      game,
      humanPlayerId,
    ),
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
    ordersRevision: panelOrdersRevision(draftOrders),
    locationScopeKeyFilter: locationScopeKeyFilter,
  );
}

String unitsPanelOwnerIdsCacheKey(Set<String> ownerIds) {
  final sorted = ownerIds.toList()..sort();
  return sorted.join('|');
}

UnitsPanelCivilianSessionRevision unitsPanelCivilianSessionRevision({
  required Game game,
  required Set<String> ownerIds,
  required Orders currentOrders,
}) {
  return (
    staticRevision: unitsPanelStaticSessionRevision(game: game),
    ownerIdsKey: unitsPanelOwnerIdsCacheKey(ownerIds),
    ordersRevision: panelOrdersRevision(currentOrders),
  );
}

/// True for empire-rail `UNIT10001` opens without tile/role shortcut filters.
bool civilianUnitsPanelSessionCacheEligible({
  String? tileScopeTileKey,
  bool explorerOnly = false,
  bool builderOnly = false,
  bool engineerOnly = false,
  bool railBuilderOnly = false,
  bool merchantOnly = false,
  bool spyOnly = false,
}) {
  final tileScopeActive =
      tileScopeTileKey != null && tileScopeTileKey.isNotEmpty;
  return !tileScopeActive &&
      !explorerOnly &&
      !builderOnly &&
      !engineerOnly &&
      !railBuilderOnly &&
      !merchantOnly &&
      !spyOnly;
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
    civilianRevision: cache.state.civilianRevision,
    civilianOpenPath: cache.state.civilianOpenPath,
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
    civilianRevision: cache.state.civilianRevision,
    civilianOpenPath: cache.state.civilianOpenPath,
  );
  return tree;
}

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
