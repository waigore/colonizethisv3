// Row model and builder for diplomacy UI. SPEC/ui/diplomacy-panel.md.

import 'package:colonizethis_orders/colonizethis_orders.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

export 'diplomacy_panel_rows_builder.dart';
export 'diplomacy_panel_rows_power.dart';
export 'diplomacy_panel_rows_standing_chips.dart';

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
