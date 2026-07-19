import '../perception/perception_snapshot.dart';
import 'phase_destination_result.dart';
import 'planning_imports.dart' hide cheapestRegimentBuildTreasuryCost;

/// Returns the deterministic list of NW tribe / minor faction ids the active
/// COLONIAL-lite player should `establishOverture` toward this turn.
///
/// Contract (issue #2509 § COLONIAL-lite § planColonialLiteOvertures):
///
///   "Inputs: Game, AIWorldSnapshot.
///    Returns: List<DiplomacyOrder> (establishOverture only).
///
///    For each visible NW tribe/minor owner in
///    adjacentNewWorldOwnerFactionIdsSorted ∪
///    preferredColonialTargetFactionIdsSorted:
///      → If no embassy yet, suggest establishOverture(tribe).
///      → Never emit declareWar, joinEmpire chain advance, or
///        purchase_land here.
///    Tiebreak: lowest factionId (deterministic)."
///
/// COLONIAL-lite is the parallel COLONIAL safeguard inside EXPAND scheduled
/// at turn ≥120 with OW ≥9 and below quota and global `newWorld|` carrying
/// non-GP ownership (issue #2509 § COLONIAL-lite). It is the **only**
/// exception to EXPAND's total NW suppression and prevents the deadlock
/// where no GP reaches OW = 10 and zero NW colonisation ever begins. The
/// orchestrator (#2509 S5) is expected to dispatch this planner only when
/// `observerGoalPhaseFor` resolves to [ObserverGoalPhase.colonialLite]; the
/// function itself does not re-check the phase, matching the other planner
/// contracts in this module.
///
/// Return type is `List<String>` of target faction ids (not the underlying
/// [DiplomaticOrder] objects) for parity with [planColonialPeace] and
/// `planExpandPeace`: the orchestrator translates the id list into the
/// concrete `establishOverture` order envelope, applying the deferred
/// suggestion-API validation step (#2509 S5). The list is sorted ascending
/// so identical inputs always yield identical outputs (Refs #2509 Must-have
/// #7) and the lowest-factionId tiebreak from the spec is preserved.
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard, walks the GP filter on each candidate
///     ([Game.playerById] for tribes / minors returns `null`), and reads
///     [Game.overtureStates] to filter out targets that already advanced
///     past the `tradeConsulate` stage with the active player.
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.adjacentNewWorldOwnerFactionIdsSorted] and
///     [ColonialSummary.preferredColonialTargetFactionIdsSorted]. Both
///     lists are unioned (sorted-deduplicated) before the GP / embassy
///     filters run.
///
/// Filter pipeline (each stage is structural, not configurable):
///   1. **Missing active player** -> empty list (the planner cannot
///      compute a per-player overture set without an owning [Player]).
///   2. **Empty candidate union** -> empty list (no visible NW tribe /
///      minor owner -- nothing to overture this turn).
///   3. **GP candidate filter** -> drop any candidate id where
///      [Game.playerById] returns a non-null [Player]. GPs do not
///      receive `establishOverture` per the spec ("Never emit
///      declareWar ... here" implies GP-vs-GP wars are out of scope for
///      this planner; GP-vs-GP peace is the [planColonialPeace] /
///      `planExpandPeace` contract).
///   4. **Embassy filter** -> drop any candidate where the active
///      player already holds an [OvertureState] with the target whose
///      [OvertureState.hasEmbassy] is `true` (stage in `{embassy, nap,
///      joinEmpire}`). The active-player constraint matters because
///      `game.overtureStates` lists per-GP entries -- a sibling GP's
///      embassy must not block the active player from initiating its
///      own overture.
///   5. **Sort ascending** -> deterministic list output (Refs #2509
///      Must-have #7).
///
/// The function is pure and deterministic — identical inputs always yield
/// identical lists.
List<String> planColonialLiteOvertures({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final activePlayerId = snapshot.playerId;
  if (game.playerById(activePlayerId) == null) {
    return const [];
  }

  final candidates = <String>{};
  candidates.addAll(snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted);
  candidates.addAll(snapshot.colonial.preferredColonialTargetFactionIdsSorted);
  if (candidates.isEmpty) {
    return const [];
  }

  final result = <String>[];
  for (final factionId in candidates) {
    if (game.playerById(factionId) != null) continue;
    final alreadyEmbassied = game.overtureStates.any(
      (o) =>
          o.gpId == activePlayerId && o.targetId == factionId && o.hasEmbassy,
    );
    if (alreadyEmbassied) continue;
    result.add(factionId);
  }
  result.sort();
  return result;
}

/// Deterministic COLONIAL-lite naval directive returned by
/// [planColonialLiteNaval].
///
/// Carries the priority subset of
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW only) the
/// orchestrator (#2509 S5) should treat as the COLONIAL-lite naval
/// exploration / cargo focus this turn, restricted to provinces owned
/// by tribes or minor nations. Two paired list fields keep the value
/// class symmetric with [ColonialMilitaryPlan] so test fixtures and
/// orchestrator wiring can swap between them with the same shape:
/// `priorityNwProvinceIdsSorted` is the conquest-style destination
/// list (province ids) and `priorityTargetOwnerFactionIdsSorted` is
/// the corresponding owner-faction roster, both deduplicated and
/// sorted ascending so identical inputs always yield identical plans
/// (Refs #2509 Must-have #7).
///
/// `const`-friendly so the default "no override" return uses a single
/// shared instance ([defaultPlan]) without per-call allocations on the
/// hot AI path. Value equality compares both list contents so tests
/// can assert against literal constructions without relying on
/// identity.
final class ColonialLiteNavalPlan extends PhaseDestinationResult {
  const ColonialLiteNavalPlan({
    required List<String> priorityNwProvinceIdsSorted,
    required List<String> priorityTargetOwnerFactionIdsSorted,
  }) : super(
         priorityProvinceIdsSorted: priorityNwProvinceIdsSorted,
         priorityTargetOwnerFactionIdsSorted:
             priorityTargetOwnerFactionIdsSorted,
       );

  /// Reusable "no override" plan returned for the outer defensive
  /// guards (missing player, empty NW invadable) and for the
  /// priority-arm fall-through (no tribe / minor faction owns any NW
  /// invadable province). The orchestrator (#2509 S5) treats
  /// `defaultPlan` as "no COLONIAL-lite naval focus this turn" and
  /// leaves the existing naval suggestion pipeline to its legacy
  /// free-choice behaviour.
  static const ColonialLiteNavalPlan defaultPlan = ColonialLiteNavalPlan(
    priorityNwProvinceIdsSorted: <String>[],
    priorityTargetOwnerFactionIdsSorted: <String>[],
  );

  /// Subset of [ColonialSummary.invadableNewWorldProvinceIdsSorted]
  /// (NW only by builder contract) whose owners are tribes or minor
  /// nations -- the COLONIAL-lite naval exploration / cargo focus
  /// this turn. Sorted ascending so identical inputs yield identical
  /// lists (Refs #2509 Must-have #7). Empty for [defaultPlan].
  ///
  /// The orchestrator (#2509 S5) is expected to combine this list
  /// with `MapTopology` (via
  /// `newWorldSeaZonesAdjacentToInvadableProvinces` in
  /// `colonial_naval_scoring.dart`) to derive the actual sea-zone
  /// naval-move destinations. Cargo routing (deliver riches to OW
  /// stockpile) is satisfied at the orchestrator layer by the
  /// existing colonial naval pathing the directive does not override.
  List<String> get priorityNwProvinceIdsSorted => priorityProvinceIdsSorted;

  /// Faction ids of the tribes / minor nations owning the provinces
  /// in [priorityNwProvinceIdsSorted]. Sorted ascending and
  /// deduplicated. Never includes any Great Power id -- GPs are
  /// structurally excluded by [planColonialLiteNaval] because
  /// COLONIAL-lite is the safeguard for **tribe / minor** NW
  /// penetration only (issue #2509 § COLONIAL-lite "establishOverture
  /// toward visible NW tribe / minor owners"). Empty for [defaultPlan].
  @override
  List<String> get priorityTargetOwnerFactionIdsSorted =>
      super.priorityTargetOwnerFactionIdsSorted;

  @override
  String toString() =>
      'ColonialLiteNavalPlan('
      'priorityNwProvinceIdsSorted: $priorityNwProvinceIdsSorted, '
      'priorityTargetOwnerFactionIdsSorted: $priorityTargetOwnerFactionIdsSorted)';
}

/// Returns the deterministic COLONIAL-lite naval directive for the
/// active player as a [ColonialLiteNavalPlan].
///
/// Contract (issue #2509 § COLONIAL-lite § planColonialLiteNaval):
///
///   "Inputs: Game, AIWorldSnapshot.
///    Returns: List<NavalOrder> (exploration + cargo only).
///
///      → Naval exploration of unrevealed NW sea zones adjacent to
///        visible NW provinces.
///      → Cargo routing (deliver riches to OW stockpile) using
///        existing colonial naval pathing.
///      → Never suggest invasion transport or NW army staging here."
///
/// COLONIAL-lite is the parallel COLONIAL safeguard inside EXPAND scheduled
/// at turn ≥`kObserverColonialLiteMinTurn` with OW ≥`kObserverColonialLiteNearQuotaOw`
/// and below quota, and global `newWorld|` carrying non-GP ownership
/// (issue #2509 § COLONIAL-lite; `SPEC/ai/ai-architecture.md` § COLONIAL-lite).
/// It is the **only** sanctioned exception to EXPAND's total NW
/// suppression and prevents the deadlock where no GP reaches OW = 10
/// and zero NW colonisation ever begins. The orchestrator (#2509 S5) is
/// expected to dispatch this planner only when `observerGoalPhaseFor`
/// resolves to [ObserverGoalPhase.colonialLite]; the function itself does
/// not re-check the phase, matching the convention established by
/// [planColonialLiteOvertures] and the other phase-planner contracts in
/// this module.
///
/// Return type is a directive ([ColonialLiteNavalPlan]) rather than a
/// `List<NavalMoveOrder>` / `List<NavalMissionOrder>` for parity with
/// [planColonialMilitary] / [planExpandMilitary]: the orchestrator owns
/// the actual order envelope (suggestion-API validation, fleet selection,
/// destination resolution via topology) while the planner owns the
/// deterministic decision of **which NW destinations to focus** the
/// existing colonial naval suggestions on this turn. Concretely the
/// orchestrator passes [priorityNwProvinceIdsSorted] to the existing
/// `newWorldSeaZonesAdjacentToInvadableProvinces` /
/// `sortNavalMovesForColonialPressure` helpers in
/// `colonial_naval_scoring.dart` so the ranked candidates already in
/// flight stay sorted by the same colonial-pressure score, just over
/// the COLONIAL-lite restricted province set. The cargo-routing arm in
/// the spec is satisfied at the orchestrator layer by the existing
/// colonial naval pathing the directive does not override (cargo moves
/// out of OW-owned ports toward OW stockpile are unaffected by this
/// NW-only directive).
///
/// Inputs:
///   - [game]: resolves the active player ([Game.playerById]) for the
///     defensive guard and walks the province-owner map
///     ([getProvinceOwnerMap]) to partition
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] by owner
///     faction (drop GP-owned, keep tribe / minor / unowned).
///   - [snapshot]: per-player [AIWorldSnapshot] supplying
///     [ColonialSummary.invadableNewWorldProvinceIdsSorted] (the NW-only
///     candidate pool that the perception-snapshot builder already
///     restricts to provinces visible to the active player).
///
/// Filter pipeline (each stage is structural, not configurable):
///   1. **Missing active player** -> [defaultPlan] (the planner cannot
///      compute a per-player naval directive without an owning
///      [Player]; matches the symmetric guard in [planColonialLiteOvertures]
///      and [planColonialMilitary]).
///   2. **Empty NW invadable** -> [defaultPlan] (structural short-circuit
///      so an empty constraint never leaks to the orchestrator and the
///      orchestrator's free-choice colonial naval pipeline keeps
///      running over its legacy candidate set).
///   3. **GP-owned filter** -> drop any candidate province whose owner
///      resolves to a [Player] via [Game.playerById]. GP-owned NW
///      invadable is structurally excluded because COLONIAL-lite is
///      the safeguard for tribe / minor NW penetration only (the spec
///      explicitly suppresses NW `declareWar` here, and NW
///      declare-war + invasion is the only context for which a GP
///      could legitimately appear as a COLONIAL-lite naval target).
///   4. **Orphan-owner filter** -> drop provinces whose owner does not
///      appear in [getProvinceOwnerMap] (defensive pin for the
///      `if (owner == null) continue` branch).
///   5. **Empty after filter** -> [defaultPlan] (priority-arm
///      fall-through: no tribe / minor faction owns NW invadable, so
///      the orchestrator falls back to its legacy free-choice
///      colonial naval behaviour over the full NW invadable set).
///   6. **Sort ascending** -> deterministic list output (Refs #2509
///      Must-have #7).
///
/// Output:
///   - [ColonialLiteNavalPlan] with the tribe / minor-owned NW invadable
///     provinces sorted ascending in [priorityNwProvinceIdsSorted] and
///     the corresponding owner faction ids sorted ascending and
///     deduplicated in [priorityTargetOwnerFactionIdsSorted] when at
///     least one tribe / minor owns an NW invadable province.
///   - [ColonialLiteNavalPlan.defaultPlan] for the outer guards
///     (missing player, empty NW invadable) and for the priority-arm
///     fall-through (no tribe / minor faction contributes any NW
///     invadable province).
///
/// Structural suppressions: this function reads only
/// [ColonialSummary.invadableNewWorldProvinceIdsSorted] (NW-only by
/// builder contract). It never reads
/// [ConquestSummary.invadableProvinceIdsSorted], so an Old World
/// province cannot appear in the plan even when the snapshot exposes
/// one. The "Never suggest invasion transport or NW army staging here"
/// rule is enforced **structurally** by the absence of any army /
/// transport-staging slot on the plan: the orchestrator wiring is
/// limited to passing [priorityNwProvinceIdsSorted] to the colonial
/// naval helpers in `colonial_naval_scoring.dart`, which emit
/// exploration / cargo moves only. Adding a transport-staging slot
/// would be a breaking SPEC change; this slice deliberately keeps the
/// plan shape minimal so no caller can backslide into invasion-style
/// orders under the COLONIAL-lite label.
///
/// The function is pure and deterministic — identical inputs always
/// yield identical [ColonialLiteNavalPlan]s (Refs #2509 Must-have #7).
ColonialLiteNavalPlan planColonialLiteNaval({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (game.playerById(snapshot.playerId) == null) {
    return ColonialLiteNavalPlan.defaultPlan;
  }
  final invadable = snapshot.colonial.invadableNewWorldProvinceIdsSorted;
  if (invadable.isEmpty) {
    return ColonialLiteNavalPlan.defaultPlan;
  }

  final provinceOwner = getProvinceOwnerMap(game);
  final priorityProvinces = <String>[];
  final priorityOwners = <String>{};
  for (final pid in invadable) {
    final owner = provinceOwner[pid];
    if (owner == null) continue;
    if (game.playerById(owner) != null) continue;
    priorityProvinces.add(pid);
    priorityOwners.add(owner);
  }
  if (priorityProvinces.isEmpty) {
    return ColonialLiteNavalPlan.defaultPlan;
  }
  priorityProvinces.sort();
  final owners = priorityOwners.toList()..sort();
  return ColonialLiteNavalPlan(
    priorityNwProvinceIdsSorted: List<String>.unmodifiable(priorityProvinces),
    priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(owners),
  );
}
