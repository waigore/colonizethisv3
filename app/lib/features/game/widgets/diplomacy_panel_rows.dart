// Row model and builder for diplomacy UI. SPEC/ui/diplomacy-panel.md.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

int? _outgoingSubsidyPerTurn(Game game, String payerId, String targetId) {
  for (final s in game.subsidyStates) {
    if (s.payerId == payerId && s.targetId == targetId) {
      return s.amountPerTurn;
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

/// Faction type for display. SPEC/game/factions.md.
enum FactionKind { greatPower, minor, tribe }

/// Diplomacy panel bottom mode-bar filter selection, per
/// `SPEC/ui/diplomacy-panel.md` § Mode bar (filter).
///
/// - [all] shows Great Powers, Minor Nations, and Tribes (default).
/// - [greatPowersOnly] hides Minor Nations and Tribes.
/// - [minorsOnly] hides Great Powers; both Minor Nations and Tribes remain
///   visible (the word "Minors" is shorthand for "non-Great-Power factions").
enum DiplomacyFilterMode { all, greatPowersOnly, minorsOnly }

/// Returns `true` when [kind] is visible under the given mode-bar [mode],
/// per `SPEC/ui/diplomacy-panel.md` § Mode bar (filter).
bool diplomacyFilterShowsKind(DiplomacyFilterMode mode, FactionKind kind) {
  switch (mode) {
    case DiplomacyFilterMode.all:
      return true;
    case DiplomacyFilterMode.greatPowersOnly:
      return kind == FactionKind.greatPower;
    case DiplomacyFilterMode.minorsOnly:
      return kind == FactionKind.minor || kind == FactionKind.tribe;
  }
}

/// One row of data for the diplomacy list.
class DiplomacyRowData {
  const DiplomacyRowData({
    required this.factionId,
    required this.displayName,
    required this.kind,
    required this.relation,
    this.overture,
    required this.actions,
    this.powerScore,
    this.playerPowerScore,
    required this.pendingOrderTypes,
    this.activeSubsidyPerTurn,
    this.pendingGrantAmount,
    this.pendingSubsidyAmount,
  });

  final String factionId;
  final String displayName;
  final FactionKind kind;
  final DiplomacyRelation? relation;
  final OvertureState? overture;
  final List<DiplomaticOrder> actions;

  /// Great Power power score (SPEC/game/diplomacy.md). Only set for GP rows.
  final int? powerScore;

  /// Human player's power score for comparison (red if GP score > this). Only set for GP rows.
  final int? playerPowerScore;

  /// Set of DiplomaticOrderType that are currently pending for this target faction.
  final Set<DiplomaticOrderType> pendingOrderTypes;

  /// Active £/turn subsidy from the human GP to this row's faction (`Game.subsidyStates`).
  final int? activeSubsidyPerTurn;

  /// Pending grant aid amount in current-turn orders (not yet resolved).
  final int? pendingGrantAmount;

  /// Pending set-subsidy amount per turn in current-turn orders.
  final int? pendingSubsidyAmount;
}

/// Builds list of discovered factions and their available actions.
/// Discovered = has a relation with the player. SPEC/ui/diplomacy-panel.md.
List<DiplomacyRowData> buildDiplomacyRows(
  Game game,
  MapTopology topology,
  String humanPlayerId,
  Orders currentOrders,
) {
  const suggestionApi = DefaultOrderSuggestionAPI();
  final view = buildPlayerView(game, topology, humanPlayerId);
  final discoveredIds = view.diplomacyByOtherId.keys.toList();
  final suggestions = suggestionApi.suggestDiplomaticOrders(
    view,
    game,
    topology,
    currentOrders,
  );
  final actionsByTarget = <String, List<DiplomaticOrder>>{};
  for (final order in suggestions) {
    actionsByTarget.putIfAbsent(order.targetFactionId, () => []).add(order);
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
  final pendingList =
      currentOrders.diplomaticOrdersByPlayerId[humanPlayerId] ?? [];
  for (final o in pendingList) {
    pendingByTarget.putIfAbsent(o.targetFactionId, () => {}).add(o.type);
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
        relation: view.diplomacyByOtherId[id],
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? [],
        powerScore: greatPowerPowerScore(game, id),
        playerPowerScore: playerPower,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        activeSubsidyPerTurn: _outgoingSubsidyPerTurn(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyAmount: econ.subsidy,
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
        relation: view.diplomacyByOtherId[id],
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? [],
        powerScore: null,
        playerPowerScore: null,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        activeSubsidyPerTurn: _outgoingSubsidyPerTurn(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyAmount: econ.subsidy,
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
        relation: view.diplomacyByOtherId[id],
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? [],
        powerScore: null,
        playerPowerScore: null,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        activeSubsidyPerTurn: _outgoingSubsidyPerTurn(game, humanPlayerId, id),
        pendingGrantAmount: econ.grant,
        pendingSubsidyAmount: econ.subsidy,
      ),
    );
  }
  return rows;
}

/// Computes the relative Great Power power-comparison percentage used by
/// `SPEC/ui/diplomacy-panel.md` § Power comparison percentage.
///
/// Formula: `round(((gpPowerScore - playerPowerScore) / max(playerPowerScore,
/// 1)) * 100)`. The `max(.., 1)` guard prevents division-by-zero when the
/// human player's score is `0`, yielding a finite percentage.
///
/// Returns the integer percentage (positive when the GP is stronger, negative
/// when weaker, zero when equal).
int powerComparisonPercent(int gpPowerScore, int playerPowerScore) {
  final int denom = math.max(playerPowerScore, 1);
  final double ratio = (gpPowerScore - playerPowerScore) / denom;
  return (ratio * 100).round();
}

/// Formats a `powerComparisonPercent` integer for display per
/// `SPEC/ui/diplomacy-panel.md` § Power comparison percentage:
/// `+N%` when positive, `−N%` (U+2212 minus) when negative, `0%` when zero.
///
/// The minus sign is the unicode `MINUS SIGN` (U+2212) to match the mockup,
/// not the ASCII hyphen-minus (U+002D).
String formatPowerComparisonPercent(int pct) {
  if (pct > 0) return '+$pct%';
  if (pct < 0) return '\u2212${-pct}%';
  return '0%';
}
