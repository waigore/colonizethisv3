// Discovery and pending-order helpers for diplomacy row assembly.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'diplomacy_panel_rows.dart';
import 'diplomacy_panel_rows_standing_chips.dart';

int? outgoingSubsidyPercent(Game game, String payerId, String targetId) {
  for (final s in game.subsidyStates) {
    if (s.payerId == payerId && s.targetId == targetId) {
      return s.percent;
    }
  }
  return null;
}

void appendDiscoveredFactionId(
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

({int? grant, int? subsidy}) pendingEconomicAmounts(
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
DiplomacyRelation defaultFirstContactRelation(
  String humanPlayerId,
  String factionId,
  int currentTurn,
) => DiplomacyRelation(
  factionId1: humanPlayerId,
  factionId2: factionId,
  sinceTurn: currentTurn,
  lastInteractionTurn: currentTurn,
);

String displayNameForFaction(Game game, String id) {
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

DiplomacyRowData buildDiplomacyRowData({
  required Game game,
  required String humanPlayerId,
  required String factionId,
  required FactionKind kind,
  required PlayerView view,
  required int currentTurn,
  required List<DiplomaticPanelAction> actions,
  required Set<DiplomaticOrderType> pendingOrderTypes,
  required OvertureStage? pendingOvertureStage,
  required int? pendingGrantAmount,
  required int? pendingSubsidyPercent,
  required PurchasedTileIndex purchasedTiles,
  int? powerScore,
  int? playerPowerScore,
}) {
  final relation =
      view.diplomacyByOtherId[factionId] ??
      defaultFirstContactRelation(humanPlayerId, factionId, currentTurn);
  return DiplomacyRowData(
    factionId: factionId,
    displayName: displayNameForFaction(game, factionId),
    kind: kind,
    relation: relation,
    overture: getOverture(game, humanPlayerId, factionId),
    actions: actions,
    powerScore: powerScore,
    playerPowerScore: playerPowerScore,
    pendingOrderTypes: pendingOrderTypes,
    pendingOvertureStage: pendingOvertureStage,
    activeSubsidyPercent: outgoingSubsidyPercent(game, humanPlayerId, factionId),
    pendingGrantAmount: pendingGrantAmount,
    pendingSubsidyPercent: pendingSubsidyPercent,
    standingChips: diplomaticStandingChips(
      game: game,
      humanPlayerId: humanPlayerId,
      factionId: factionId,
      kind: kind,
      relation: relation,
      overture: getOverture(game, humanPlayerId, factionId),
      purchasedTiles: purchasedTiles,
    ),
  );
}
