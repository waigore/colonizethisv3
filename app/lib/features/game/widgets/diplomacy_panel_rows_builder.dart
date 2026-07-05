/// Row-builder pipeline for diplomacy panel faction lists.

part of 'diplomacy_panel_rows.dart';

int? _outgoingSubsidyPercent(Game game, String payerId, String targetId) {
  for (final s in game.subsidyStates) {
    if (s.payerId == payerId && s.targetId == targetId) {
      return s.percent;
    }
  }
  return null;
}

void _appendDiscoveredFactionId(
  Game game,
  String humanPlayerId,
  String id,
  List<String> gpIds,
  List<String> minorIds,
  List<String> tribeIds,
) {
  if (id == humanPlayerId) {
    return;
  }
  if (game.players.any((p) => p.id == id)) {
    gpIds.add(id);
    return;
  }
  if (game.minorNations.any((m) => m.id == id)) {
    minorIds.add(id);
    return;
  }
  if (game.tribes.any((t) => t.id == id)) {
    tribeIds.add(id);
  }
}

({int? grant, int? subsidy}) _pendingEconomicAmounts(
  List<DiplomaticOrder> list,
  String targetId,
) {
  int? grant;
  int? subsidy;
  for (final o in list) {
    if (o.targetFactionId != targetId) continue;
    if (o.type == DiplomaticOrderType.grantAid) {
      grant = o.amount;
    }
    if (o.type == DiplomaticOrderType.setSubsidy) {
      subsidy = o.amount;
    }
  }
  return (grant: grant, subsidy: subsidy);
}

/// Default neutral first-contact standing surfaced for a discovered faction
/// that has no persisted [DiplomacyRelation] yet. SPEC/ui/diplomacy-panel.md
/// § Discovered factions → First-contact standing: `AT_PEACE`, score `50`,
/// level `Neutral` (the same default used for game-start Minor relations).
/// The `DiplomacyRelation` constructor already defaults to these values; the
/// turn fields are pinned to the current turn so history-derived UI stays
/// deterministic.
DiplomacyRelation _defaultFirstContactRelation(
  String humanPlayerId,
  String factionId,
  int currentTurn,
) => DiplomacyRelation(
  factionId1: humanPlayerId,
  factionId2: factionId,
  sinceTurn: currentTurn,
  lastInteractionTurn: currentTurn,
);

/// Builds list of discovered factions and their available actions.
///
/// Discovery follows `knownDiplomaticTargetFactionIds`
/// (SPEC/ui/diplomacy-panel.md § Discovered factions) for Great Powers and
/// Minor Nations: an existing [DiplomacyRelation] or non-`unknown` tile
/// visibility into a faction-owned province. A discovered faction without a
/// persisted relation is surfaced with the default neutral first-contact
/// standing.
///
/// **Tribes require first contact (Refs #3620):** a Tribe is surfaced only
/// after first contact — a persisted GP↔Tribe relation **or** non-`unknown`
/// tile visibility into a province that Tribe owns
/// ([discoveredTribeIdsForFirstContact]). Sea-reachable colonial intel alone
/// no longer surfaces a Tribe row (SPEC/ui/diplomacy-panel.md § Tribes require
/// first contact).
List<DiplomacyRowData> buildDiplomacyRows(
  Game game,
  MapTopology topology,
  String humanPlayerId,
  Orders currentOrders,
) {
  final view = buildPlayerView(game, topology, humanPlayerId);
  // Built once per render pass so the per-tile attribution scan that backs the
  // overseas-holdings standing chip (Refs #3753 R12 / R8) is not repeated per
  // row. SPEC/ui/diplomacy-panel.md § Diplomatic standing chip cluster.
  final purchasedTiles = PurchasedTileIndex.fromGame(game);
  final discoveredIds = <String>{
    ...view.diplomacyByOtherId.keys,
    ...knownDiplomaticTargetFactionIds(
      view: view,
      game: game,
      topology: topology,
    ),
  };
  // First-contact gate for Tribes (Refs #3620): drop tribe ids that are only
  // sea-reachable colonial intel (present in `knownDiplomaticTargetFactionIds`
  // without a persisted relation or tile visibility). A tribe is contacted iff
  // a GP↔Tribe relation is persisted or the GP holds non-`unknown` tile
  // visibility into a province it owns.
  final contactedTribeIds = discoveredTribeIdsForFirstContact(
    view: view,
    game: game,
  );
  discoveredIds.removeWhere((id) {
    final isTribe = game.tribes.any((t) => t.id == id);
    if (!isTribe) return false;
    final hasRelation = view.diplomacyByOtherId.containsKey(id);
    return !hasRelation && !contactedTribeIds.contains(id);
  });
  final currentTurn = game.worldState.turnState.turnNumber;
  final factionMembership = DiplomacyFactionMembership.from(game);
  final actionsByTarget = <String, List<DiplomaticPanelAction>>{};
  for (final id in discoveredIds) {
    if (id == humanPlayerId) continue;
    actionsByTarget[id] = enumerateDiplomaticPanelActionsForTarget(
      game: game,
      topology: topology,
      playerId: humanPlayerId,
      targetId: id,
      currentOrders: currentOrders,
      factionMembership: factionMembership,
    );
  }

  final gpIds = <String>[];
  final minorIds = <String>[];
  final tribeIds = <String>[];
  for (final id in discoveredIds) {
    _appendDiscoveredFactionId(
      game,
      humanPlayerId,
      id,
      gpIds,
      minorIds,
      tribeIds,
    );
  }

  // GPs: sort by military power desc, then province count desc. SPEC/ui/diplomacy-panel.md.
  gpIds.sort((a, b) {
    final strA = aggregateMilitaryStrengthForPlayer(game, a);
    final strB = aggregateMilitaryStrengthForPlayer(game, b);
    final cmp = strB.compareTo(strA);
    if (cmp != 0) return cmp;
    final provA = provinceCountOwnedBy(game, a);
    final provB = provinceCountOwnedBy(game, b);
    return provB.compareTo(provA);
  });

  final pendingByTarget = <String, Set<DiplomaticOrderType>>{};
  final pendingOvertureStageByTarget = <String, OvertureStage>{};
  final pendingList =
      currentOrders.diplomaticOrdersByPlayerId[humanPlayerId] ?? [];
  for (final o in pendingList) {
    pendingByTarget.putIfAbsent(o.targetFactionId, () => {}).add(o.type);
    if (o.type == DiplomaticOrderType.establishOverture &&
        o.overtureStage != null) {
      pendingOvertureStageByTarget[o.targetFactionId] = o.overtureStage!;
    }
  }

  String displayNameFor(String id) {
    final p = game.playerById(id);
    if (p != null) return p.displayName;
    for (final m in game.minorNations) {
      if (m.id == id) return m.displayName ?? id;
    }
    for (final t in game.tribes) {
      if (t.id == id) return t.displayName ?? id;
    }
    return id;
  }

  List<DiplomacyRowData> rows = [];
  final playerPower = greatPowerPowerScore(game, humanPlayerId);
  for (final id in gpIds) {
    final econ = _pendingEconomicAmounts(pendingList, id);
    rows.add(
      DiplomacyRowData(
        factionId: id,
        displayName: displayNameFor(id),
        kind: FactionKind.greatPower,
        relation:
            view.diplomacyByOtherId[id] ??
            _defaultFirstContactRelation(humanPlayerId, id, currentTurn),
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? const <DiplomaticPanelAction>[],
        powerScore: greatPowerPowerScore(game, id),
        playerPowerScore: playerPower,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        pendingOvertureStage: pendingOvertureStageByTarget[id],
        activeSubsidyPercent: _outgoingSubsidyPercent(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyPercent: econ.subsidy,
        standingChips: diplomaticStandingChips(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: id,
          kind: FactionKind.greatPower,
          relation:
              view.diplomacyByOtherId[id] ??
              _defaultFirstContactRelation(humanPlayerId, id, currentTurn),
          overture: getOverture(game, humanPlayerId, id),
          purchasedTiles: purchasedTiles,
        ),
      ),
    );
  }
  minorIds.sort((a, b) => (displayNameFor(a)).compareTo(displayNameFor(b)));
  for (final id in minorIds) {
    final econ = _pendingEconomicAmounts(pendingList, id);
    rows.add(
      DiplomacyRowData(
        factionId: id,
        displayName: displayNameFor(id),
        kind: FactionKind.minor,
        relation:
            view.diplomacyByOtherId[id] ??
            _defaultFirstContactRelation(humanPlayerId, id, currentTurn),
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? const <DiplomaticPanelAction>[],
        powerScore: null,
        playerPowerScore: null,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        pendingOvertureStage: pendingOvertureStageByTarget[id],
        activeSubsidyPercent: _outgoingSubsidyPercent(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyPercent: econ.subsidy,
        standingChips: diplomaticStandingChips(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: id,
          kind: FactionKind.minor,
          relation:
              view.diplomacyByOtherId[id] ??
              _defaultFirstContactRelation(humanPlayerId, id, currentTurn),
          overture: getOverture(game, humanPlayerId, id),
          purchasedTiles: purchasedTiles,
        ),
      ),
    );
  }
  tribeIds.sort((a, b) => (displayNameFor(a)).compareTo(displayNameFor(b)));
  for (final id in tribeIds) {
    final econ = _pendingEconomicAmounts(pendingList, id);
    rows.add(
      DiplomacyRowData(
        factionId: id,
        displayName: displayNameFor(id),
        kind: FactionKind.tribe,
        relation:
            view.diplomacyByOtherId[id] ??
            _defaultFirstContactRelation(humanPlayerId, id, currentTurn),
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? const <DiplomaticPanelAction>[],
        powerScore: null,
        playerPowerScore: null,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        pendingOvertureStage: pendingOvertureStageByTarget[id],
        activeSubsidyPercent: _outgoingSubsidyPercent(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyPercent: econ.subsidy,
        standingChips: diplomaticStandingChips(
          game: game,
          humanPlayerId: humanPlayerId,
          factionId: id,
          kind: FactionKind.tribe,
          relation:
              view.diplomacyByOtherId[id] ??
              _defaultFirstContactRelation(humanPlayerId, id, currentTurn),
          overture: getOverture(game, humanPlayerId, id),
          purchasedTiles: purchasedTiles,
        ),
      ),
    );
  }
  return rows;
}
