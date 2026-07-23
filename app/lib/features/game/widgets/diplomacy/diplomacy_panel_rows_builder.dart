/// Row-builder pipeline for diplomacy panel faction lists.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_panel_rows_models.dart';
import 'diplomacy_panel_rows_builder_helpers.dart';
import 'diplomacy_panel_rows_standing_chips.dart';

/// Row-builder pipeline for diplomacy panel faction lists.


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
    appendDiscoveredFactionId(
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

  final rows = <DiplomacyRowData>[];
  final playerPower = greatPowerPowerScore(game, humanPlayerId);
  for (final id in gpIds) {
    final econ = pendingEconomicAmounts(pendingList, id);
    rows.add(
      buildDiplomacyRowData(
        game: game,
        humanPlayerId: humanPlayerId,
        factionId: id,
        kind: FactionKind.greatPower,
        view: view,
        currentTurn: currentTurn,
        actions: actionsByTarget[id] ?? const <DiplomaticPanelAction>[],
        pendingOrderTypes: pendingByTarget[id] ?? {},
        pendingOvertureStage: pendingOvertureStageByTarget[id],
        pendingGrantAmount: econ.grant,
        pendingSubsidyPercent: econ.subsidy,
        purchasedTiles: purchasedTiles,
        powerScore: greatPowerPowerScore(game, id),
        playerPowerScore: playerPower,
      ),
    );
  }
  minorIds.sort(
    (a, b) => displayNameForFaction(game, a).compareTo(
      displayNameForFaction(game, b),
    ),
  );
  for (final id in minorIds) {
    final econ = pendingEconomicAmounts(pendingList, id);
    rows.add(
      buildDiplomacyRowData(
        game: game,
        humanPlayerId: humanPlayerId,
        factionId: id,
        kind: FactionKind.minor,
        view: view,
        currentTurn: currentTurn,
        actions: actionsByTarget[id] ?? const <DiplomaticPanelAction>[],
        pendingOrderTypes: pendingByTarget[id] ?? {},
        pendingOvertureStage: pendingOvertureStageByTarget[id],
        pendingGrantAmount: econ.grant,
        pendingSubsidyPercent: econ.subsidy,
        purchasedTiles: purchasedTiles,
      ),
    );
  }
  tribeIds.sort(
    (a, b) => displayNameForFaction(game, a).compareTo(
      displayNameForFaction(game, b),
    ),
  );
  for (final id in tribeIds) {
    final econ = pendingEconomicAmounts(pendingList, id);
    rows.add(
      buildDiplomacyRowData(
        game: game,
        humanPlayerId: humanPlayerId,
        factionId: id,
        kind: FactionKind.tribe,
        view: view,
        currentTurn: currentTurn,
        actions: actionsByTarget[id] ?? const <DiplomaticPanelAction>[],
        pendingOrderTypes: pendingByTarget[id] ?? {},
        pendingOvertureStage: pendingOvertureStageByTarget[id],
        pendingGrantAmount: econ.grant,
        pendingSubsidyPercent: econ.subsidy,
        purchasedTiles: purchasedTiles,
      ),
    );
  }
  return rows;
}
