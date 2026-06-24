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
    this.pendingOvertureStage,
    this.activeSubsidyPerTurn,
    this.pendingGrantAmount,
    this.pendingSubsidyAmount,
  });

  final String factionId;
  final String displayName;
  final FactionKind kind;
  final DiplomacyRelation? relation;
  final OvertureState? overture;
  final List<DiplomaticPanelAction> actions;

  /// Great Power power score (SPEC/game/diplomacy.md). Only set for GP rows.
  final int? powerScore;

  /// Human player's power score for comparison (red if GP score > this). Only set for GP rows.
  final int? playerPowerScore;

  /// Set of DiplomaticOrderType that are currently pending for this target faction.
  final Set<DiplomaticOrderType> pendingOrderTypes;

  /// When an [establishOverture] order is pending, the queued overture stage.
  final OvertureStage? pendingOvertureStage;

  /// Active £/turn subsidy from the human GP to this row's faction (`Game.subsidyStates`).
  final int? activeSubsidyPerTurn;

  /// Pending grant aid amount in current-turn orders (not yet resolved).
  final int? pendingGrantAmount;

  /// Pending set-subsidy amount per turn in current-turn orders.
  final int? pendingSubsidyAmount;
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
        relation:
            view.diplomacyByOtherId[id] ??
            _defaultFirstContactRelation(humanPlayerId, id, currentTurn),
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? const <DiplomaticPanelAction>[],
        powerScore: null,
        playerPowerScore: null,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        pendingOvertureStage: pendingOvertureStageByTarget[id],
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
        relation:
            view.diplomacyByOtherId[id] ??
            _defaultFirstContactRelation(humanPlayerId, id, currentTurn),
        overture: getOverture(game, humanPlayerId, id),
        actions: actionsByTarget[id] ?? const <DiplomaticPanelAction>[],
        powerScore: null,
        playerPowerScore: null,
        pendingOrderTypes: pendingByTarget[id] ?? {},
        pendingOvertureStage: pendingOvertureStageByTarget[id],
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

/// Display-only strength tier derived from a `powerComparisonPercent` value
/// per `SPEC/ui/diplomacy-panel.md` § Relative power line. The tier is a
/// UI-only label and never feeds AI war-desire or any logic-package model.
enum PowerComparisonTier {
  vastlyInferior,
  inferior,
  roughlyEqual,
  superior,
  vastlySuperior,
}

/// Maps a `powerComparisonPercent` integer to its [PowerComparisonTier] per
/// the boundary table in `SPEC/ui/diplomacy-panel.md` § Relative power line:
///
/// | `pct` range | Tier |
/// |-------------|------|
/// | `pct >= +31` | vastlySuperior |
/// | `+11 .. +30` | superior |
/// | `−10 .. +10` | roughlyEqual |
/// | `−30 .. −11` | inferior |
/// | `pct <= −31` | vastlyInferior |
///
/// Boundaries are inclusive on the side shown (e.g. `+10` is roughlyEqual,
/// `+11` is superior). Extreme values (e.g. `+4900` when the player score is
/// near zero) clamp into [PowerComparisonTier.vastlySuperior] without a cap.
PowerComparisonTier powerComparisonTier(int pct) {
  if (pct <= -31) return PowerComparisonTier.vastlyInferior;
  if (pct <= -11) return PowerComparisonTier.inferior;
  if (pct <= 10) return PowerComparisonTier.roughlyEqual;
  if (pct <= 30) return PowerComparisonTier.superior;
  return PowerComparisonTier.vastlySuperior;
}
