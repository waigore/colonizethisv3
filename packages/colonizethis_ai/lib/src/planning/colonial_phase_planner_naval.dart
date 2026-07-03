part of 'colonial_phase_planner.dart';

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
  })  : _priorityInvasionTransportProvinceIdsSorted =
            priorityInvasionTransportProvinceIdsSorted,
        _priorityTargetOwnerFactionIdsSorted =
            priorityTargetOwnerFactionIdsSorted;

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

  final List<String> _priorityInvasionTransportProvinceIdsSorted;
  final List<String> _priorityTargetOwnerFactionIdsSorted;

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
      _priorityInvasionTransportProvinceIdsSorted;

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
      _priorityTargetOwnerFactionIdsSorted;

  @override
  List<String> get priorityProvinceIdsSorted =>
      _priorityInvasionTransportProvinceIdsSorted;

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
  expand_phase_planner.ExpandEconomyPlan expandEconomyPlan =
      expand_phase_planner.ExpandEconomyPlan.defaultPlan,
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
  })  : _priorityNwProvinceIdsSorted = priorityNwProvinceIdsSorted,
        _priorityTargetOwnerFactionIdsSorted =
            priorityTargetOwnerFactionIdsSorted;

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

  final List<String> _priorityNwProvinceIdsSorted;
  final List<String> _priorityTargetOwnerFactionIdsSorted;

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
  List<String> get priorityNwProvinceIdsSorted => _priorityNwProvinceIdsSorted;

  /// Faction ids of the tribes / minor nations owning the provinces
  /// in [priorityNwProvinceIdsSorted]. Sorted ascending and
  /// deduplicated. Never includes any Great Power id -- GPs are
  /// structurally excluded by [planColonialLiteNaval] because
  /// COLONIAL-lite is the safeguard for **tribe / minor** NW
  /// penetration only (issue #2509 § COLONIAL-lite "establishOverture
  /// toward visible NW tribe / minor owners"). Empty for [defaultPlan].
  @override
  List<String> get priorityTargetOwnerFactionIdsSorted =>
      _priorityTargetOwnerFactionIdsSorted;

  @override
  List<String> get priorityProvinceIdsSorted => _priorityNwProvinceIdsSorted;

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

/// Returns deterministic `build_improvement` work orders for the active
/// player's idle Builder units, ranked by extractable-tile priority and
/// restricted to **New World** owned land for COLONIAL phase.
///
/// Contract (issue #2509 § COLONIAL phase planner § planColonialCivilian,
/// also Suppressions § "No OW build_improvement except tiles needed for
/// port/supply to active NW objectives"):
///
///   "Returns: List<WorkOrder> (NW purchase_land, NW improvements)."
///
/// This slice covers the **NW improvements** half of that contract.
/// `purchase_land` toward unowned NW tiles is the responsibility of
/// [planColonialAcquisition]. The narrow OW
/// port/supply allowance noted in the spec ("except tiles needed for
/// port/supply to active NW objectives") is also deferred — no
/// orchestrator caller consumes the planner on the landed post-S5
/// dispatch path, and tightening that exception requires the
/// orchestrator's active-NW-objective set which lives in
/// `planColonialAcquisition` / `planColonialMilitary` (neither in
/// place today). Suppressing OW improvements unconditionally here is
/// the structural COLONIAL-phase default the spec mandates; the
/// follow-up slice will broaden the gate when active-NW-objective
/// state becomes available.
///
/// Filtering (structural gates from issue #2509 COLONIAL planner spec):
///   1. Province must be in the **New World** region
///      ([Province.regionId] == [kNewWorldRegionId]).
///   2. Province must be owned by the active player
///      ([AIWorldSnapshot.playerId]).
///   3. Tile must carry a non-empty resource id in
///      [WorldState.resourceByTileKey] (extractable resource tile).
///   4. Tile must not be the province's town tile
///      ([Province.townTileKey]); town and capital tiles do not carry
///      resources per `SPEC/game/extraction-and-improvements.md`
///      § Town and capital tile occupancy, but the explicit exclusion
///      pins the contract against future model changes (mirrors the
///      pin in `planDevelopCivilian`).
///   5. Tile's existing improvement level
///      ([TileMapState.improvementLevel]) must be `< 1`.
///
/// Ranking (deterministic; ties broken lexicographically by tile key):
///   - Base score per extractable tile:
///     `kBuildImprovementExtractableResourceScore`.
///   - `+kBuildImprovementNewWorldResourceBonus` (always present here
///     because every eligible tile is in the NW region by gate #1).
///   - `+kBuildImprovementOwnedNewWorldResourceBonus` (always present
///     here because every eligible tile is on owned NW land by gate
///     #2). The orchestrator-facing score is therefore uniform across
///     eligible tiles; the planner falls back to lex tile-key tie-break
///     for deterministic ordering. The score constants are kept in the
///     ranking key (rather than collapsing to a single constant) so the
///     COLONIAL planner remains consistent with `planDevelopCivilian`
///     should later tuning introduce additional NW-only bonuses.
///
/// Builder selection: every active-player [Unit] with
/// `type == kUnitTypeBuilder` and `status == UnitStatus.idle` is included
/// regardless of current region — a Builder in the Old World can still
/// be assigned to a NW improvement directive; the orchestrator and
/// resolver handle the movement / staging on subsequent turns. Builders
/// are sorted ascending by `unit.id` and paired one-to-one with the
/// top-priority eligible tiles
/// (`pairCount = min(idleBuilders, eligibleTiles)`). Distance-aware
/// pairing is deferred to follow-up tuning under #2509 S5 (orchestrator
/// wiring) / S7 (observer integration), matching the convention
/// established by `planDevelopCivilian`.
///
/// Output: a new `List<WorkOrder>` of at most
/// `min(idleBuilders, eligibleNwTiles)` entries, each with
/// `target == kWorkTargetBuildImprovement`. Empty when no idle Builders,
/// no owned NW provinces, or no eligible NW resource tiles exist. The
/// function is pure and deterministic — identical inputs always yield
/// identical lists (Refs #2509 Must-have #7).
List<WorkOrder> planColonialCivilian({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final playerId = snapshot.playerId;
  final world = game.worldState;

  final ownedNwProvinceIds = <String>{};
  final townTileKeys = <String>{};
  for (final province in ProvinceOwnerCache.of(
    world,
  ).provincesOwnedByInRegion(playerId, kRegionNewWorld)) {
    ownedNwProvinceIds.add(province.id);
    final townTileKey = province.townTileKey;
    if (townTileKey != null && townTileKey.isNotEmpty) {
      townTileKeys.add(townTileKey);
    }
  }
  if (ownedNwProvinceIds.isEmpty) {
    return const [];
  }

  final builders = <Unit>[
    for (final unit in allUnitsFromWorld(world))
      if (unit.ownerId == playerId &&
          unit.type == kUnitTypeBuilder &&
          unit.status == UnitStatus.idle)
        unit,
  ]..sort((a, b) => a.id.compareTo(b.id));
  if (builders.isEmpty) {
    return const [];
  }

  final tileState = world.tileState;
  final eligibleTileKeys = <String>[];
  for (final entry in world.resourceByTileKey.entries) {
    final tileKey = entry.key;
    final resourceId = entry.value;
    if (resourceId.isEmpty) continue;
    if (Unit.regionIdFromTileKey(tileKey) != kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(tileKey);
    if (provinceId == null || !ownedNwProvinceIds.contains(provinceId)) {
      continue;
    }
    if (townTileKeys.contains(tileKey)) continue;
    if (tileState.improvementLevel(tileKey) >= 1) continue;
    eligibleTileKeys.add(tileKey);
  }
  if (eligibleTileKeys.isEmpty) {
    return const [];
  }

  eligibleTileKeys.sort((a, b) {
    final scoreCmp = _colonialCivilianTileScore(
      b,
    ).compareTo(_colonialCivilianTileScore(a));
    if (scoreCmp != 0) return scoreCmp;
    return a.compareTo(b);
  });

  final pairCount = eligibleTileKeys.length < builders.length
      ? eligibleTileKeys.length
      : builders.length;
  return <WorkOrder>[
    for (var i = 0; i < pairCount; i++)
      WorkOrder(
        unitId: builders[i].id,
        target: kWorkTargetBuildImprovement,
        targetTileKey: eligibleTileKeys[i],
      ),
  ];
}

/// Deterministic priority score for an eligible NW tile in
/// [planColonialCivilian].
///
/// Every tile that survives the structural gates in [planColonialCivilian]
/// is NW + owned-NW by construction, so this score collapses to a single
/// constant in the current implementation. Keeping the additive form
/// (rather than inlining a literal) preserves consistency with the
/// per-tile component of `_developCivilianTileScore` and stays robust
/// against future ranking tweaks that introduce per-tile NW differentiators.
int _colonialCivilianTileScore(String tileKey) {
  // Tile is structurally NW + owned-NW once we reach this comparator
  // (see eligibility gates 1 and 2 in [planColonialCivilian]); the
  // bonus additions are explicit so the score formula stays parallel
  // to `_developCivilianTileScore` in `develop_phase_planner.dart`.
  return kBuildImprovementExtractableResourceScore +
      kBuildImprovementNewWorldResourceBonus +
      kBuildImprovementOwnedNewWorldResourceBonus;
}
