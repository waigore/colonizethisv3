import '../perception/perception_snapshot.dart';
import 'expand_phase_planner_economy.dart' show ExpandEconomyPlan;
import 'phase_destination_result.dart';
import 'phase_priority_weights.dart' show isNwLockRecoveryPathEActive;
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;

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

/// Returns the deterministic COLONIAL-phase invasion-transport
/// directive for the active player as a [ColonialNavalPlan].
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialNaval):
///
///   "Colonial naval missions:
///      → Transport regiments to NW invasion staging.
///      → Explore unrevealed NW tiles.
///      → Cargo routing for overseas extraction."
///
/// This planner covers the **invasion-transport** arm of that contract.
/// The remaining two arms ("Explore unrevealed NW tiles" and
/// "Cargo routing for overseas extraction") are satisfied at the
/// orchestrator layer (#2509 S5) by the existing colonial naval
/// pipeline -- specifically `colonial_naval_scoring.dart` which
/// already ranks naval moves toward NW sea zones adjacent to
/// invadable provinces (exploration) and toward NW ports (cargo
/// routing). Adding those arms to this plan would duplicate behaviour
/// the orchestrator already performs through the legacy free-choice
/// pipeline, so the directive is intentionally scoped to the
/// invasion-transport decision only: which NW invadable provinces
/// should this turn's transport ships stage regiments toward?
///
/// Priority arms (first match wins; each arm produces a
/// sorted-ascending, deduplicated province list):
///   1. **Declared colonial target** -- when
///      [colonialDeclaredWarTargetFactionId] is non-null and owns at
///      least one province in
///      [ColonialSummary.invadableNewWorldProvinceIdsSorted], the
///      plan restricts to those provinces and lists only the target
///      as `priorityTargetOwnerFactionIdsSorted`. Matches the
///      [planColonialMilitary] priority-1 shape so the orchestrator
///      can pair the army-move plan with the naval-transport plan
///      against the same colonial declare-war target.
///   2. **At-war owners fallback** -- when no colonial target is
///      given (the COLONIAL acquisition method resolved to Join
///      Empire or `purchase_land` rather than `declareWar`) and at
///      least one faction in [ThreatSummary.atWarWith] owns an NW
///      invadable province, the plan restricts to the union of those
///      provinces and lists the at-war owners sorted ascending. This
///      preserves invasion-transport pressure on existing wars even
///      when the current acquisition pick is a non-war method.
///   3. **Default plan** -- when the declared colonial target owns
///      nothing in NW invadable, or when no target is given and no
///      at-war faction owns NW invadable, or for the outer guards
///      (below quota, missing player, empty NW invadable). Empty
///      plan signals the orchestrator to skip the invasion-transport
///      directive this turn; the legacy exploration + cargo arms
///      continue uninterrupted.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] by owner
///     faction.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the
///     NW-only candidate pool),
///     [ConquestSummary.oldWorldProvincesOwned] (the COLONIAL outer
///     quota gate), and [ThreatSummary.atWarWith] (the Priority 2
///     fallback when no colonial declare-war target is given).
///   - [colonialDeclaredWarTargetFactionId]: optional colonial
///     declare-war target chosen by [planColonialAcquisition] when
///     the acquisition method resolves to
///     [AcquisitionMethod.declareWar] (issue #2509 §
///     planColonialAcquisition Acquisition method 3). When non-null,
///     the planner restricts transport destinations to NW provinces
///     owned by that faction (Priority 1). The argument is not
///     constrained to a specific faction class -- tribes, minor
///     nations, and Great Powers are all valid invasion-transport
///     targets per the spec because COLONIAL allows invasion against
///     any colonial blocker; the acquisition planner returns only
///     tribe / minor ids today, but [planColonialNaval] does not
///     re-narrow the argument so the orchestrator stays free to pass
///     any at-war target.
///
/// Structural OW suppression: this function reads only
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW-only by
/// builder contract). It never reads
/// [ConquestSummary.invadableProvinceIdsSorted], so an Old World
/// province cannot appear in the plan even when the snapshot exposes
/// one.
///
/// Difference vs [planColonialLiteNaval]: [planColonialLiteNaval]
/// filters out GP-owned NW invadable provinces because COLONIAL-lite
/// is the safeguard for tribe / minor NW penetration only and
/// suppresses NW `declareWar` entirely. [planColonialNaval] does
/// **not** apply that filter: invading a GP-owned NW invadable
/// province (the primary colonial GP blocker) is a legitimate
/// COLONIAL acquisition path. Both planners share the
/// "empty plan = orchestrator falls back to legacy free-choice
/// colonial naval pipeline" contract, just with different
/// owner-class admissibility for the priority arm.
///
/// Outer guard rationale: [isBelowObserverConquestQuota] returning
/// `true` means the active player has not reached
/// [kObserverConquestMinOwProvincesPerGp] (the EXPAND -> COLONIAL
/// transition threshold). The function returns [defaultPlan] in that
/// case so a mis-dispatched call from EXPAND territory cannot leak
/// NW invasion-transport destinations; matches the symmetric guard in
/// [planColonialMilitary] (the army-move plan also short-circuits
/// below quota so EXPAND callers never receive an NW directive).
///
/// The function is pure and deterministic -- identical inputs always
/// yield identical [ColonialNavalPlan]s (Refs #2509 Must-have #7).
ColonialNavalPlan planColonialNaval({
  required Game game,
  required AIWorldSnapshot snapshot,
  String? colonialDeclaredWarTargetFactionId,
  ExpandEconomyPlan expandEconomyPlan =
      ExpandEconomyPlan.defaultPlan,
}) {
  if (isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
      !isNwLockRecoveryPathEActive(
        snapshot: snapshot,
        expandEconomyPlan: expandEconomyPlan,
      )) {
    return ColonialNavalPlan.defaultPlan;
  }
  if (game.playerById(snapshot.playerId) == null) {
    return ColonialNavalPlan.defaultPlan;
  }
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ColonialNavalPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);

  if (colonialDeclaredWarTargetFactionId != null) {
    final destinations = <String>[
      for (final pid in invadable)
        if (provinceOwner[pid] == colonialDeclaredWarTargetFactionId) pid,
    ];
    if (destinations.isEmpty) {
      return ColonialNavalPlan.defaultPlan;
    }
    destinations.sort();
    return ColonialNavalPlan(
      priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
        destinations,
      ),
      priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(<String>[
        colonialDeclaredWarTargetFactionId,
      ]),
    );
  }

  final atWarSet = snapshot.threats.atWarWith.toSet();
  final atWarOwners = <String>{};
  final destinations = <String>[];
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (!atWarSet.contains(owner)) continue;
    destinations.add(pid);
    atWarOwners.add(owner);
  }
  if (destinations.isEmpty) {
    return ColonialNavalPlan.defaultPlan;
  }
  destinations.sort();
  final owners = atWarOwners.toList()..sort();
  return ColonialNavalPlan(
    priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
      destinations,
    ),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}
