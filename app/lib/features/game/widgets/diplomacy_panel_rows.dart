// Row model and builder for diplomacy UI. SPEC/ui/diplomacy-panel.md.

import 'dart:math' as math;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

/// Faction type for display. SPEC/game/factions.md.
enum FactionKind { greatPower, minor, tribe }

/// Overture/treaty milestone chip labels for the diplomatic standing chip
/// cluster (SPEC/ui/diplomacy-panel.md § Diplomatic standing chip cluster,
/// Refs #3753 R12). Library-scope constants mirroring the non-localized
/// `WAR` / `PEACE` / `ALLIANCE` badge-label convention.
const String kDiplomacyChipConsulate = 'Consulate';
const String kDiplomacyChipEmbassy = 'Embassy';
const String kDiplomacyChipNap = 'NAP';
const String kDiplomacyChipJoinEmpire = 'Join Empire';
const String kDiplomacyChipColony = 'Colony';

/// Prefix for a boycott the human Great Power has imposed through a colony,
/// followed by the boycotted target GP's display name (Refs #3753 R12).
const String kDiplomacyChipBoycottVsPrefix = 'Boycott vs ';

/// Prefix for a boycott imposed on the human Great Power by another colony
/// holder, followed by that GP's display name (Refs #3753 R12).
const String kDiplomacyChipBoycottedByPrefix = 'Boycotted by ';

/// Prefix for the overseas-holdings chip (Refs #3753 R12 / R8). Rendered as
/// `Overseas: {tileCount} · {sharePercent}%`.
const String kDiplomacyChipOverseasPrefix = 'Overseas: ';

/// Active diplomatic overture/treaty/economic state for one faction row,
/// surfaced by the [DiplomacyStandingChipCluster]. SPEC/ui/diplomacy-panel.md
/// § Diplomatic standing chip cluster (Refs #3753 R12 / S13).
class DiplomaticStandingChips {
  const DiplomaticStandingChips({
    this.treatyLabels = const <String>[],
    this.boycottVsNames = const <String>[],
    this.boycottedByNames = const <String>[],
    this.overseasTileCount = 0,
    this.overseasSharePercent = 0,
  });

  /// Cumulative overture/treaty milestone labels (Consulate / Embassy / NAP)
  /// plus the terminal `Join Empire` (Minor) or `Colony` (Tribe) chip.
  final List<String> treatyLabels;

  /// Display names of Great Powers the human GP boycotts through this colony
  /// Tribe (only populated for a Tribe that is a colony of the human GP).
  final List<String> boycottVsNames;

  /// Display names of Great Powers boycotting the human GP from trading with
  /// this colony Tribe (only populated for a Tribe colony of another GP).
  final List<String> boycottedByNames;

  /// Count of human-owned purchased tiles sourced from this faction (R8).
  final int overseasTileCount;

  /// Overseas tile-owner share rate as a whole-number percent (the rounded
  /// decimal relation score, per R8.2 `relationScore / 100`).
  final int overseasSharePercent;

  /// True when no standing chip applies, so the cluster renders nothing.
  bool get isEmpty =>
      treatyLabels.isEmpty &&
      boycottVsNames.isEmpty &&
      boycottedByNames.isEmpty &&
      overseasTileCount <= 0;

  bool get isNotEmpty => !isEmpty;
}

/// Derives the [DiplomaticStandingChips] for a faction row from current
/// [game] state. SPEC/ui/diplomacy-panel.md § Diplomatic standing chip
/// cluster (Refs #3753 R12). [purchasedTiles] is built once per render pass
/// by the caller (e.g. [buildDiplomacyRows]) so the per-tile attribution scan
/// is not repeated per row.
DiplomaticStandingChips diplomaticStandingChips({
  required Game game,
  required String humanPlayerId,
  required String factionId,
  required FactionKind kind,
  required DiplomacyRelation? relation,
  required OvertureState? overture,
  required PurchasedTileIndex purchasedTiles,
}) {
  final OvertureStage stage = overture?.stage ?? OvertureStage.none;
  final treaty = <String>[];
  if (stage.index >= OvertureStage.tradeConsulate.index) {
    treaty.add(kDiplomacyChipConsulate);
  }
  if (stage.index >= OvertureStage.embassy.index) {
    treaty.add(kDiplomacyChipEmbassy);
  }
  if (stage.index >= OvertureStage.nap.index) {
    treaty.add(kDiplomacyChipNap);
  }

  String? colonyOfGpId;
  if (kind == FactionKind.tribe) {
    for (final c in game.colonyStates) {
      if (c.tribeId == factionId) {
        colonyOfGpId = c.colonyOfGpId;
        break;
      }
    }
  }
  final bool isColonyOfHuman = colonyOfGpId == humanPlayerId;
  if (isColonyOfHuman) {
    treaty.add(kDiplomacyChipColony);
  } else if (kind == FactionKind.minor && stage == OvertureStage.joinEmpire) {
    treaty.add(kDiplomacyChipJoinEmpire);
  }

  String nameOf(String id) => game.playerById(id)?.displayName ?? id;

  final boycottVs = <String>[];
  final boycottedBy = <String>[];
  if (colonyOfGpId != null) {
    if (isColonyOfHuman) {
      for (final b in game.boycottStates) {
        if (b.gpId == humanPlayerId) {
          boycottVs.add(nameOf(b.targetGpId));
        }
      }
    } else {
      for (final b in game.boycottStates) {
        if (b.gpId == colonyOfGpId && b.targetGpId == humanPlayerId) {
          boycottedBy.add(nameOf(colonyOfGpId));
        }
      }
    }
  }

  int overseasCount = 0;
  if (kind != FactionKind.greatPower) {
    for (final a in purchasedTiles.attributions) {
      if (a.owningGpId == humanPlayerId && a.sourceFactionId == factionId) {
        overseasCount++;
      }
    }
  }
  final int overseasShare = relation == null ? 0 : relation.score.round();

  return DiplomaticStandingChips(
    treatyLabels: treaty,
    boycottVsNames: boycottVs,
    boycottedByNames: boycottedBy,
    overseasTileCount: overseasCount,
    overseasSharePercent: overseasShare,
  );
}

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
    this.activeSubsidyPercent,
    this.pendingGrantAmount,
    this.pendingSubsidyPercent,
    this.standingChips = const DiplomaticStandingChips(),
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

  /// Active subsidy **percentage** (5–20) from the human GP to this row's
  /// faction (`Game.subsidyStates`; Refs #3753 R3).
  final int? activeSubsidyPercent;

  /// Pending grant aid amount in current-turn orders (not yet resolved).
  final int? pendingGrantAmount;

  /// Pending set-subsidy **percentage** in current-turn orders (Refs #3753 R3).
  final int? pendingSubsidyPercent;

  /// Active diplomatic overture/treaty/economic state chips for this row's
  /// faction. SPEC/ui/diplomacy-panel.md § Diplomatic standing chip cluster
  /// (Refs #3753 R12).
  final DiplomaticStandingChips standingChips;
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
