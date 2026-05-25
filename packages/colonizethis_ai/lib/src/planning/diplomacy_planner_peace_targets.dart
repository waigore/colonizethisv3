import '../perception/perception_snapshot.dart';
import 'army_conquest_prep.dart';
import 'planning_imports.dart';
import 'colonial_pressure.dart';
import 'expand_phase_planner.dart' as expand_phase_planner;
import 'observer_goal_phase.dart';

/// Strongest at-war GP that owns invadable OW provinces while this GP is stalled.
String? stalledStrongerGpBlockerPeaceTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return null;
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return null;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any((
    pid,
  ) {
    final owner = provinceOwner[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (!minorsOwnInvadable && !gpBlockerFocus) {
    return null;
  }
  if (gpBlockerFocus) {
    final anyMinorOwnsOw = game.worldState.oldWorld.provinces.any(
      (p) =>
          p.ownerId != null &&
          p.ownerId!.isNotEmpty &&
          game.minorNations.any((m) => m.id == p.ownerId),
    );
    if (!anyMinorOwnsOw) {
      return null;
    }
  }
  final primaryBlocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  String? bestFactionId;
  var bestLead = 0;
  for (final factionId in snapshot.threats.atWarWith) {
    if (game.playerById(factionId) == null) continue;
    if (factionId == primaryBlocker) continue;
    final ownsInvadable = snapshot.conquest.invadableProvinceIdsSorted.any(
      (pid) => provinceOwner[pid] == factionId,
    );
    if (!ownsInvadable) continue;
    final lead =
        provinceCountOwnedBy(game, factionId) -
        snapshot.conquest.oldWorldProvincesOwned;
    if (lead <= 0) continue;
    if (lead > bestLead) {
      bestLead = lead;
      bestFactionId = factionId;
    }
  }
  return bestFactionId;
}

/// Factions at war with this GP to peace while a single GP owns the invadable OW
/// frontier (minors, tribes, and other GPs are distractions; Refs #2509).
List<String> stalledGpBlockerFocusPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any((
    pid,
  ) {
    final owner = provinceOwner[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
  final gpWars = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.playerById(factionId) != null) factionId,
  ];
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null) {
    return const [];
  }
  if (minorsOwnInvadable && gpWars.length <= 1) {
    // Sole GP war on a mixed frontier must still drop non-blocker fronts
    // (seed-42 gp4/gp5 vs gp3 blocker; Refs #2509).
    if (gpWars.length == 1 && gpWars.single != blocker) {
      return [gpWars.single];
    }
    return const [];
  }
  if (minorsOwnInvadable) {
    final targets = <String>[
      for (final factionId in gpWars)
        if (factionId != blocker) factionId,
    ]..sort();
    return targets;
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (factionId != blocker) factionId,
  ]..sort();
  return targets;
}

/// At-war Great Powers that own none of this GP's invadable Old World provinces
/// while minors still hold invadable land (distracting GP wars; Refs #2509).
///
/// Delegates to [expand_phase_planner.stalledFutileGpPeaceTargets]
/// (Refs #2509 S1) so the EXPAND-phase futile-GP peace decider survives
/// the planned deletion of this file alongside the canonical
/// [expand_phase_planner.isOldWorldGpOnlyInvadableFrontier] band selector
/// it composes with through the [getProvinceOwnerMap]-shared
/// `minorsOwnInvadable` precondition scan.
List<String> stalledFutileGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.stalledFutileGpPeaceTargets(
  game: game,
  snapshot: snapshot,
);

bool _isMinorOrTribeFaction(Game game, String factionId) =>
    game.minorNations.any((m) => m.id == factionId) ||
    game.tribes.any((t) => t.id == factionId);

/// At-war minor with the most invadable Old World provinces (single-front focus).
///
/// Delegates to [expand_phase_planner.stalledFocusMinorTarget]
/// (Refs #2509 S1) so the EXPAND-phase focused-minor target identifier
/// survives the planned deletion of this file alongside its
/// [belowQuotaActiveMinorWarTarget] gate-wrapper sibling and the
/// `stalledExpansionDistractionPeaceTargets` /
/// `belowQuotaMultiMinorDistractionPeaceTargets` consumer chain that
/// pivot off the focused-minor identity.
String? stalledFocusMinorTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.stalledFocusMinorTarget(
  game: game,
  snapshot: snapshot,
);

/// Active at-war minor front while below the observer quota (seed-42 gp4).
///
/// Delegates to [expand_phase_planner.belowQuotaActiveMinorWarTarget]
/// (Refs #2509 S1) so the EXPAND-phase below-quota minor-front gate
/// survives the planned deletion of this file alongside the canonical
/// [expand_phase_planner.stalledFocusMinorTarget] helper it composes.
String? belowQuotaActiveMinorWarTarget({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.belowQuotaActiveMinorWarTarget(
  game: game,
  snapshot: snapshot,
);

/// Peace tribe wars while fighting a Great Power (OW consolidation; Refs #2509).
///
/// Delegates to [expand_phase_planner.atWarGpDistractionTribePeaceTargets]
/// (Refs #2509 S1) so the EXPAND-phase GP-distraction tribe peace
/// decider survives the planned deletion of this file alongside its
/// `_expandRatchetGreatPowerPeaceTargets` /
/// `collectStalledGreatPowerPeaceTargets` consumer chains.
List<String> atWarGpDistractionTribePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.atWarGpDistractionTribePeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace every at-war minor/tribe except the focused minor or GP blocker war.
List<String> stalledExpansionDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isStalledOldWorldExpansion(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  if (snapshot.threats.atWarWith.isEmpty) {
    return const [];
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final minorsOwnInvadable = snapshot.conquest.invadableProvinceIdsSorted.any((
    pid,
  ) {
    final owner = provinceOwner[pid];
    return owner != null && game.minorNations.any((m) => m.id == owner);
  });
  final gpBlockerFocus = isStalledOldWorldGpBlockerFocus(
    game: game,
    snapshot: snapshot,
  );
  if (!minorsOwnInvadable && !gpBlockerFocus) {
    return const [];
  }
  final keepMinor = minorsOwnInvadable
      ? stalledFocusMinorTarget(game: game, snapshot: snapshot)
      : null;
  final keepGp = gpBlockerFocus
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (factionId != keepMinor &&
          factionId != keepGp &&
          _isMinorOrTribeFaction(game, factionId))
        factionId,
  ]..sort();
  return targets;
}

/// When OW holdings are critically low (≤6), peace every stronger at-war GP (Refs #2509).
///
/// Delegates to [expand_phase_planner.criticalWeakGpSurvivalPeaceTargets]
/// (Refs #2509 S1) so the EXPAND-phase critical-survival peace decider
/// survives the planned deletion of this file alongside the canonical
/// sibling survival deciders ([expand_phase_planner.stalledZeroRegimentGpPeaceTargets],
/// [expand_phase_planner.stalledZeroRegimentAllFactionPeaceTargets],
/// [expand_phase_planner.mutualZeroRegimentGpStalematePeaceTargets],
/// [expand_phase_planner.mutualExhaustedBelowQuotaGpStalematePeaceTargets]).
/// Retained here as a thin stub for the legacy
/// `diplomacy_planner_mutual_exhausted_peace_test.dart` and
/// `diplomacy_planner_stalled_peace_test.dart` fixtures and the in-file
/// `_survivalGreatPowerPeaceTargets` / `stalledOwExpansionNeedsPeacePass`
/// consumer chains until the planned S1 deletion of this file.
List<String> criticalWeakGpSurvivalPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.criticalWeakGpSurvivalPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace the invadable OW frontier GP while critically weak and outmatched
/// (pivot to minors/tribes instead of unwinnable GP wars; Refs #2509).
List<String> weakHoldingsInvadableBlockerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final zeroRegiments = regimentCountForPlayer(game, snapshot.playerId) == 0;
  final belowQuota = isBelowObserverConquestQuota(
    snapshot.conquest.oldWorldProvincesOwned,
  );
  if (snapshot.conquest.oldWorldProvincesOwned >
          kFewOldWorldProvincesDefendThreshold &&
      !belowQuota &&
      !(zeroRegiments &&
          isStalledOldWorldExpansion(
            snapshot.conquest.oldWorldProvincesOwned,
          ))) {
    return const [];
  }
  if (isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)) {
    return const [];
  }
  final blocker = primaryInvadableOldWorldGpBlocker(
    game: game,
    snapshot: snapshot,
  );
  if (blocker == null ||
      !snapshot.threats.atWarWith.contains(blocker) ||
      game.playerById(blocker) == null) {
    return const [];
  }
  final lead =
      provinceCountOwnedBy(game, blocker) -
      snapshot.conquest.oldWorldProvincesOwned;
  final minLead = belowQuota
      ? (snapshot.conquest.oldWorldProvincesOwned <=
                kObserverDefaultStartOldWorldProvincesPerGp + 2
            ? 1
            : kUnwinnableSoleGpMinProvinceDeficit)
      : kDeclareWarAggressorSuppressWeakGpLeadThreshold;
  if (lead < minLead) {
    return const [];
  }
  return [blocker];
}

/// When OW holdings are critically low, peace non-blocker Great Power fronts only
/// (avoid total collapse from multi-front GP wars; Refs #2509).
///
/// Delegates to [expand_phase_planner.criticalMultiFrontGpPeaceTargets]
/// (Refs #2509 S1) so the EXPAND-phase critical multi-front peace
/// decider survives the planned deletion of this file alongside the
/// canonical [expand_phase_planner.multiFrontNonBlockerGpPeaceTargets]
/// helper it composes. Retained here as a thin stub for the legacy
/// `diplomacy_planner_below_quota_peace_part3_test.dart` and
/// `diplomacy_planner_stalled_peace_test.dart` fixtures and the in-file
/// `_expandRatchetGreatPowerPeaceTargets` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains until the planned
/// S1 deletion of this file.
List<String> criticalMultiFrontGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.criticalMultiFrontGpPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Below-quota GPs with too few regiments to split across multiple minor wars:
/// peace every at-war minor except the focused invadable frontier (Refs #2509).
List<String> belowQuotaMultiMinorDistractionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  if (!isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned)) {
    return const [];
  }
  final regimentCount = regimentCountForPlayer(game, snapshot.playerId);
  if (regimentCount <= 0 ||
      regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
    return const [];
  }
  if (snapshot.conquest.invadableProvinceIdsSorted.isEmpty) {
    return const [];
  }
  final focus = stalledFocusMinorTarget(game: game, snapshot: snapshot);
  if (focus == null) {
    return const [];
  }
  final targets = <String>[
    for (final factionId in snapshot.threats.atWarWith)
      if (game.minorNations.any((m) => m.id == factionId) && factionId != focus)
        factionId,
  ]..sort();
  return targets;
}

/// Peace every at-war minor/tribe when stalled below quota with zero regiments.
///
/// Delegates to [expand_phase_planner.stalledZeroRegimentAllFactionPeaceTargets]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// EXPAND zero-regiment survival arm. Retained here as a thin stub for
/// the legacy `diplomacy_planner_below_quota_peace_part3_test.dart`
/// fixture and the in-file `_survivalGreatPowerPeaceTargets` consumer
/// chain until the planned S1 deletion of this file.
List<String> stalledZeroRegimentAllFactionPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.stalledZeroRegimentAllFactionPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace every at-war Great Power when stalled with zero regiments (Refs #2509).
///
/// Delegates to [expand_phase_planner.stalledZeroRegimentGpPeaceTargets]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// EXPAND zero-regiment survival arm. Retained here as a thin stub for
/// the legacy `diplomacy_planner_below_quota_peace_part3_test.dart`
/// fixture and the in-file `_survivalGreatPowerPeaceTargets` /
/// `collectStalledGreatPowerPeaceTargets` / `stalledOwExpansionNeedsPeacePass`
/// consumer chains until the planned S1 deletion of this file.
List<String> stalledZeroRegimentGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.stalledZeroRegimentGpPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace a sole GP enemy when both sides have zero regiments (stalemate reset).
///
/// Delegates to [expand_phase_planner.mutualZeroRegimentGpStalematePeaceTargets]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// EXPAND zero-regiment mutual-stalemate arm. Retained here as a thin
/// stub for the in-file `_survivalGreatPowerPeaceTargets` /
/// `collectStalledGreatPowerPeaceTargets` `zeroRegimentBlockerPeace` /
/// `stalledOwExpansionNeedsPeacePass` consumer chains until the planned
/// S1 deletion of this file.
List<String> mutualZeroRegimentGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.mutualZeroRegimentGpStalematePeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Peace the sole at-war GP when both sides are mutual-plateau peers below
/// quota and mutually exhausted in regiments and treasury (Refs #2509).
///
/// Delegates to
/// [expand_phase_planner.mutualExhaustedBelowQuotaGpStalematePeaceTargets]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// EXPAND mutually-exhausted stalemate arm. Retained here as a thin stub
/// for the legacy `diplomacy_planner_mutual_exhausted_peace_test.dart`
/// fixture and the in-file `_survivalGreatPowerPeaceTargets` consumer
/// chain until the planned S1 deletion of this file.
List<String> mutualExhaustedBelowQuotaGpStalematePeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.mutualExhaustedBelowQuotaGpStalematePeaceTargets(
  game: game,
  snapshot: snapshot,
);

bool stalledOwExpansionNeedsPeacePass({
  required Game game,
  required AIWorldSnapshot snapshot,
}) =>
    stalledStrongerGpBlockerPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    stalledFutileGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledGpBlockerFocusPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledExpansionDistractionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    atWarGpDistractionTribePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    multiFrontNonBlockerGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalMultiFrontGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalWeakGpSurvivalPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    weakHoldingsInvadableBlockerPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    mutualZeroRegimentGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledZeroRegimentAllFactionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    stalledZeroRegimentGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    mutualExhaustedBelowQuotaGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    criticalOwHoldPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    stalledBelowQuotaGpLeadPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    defaultStartGpPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    defaultStartFutileMinorPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot).isNotEmpty ||
    quotaMetBelowQuotaAtWarPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    quotaMetFutileBelowQuotaGpPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).isNotEmpty ||
    unwinnableSoleGpFrontierPeaceTarget(game: game, snapshot: snapshot) !=
        null ||
    consolidateGainsSoleGpPeaceTarget(game: game, snapshot: snapshot) != null;

/// When fighting 2+ Great Powers, peace every non-blocker GP. Also peace a sole
/// non-blocker GP war while invadable OW remains (Refs #2509).
///
/// Delegates to [expand_phase_planner.multiFrontNonBlockerGpPeaceTargets]
/// (Refs #2509 S1) so the canonical implementation lives alongside the
/// other EXPAND multi-front / non-blocker peace deciders. Retained here
/// as a thin stub for the legacy `multi_front_peace_targets_test.dart`
/// fixture and the `stalledOwExpansionNeedsPeacePass` consumer chain
/// until the planned S1 deletion of this file.
List<String> multiFrontNonBlockerGpPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) => expand_phase_planner.multiFrontNonBlockerGpPeaceTargets(
  game: game,
  snapshot: snapshot,
);

/// Critical collapse / zero-regiment peace (all observer phases).
Iterable<String> _survivalGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) sync* {
  yield* criticalWeakGpSurvivalPeaceTargets(game: game, snapshot: snapshot);
  yield* stalledZeroRegimentAllFactionPeaceTargets(
    game: game,
    snapshot: snapshot,
  );
  yield* mutualZeroRegimentGpStalematePeaceTargets(
    game: game,
    snapshot: snapshot,
  );
  yield* stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot);
  yield* mutualExhaustedBelowQuotaGpStalematePeaceTargets(
    game: game,
    snapshot: snapshot,
  );
}

/// Legacy OW-expansion scoring ratchet peace (EXPAND / COLONIAL-lite only; Refs #2509 S10).
Iterable<String> _expandRatchetGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) sync* {
  yield* stalledFutileGpPeaceTargets(game: game, snapshot: snapshot);
  yield* stalledGpBlockerFocusPeaceTargets(game: game, snapshot: snapshot);
  yield* stalledExpansionDistractionPeaceTargets(
    game: game,
    snapshot: snapshot,
  );
  yield* multiFrontNonBlockerGpPeaceTargets(game: game, snapshot: snapshot);
  yield* criticalMultiFrontGpPeaceTargets(game: game, snapshot: snapshot);
  yield* weakHoldingsInvadableBlockerPeaceTargets(
    game: game,
    snapshot: snapshot,
  );
  final strongerBlocker = stalledStrongerGpBlockerPeaceTarget(
    game: game,
    snapshot: snapshot,
  );
  if (strongerBlocker != null) {
    yield strongerBlocker;
  }
  yield* criticalOwHoldPeaceTargets(game: game, snapshot: snapshot);
  yield* stalledBelowQuotaGpLeadPeaceTargets(game: game, snapshot: snapshot);
  yield* belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot);
  yield* defaultStartGpPeaceTargets(game: game, snapshot: snapshot);
  yield* defaultStartFutileMinorPeaceTargets(game: game, snapshot: snapshot);
  yield* nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot);
  yield* quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot);
  yield* quotaMetFutileBelowQuotaGpPeaceTargets(game: game, snapshot: snapshot);
  final unwinnable = unwinnableSoleGpFrontierPeaceTarget(
    game: game,
    snapshot: snapshot,
  );
  if (unwinnable != null) {
    yield unwinnable;
  }
  final consolidate = consolidateGainsSoleGpPeaceTarget(
    game: game,
    snapshot: snapshot,
  );
  if (consolidate != null) {
    yield consolidate;
  }
}

/// Great Power peace targets from observer phase rules and stalled expansion helpers.
Set<String> collectStalledGreatPowerPeaceTargets({
  required Game game,
  required AIWorldSnapshot snapshot,
}) {
  final phase = observerGoalPhaseFor(snapshot: snapshot, game: game);
  final phaseRatchetPeace = switch (phase) {
    ObserverGoalPhase.develop => const <String>[],
    ObserverGoalPhase.colonial => atWarGpDistractionTribePeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
    ObserverGoalPhase.expand ||
    ObserverGoalPhase.colonialLite => _expandRatchetGreatPowerPeaceTargets(
      game: game,
      snapshot: snapshot,
    ).toList(),
  };
  final targets = <String>{
    ...developPhaseGpPeaceTargets(game: game, snapshot: snapshot),
    ...colonialPhaseGpPeaceTargets(game: game, snapshot: snapshot),
    ...expandPhaseGpPeaceTargets(game: game, snapshot: snapshot),
    ..._survivalGreatPowerPeaceTargets(game: game, snapshot: snapshot),
    ...phaseRatchetPeace,
  };
  final invadableBlocker =
      isBelowObserverConquestQuota(snapshot.conquest.oldWorldProvincesOwned) &&
          isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot)
      ? primaryInvadableOldWorldGpBlocker(game: game, snapshot: snapshot)
      : null;
  final unwinnableBlockerPeace = unwinnableSoleGpFrontierPeaceTarget(
    game: game,
    snapshot: snapshot,
  );
  final preserveBlockerPeace = <String>{
    if (!isOldWorldGpOnlyInvadableFrontier(game: game, snapshot: snapshot))
      ...weakHoldingsInvadableBlockerPeaceTargets(
        game: game,
        snapshot: snapshot,
      ),
    if (unwinnableBlockerPeace != null) unwinnableBlockerPeace,
    ...quotaMetBelowQuotaAtWarPeaceTargets(game: game, snapshot: snapshot),
    ...belowQuotaPeerGpPeaceTargets(game: game, snapshot: snapshot),
    if (snapshot.conquest.oldWorldProvincesOwned >=
        kObserverDefaultStartOldWorldProvincesPerGp)
      ...defaultStartGpPeaceTargets(game: game, snapshot: snapshot),
    ...nearQuotaHoldPeaceTargets(game: game, snapshot: snapshot),
  };
  // Zero-regiment stalemates must peace the sole GP blocker even on a GP-only
  // frontier; otherwise broke mutual-plateau pairs stay at war with no armies
  // (observer seed-42 gp3/gp4; Refs #2509). The mutually-exhausted variant
  // covers the same stalemate at non-zero but critically low regiment counts
  // (3-regiment 0-treasury plateau) when no minor pivot remains.
  final zeroRegimentBlockerPeace = <String>{
    ...mutualZeroRegimentGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
    ...stalledZeroRegimentGpPeaceTargets(game: game, snapshot: snapshot),
    ...mutualExhaustedBelowQuotaGpStalematePeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
  };
  final greatPowerPeace = targets
      .where(
        (id) =>
            game.playerById(id) != null &&
            (id != invadableBlocker ||
                preserveBlockerPeace.contains(id) ||
                zeroRegimentBlockerPeace.contains(id)),
      )
      .toSet();
  final minorTribePeace = <String>{
    ...belowQuotaMultiMinorDistractionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
    ...stalledZeroRegimentAllFactionPeaceTargets(
      game: game,
      snapshot: snapshot,
    ),
  }.where((id) => game.playerById(id) == null);
  return {...greatPowerPeace, ...minorTribePeace};
}

/// GP–GP peace requires both sides to [offerPeace] in the same phase; mirror existing offers.
Orders supplementMutualStalledGreatPowerPeaceOrders({
  required Game game,
  required MapTopology topology,
  required Orders orders,
}) {
  final diplo = Map<String, List<DiplomaticOrder>>.from(
    orders.diplomaticOrdersByPlayerId,
  );
  var changed = false;
  for (final entry in orders.diplomaticOrdersByPlayerId.entries) {
    final fromGp = entry.key;
    if (!isAiControlled(game, fromGp)) continue;
    for (final order in entry.value) {
      if (order.type != DiplomaticOrderType.offerPeace) continue;
      final toGp = order.targetFactionId;
      if (game.playerById(toGp) == null || !isAiControlled(game, toGp)) {
        continue;
      }
      final fromView = buildPlayerView(game, topology, fromGp);
      final fromSnapshot = AIWorldSnapshot.fromPlayerView(
        fromView,
        topology: topology,
      );
      final invadableBlocker = primaryInvadableOldWorldGpBlocker(
        game: game,
        snapshot: fromSnapshot,
      );
      final stalledPeaceTargets = collectStalledGreatPowerPeaceTargets(
        game: game,
        snapshot: fromSnapshot,
      );
      if (toGp == invadableBlocker && !stalledPeaceTargets.contains(toGp)) {
        continue;
      }
      final before = diplo[toGp]?.length ?? 0;
      _appendOfferPeaceIfMissing(diplo, toGp, fromGp);
      if ((diplo[toGp]?.length ?? 0) > before) {
        changed = true;
      }
    }
  }
  if (!changed) {
    return orders;
  }
  return orders.copyWith(diplomaticOrdersByPlayerId: diplo);
}

void _appendOfferPeaceIfMissing(
  Map<String, List<DiplomaticOrder>> diplo,
  String fromGp,
  String toGp,
) {
  final existing = diplo[fromGp] ?? const [];
  if (existing.any(
    (o) =>
        o.type == DiplomaticOrderType.offerPeace && o.targetFactionId == toGp,
  )) {
    return;
  }
  diplo[fromGp] = [
    ...existing,
    DiplomaticOrder(
      type: DiplomaticOrderType.offerPeace,
      targetFactionId: toGp,
    ),
  ];
}
