import 'phase_destination_result.dart';

/// COLONIAL-phase invasion-transport destination filter returned by
/// [planColonialNaval].
///
/// Two ascending-sorted lists describe the priority subset of NW
/// invadable provinces (and the owning faction(s)) that
/// invasion-transport naval moves should land regiments at this turn.
/// The lists never contain Old World provinces -- structural
/// suppression in [planColonialNaval] (the planner only reads
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted], which is
/// NW-only by construction in the perception-snapshot builder).
///
/// Unlike [ColonialLiteNavalPlan], the COLONIAL invasion-transport
/// directive **does not** filter out GP-owned NW invadable provinces:
/// COLONIAL acquisition method 3 (issue #2509 § planColonialAcquisition
/// step 3) explicitly permits `declareWar` + invasion against any
/// faction class -- tribes, minor nations, **and** Great Powers
/// blocking the colonial frontier -- so a GP-owned NW invadable
/// province is a legitimate transport destination here. The
/// COLONIAL-lite sibling, by contrast, suppresses NW `declareWar` and
/// must therefore exclude GP-owned NW invadable from its naval focus.
///
/// The orchestrator (Refs #2509 S5) consumes the plan as a filter on
/// the existing colonial naval pipeline:
///   - [defaultPlan]
///     (`priorityInvasionTransportProvinceIdsSorted` empty) =
///     "no invasion-transport directive this turn"; the orchestrator
///     keeps running the legacy free-choice colonial naval pipeline as
///     exploration + cargo only (the two non-invasion arms from the
///     spec stay live; they are satisfied by `colonial_naval_scoring.dart`
///     without any input from this plan).
///   - A non-default plan = "restrict invasion-transport landing
///     destinations to this NW invadable subset". Non-empty plans
///     always carry at least one owner faction id; empty plans never
///     carry [priorityTargetOwnerFactionIdsSorted] entries.
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path. Value equality compares both list contents so tests
/// can assert against literal constructions without relying on
/// identity, mirroring the [ColonialMilitaryPlan] /
/// [ColonialLiteNavalPlan] shape.
final class ColonialNavalPlan extends PhaseDestinationResult {
  const ColonialNavalPlan({
    required List<String> priorityInvasionTransportProvinceIdsSorted,
    required List<String> priorityTargetOwnerFactionIdsSorted,
  }) : super(
         priorityProvinceIdsSorted: priorityInvasionTransportProvinceIdsSorted,
         priorityTargetOwnerFactionIdsSorted:
             priorityTargetOwnerFactionIdsSorted,
       );

  /// Reusable "no override" plan returned for the outer COLONIAL
  /// guards (below quota, missing player, empty NW invadable) and for
  /// the priority-arm fall-through (declared colonial target owns
  /// nothing in NW invadable and no at-war faction owns NW invadable
  /// either). The orchestrator (#2509 S5) treats `defaultPlan` as "no
  /// invasion-transport directive this turn" and runs the legacy
  /// free-choice colonial naval pipeline as exploration + cargo only.
  static const ColonialNavalPlan defaultPlan = ColonialNavalPlan(
    priorityInvasionTransportProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ColonialSummary.invadableNewWorldProvinceIdsSorted]
  /// (NW only by builder contract) where invasion-transport naval
  /// moves should land regiments this turn. Sorted ascending so
  /// identical inputs yield identical lists (Refs #2509
  /// Must-have #7). Empty for [defaultPlan].
  ///
  /// The orchestrator (#2509 S5) is expected to combine this list
  /// with `MapTopology` (via
  /// `newWorldSeaZonesAdjacentToInvadableProvinces` in
  /// `colonial_naval_scoring.dart`) to derive the actual sea-zone
  /// transport destinations and fleet pairings. Exploration of
  /// unrevealed NW tiles and cargo routing for overseas extraction
  /// are satisfied at the orchestrator layer by the existing
  /// colonial naval pathing the directive does not override -- the
  /// plan is intentionally scoped to the invasion-transport arm so a
  /// non-default plan does not suppress the parallel exploration /
  /// cargo activity.
  List<String> get priorityInvasionTransportProvinceIdsSorted =>
      priorityProvinceIdsSorted;

  /// Faction ids of the owners covered by
  /// [priorityInvasionTransportProvinceIdsSorted]. Sorted ascending
  /// and deduplicated:
  ///   - Single-element list when the declared colonial-target arm
  ///     fires ([planColonialNaval] § Priority 1). The target may
  ///     be a tribe, minor nation, or Great Power -- the planner
  ///     does not partition by faction class because COLONIAL
  ///     acquisition via `declareWar` (issue #2509 §
  ///     planColonialAcquisition step 3) can pick any of those.
  ///   - One or more entries (sorted at-war owners) when the at-war
  ///     fallback arm fires ([planColonialNaval] § Priority 2).
  ///   - Empty for [defaultPlan].
  @override
  List<String> get priorityTargetOwnerFactionIdsSorted =>
      super.priorityTargetOwnerFactionIdsSorted;

  @override
  String toString() =>
      'ColonialNavalPlan('
      'priorityInvasionTransportProvinceIdsSorted: '
      '$priorityInvasionTransportProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

