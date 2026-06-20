import 'package:colonizethis_data/colonizethis_data.dart';
import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'economy_debt_rules.dart';
import 'economy_tech_effects.dart';
import 'research_rules.dart';

({Game state, Player updated}) _applyResearchUnlockSideEffects({
  required Game state,
  required Player player,
  required List<String> toUnlock,
  required int turn,
  required List<DossierEvidenceEntry> extraEvidence,
}) {
  var nextState = state;
  for (final techId in toUnlock) {
    final techMeta = techById(techId);
    final cat = techMeta?.category;
    if (cat != null && cat.isNotEmpty && player.isHuman) {
      nextState = nextState.copyWith(
        lastHumanCompletedResearchCategory: cat,
        lastHumanResearchCategoryCompletionTurn: turn,
      );
    }
  }
  for (final techId in toUnlock) {
    final techMeta = techById(techId);
    final cat = techMeta?.category;
    if (cat != null &&
        cat.isNotEmpty &&
        !player.isHuman &&
        isAiControlledForEvidence(nextState, player.id)) {
      extraEvidence.addAll(
        evidenceForEnvyResearchMirror(
          nextState,
          player.id,
          cat,
          turn,
          extraEvidence,
        ),
      );
    }
  }
  return (state: nextState, updated: player);
}

bool _researchPrerequisitesMet(
  TechDefinition tech,
  Map<String, bool> originalUnlocked,
) {
  for (final pre in tech.prerequisiteIds) {
    if (originalUnlocked[pre] != true) return false;
  }
  return true;
}

bool _researchDiscoverySatisfied(
  Game game,
  String playerId,
  TechDefinition tech,
) {
  final discoveryIds = tech.discoveryResourceIds;
  if (discoveryIds == null || discoveryIds.isEmpty) return true;
  for (final r in discoveryIds) {
    if (hasRevealedResourceForPlayer(game, playerId, r)) return true;
  }
  return false;
}

/// Mutable per-player accumulator for one research-phase allocation pass.
///
/// Bundles the immutable inputs ([game], [player], [slots], [originalUnlocked],
/// [maxDebt]) with the state mutated while applying each [ResearchOrder]
/// ([treasury] and [progress]). Replaces the prior treasury getter/setter
/// parameter pair so [_applyResearchOrderIfValid] threads a single value.
class _ResearchAllocationContext {
  _ResearchAllocationContext({
    required this.game,
    required this.player,
    required this.slots,
    required this.originalUnlocked,
    required this.progress,
    required this.maxDebt,
    required this.treasury,
  });

  final Game game;
  final Player player;
  final int slots;
  final Map<String, bool> originalUnlocked;
  final Map<String, int> progress;
  final int maxDebt;
  int treasury;
}

/// True when [techId] can occupy [slotIndex] given [slots] research slots: the
/// slot index is in `0..slots-1`, the tech id is non-empty, and the tech exists
/// in the catalog. SPEC/program/research-resolution.md § Slot occupancy
/// persistence (catalog-aware reconciliation).
bool _isResearchableSlotAssignment(int slotIndex, String techId, int slots) {
  if (slotIndex < 0 || slotIndex >= slots) return false;
  if (techId.isEmpty) return false;
  return techById(techId) != null;
}

/// Builds the effective per-slot occupancy for one resolution pass.
///
/// Starts from the player's persisted [Player.researchSlotAssignments] (each
/// entry validated against the catalog and `0..slots-1` bounds) and applies this
/// turn's [playerOrders] as the UI mutation surface: a non-empty order
/// assigns/updates the slot's tech and funding; an empty-techId order cancels
/// (frees) the slot. SPEC/program/research-resolution.md § Slot occupancy
/// persistence.
Map<int, ResearchSlotAssignment> _effectiveSlotAssignments({
  required Player player,
  required List<ResearchOrder> playerOrders,
  required int slots,
}) {
  final effective = <int, ResearchSlotAssignment>{};
  final persisted = player.researchSlotAssignments;
  if (persisted != null) {
    for (final entry in persisted.entries) {
      if (_isResearchableSlotAssignment(entry.key, entry.value.techId, slots)) {
        effective[entry.key] = entry.value;
      }
    }
  }
  // One order per slot: last in the merged list wins.
  final orderBySlot = <int, ResearchOrder>{};
  for (final order in playerOrders) {
    orderBySlot[order.slotIndex] = order;
  }
  for (final entry in orderBySlot.entries) {
    final slotIndex = entry.key;
    if (slotIndex < 0 || slotIndex >= slots) continue;
    final order = entry.value;
    if (order.techId.isEmpty) {
      effective.remove(slotIndex);
      continue;
    }
    if (techById(order.techId) == null) continue;
    effective[slotIndex] = ResearchSlotAssignment(
      techId: order.techId,
      funding: order.funding,
    );
  }
  return effective;
}

void _applyResearchOrderIfValid(
  _ResearchAllocationContext ctx,
  ResearchOrder order,
) {
  if (order.slotIndex < 0 || order.slotIndex >= ctx.slots) return;
  final techId = order.techId;
  if (techId.isEmpty) return;

  final tech = techById(techId);
  if (tech == null) return;
  if (ctx.originalUnlocked[techId] == true) return;
  if (!_researchPrerequisitesMet(tech, ctx.originalUnlocked)) return;
  if (!_researchDiscoverySatisfied(ctx.game, ctx.player.id, tech)) return;

  final funding = fundingStats(order.funding);
  if (funding.cost <= 0) return;
  final nextTreasury = ctx.treasury - funding.cost;
  if (nextTreasury < -ctx.maxDebt) return;

  final points = effectiveResearchPointsForTechAllocation(
    ctx.player,
    tech,
    funding.points,
  );
  if (points <= 0) return;

  ctx.treasury = nextTreasury;
  ctx.progress[techId] = (ctx.progress[techId] ?? 0) + points;
}

({Game state, Player? updatedPlayer}) _resolveResearchForOnePlayer({
  required Game game,
  required Game state,
  required Player player,
  required List<ResearchOrder> playerOrders,
  required int turn,
  required List<DossierEvidenceEntry> extraEvidence,
}) {
  final slots = player.researchSlots ?? defaultResearchSlots;
  if (slots <= 0) {
    turnLog.i(
      'research apply turn=$turn playerId=${player.id} '
      'orders=${playerOrders.length} skipped=true reason=no_research_slots',
    );
    return (state: state, updatedPlayer: player);
  }

  final originalUnlocked = Map<String, bool>.from(
    player.techUnlocked ?? const <String, bool>{},
  );
  final workingUnlocked = Map<String, bool>.from(originalUnlocked);
  final progress = Map<String, int>.from(
    player.researchProgressByTechId ?? const <String, int>{},
  );
  final maxDebt = maxDebtForPlayer(player);

  // Persisted slot occupancy merged with this turn's orders. Cancelled or
  // switched-out techs are no longer occupied and forfeit their progress.
  final effectiveBySlot = _effectiveSlotAssignments(
    player: player,
    playerOrders: playerOrders,
    slots: slots,
  );
  final occupiedTechIds = <String>{
    for (final a in effectiveBySlot.values) a.techId,
  };
  // Retain progress while the tech still occupies a slot; prune only for techs
  // that are no longer assigned (cancellation / reassignment).
  progress.removeWhere((techId, _) => !occupiedTechIds.contains(techId));

  final allocation = _ResearchAllocationContext(
    game: game,
    player: player,
    slots: slots,
    originalUnlocked: originalUnlocked,
    progress: progress,
    maxDebt: maxDebt,
    treasury: player.treasury,
  );
  final orderedSlots = effectiveBySlot.keys.toList()..sort();
  for (final slotIndex in orderedSlots) {
    final assignment = effectiveBySlot[slotIndex]!;
    _applyResearchOrderIfValid(
      allocation,
      ResearchOrder(
        slotIndex: slotIndex,
        techId: assignment.techId,
        funding: assignment.funding,
      ),
    );
  }
  final treasury = allocation.treasury;

  final toUnlock = <String>[];
  progress.forEach((techId, pts) {
    final tech = techById(techId);
    if (tech != null && pts >= tech.cost) {
      toUnlock.add(techId);
    }
  });

  for (final techId in toUnlock) {
    workingUnlocked[techId] = true;
    progress.remove(techId);
  }
  // Completing a tech frees its slot; the assignment is not persisted.
  if (toUnlock.isNotEmpty) {
    final completed = toUnlock.toSet();
    effectiveBySlot.removeWhere((_, a) => completed.contains(a.techId));
  }

  var nextState = state;
  final sideFx = _applyResearchUnlockSideEffects(
    state: nextState,
    player: player,
    toUnlock: toUnlock,
    turn: turn,
    extraEvidence: extraEvidence,
  );
  nextState = sideFx.state;

  Map<String, bool>? nextUnlocked;
  if (workingUnlocked.isNotEmpty) {
    nextUnlocked = workingUnlocked;
  }

  final nextUnlockedForLevel = nextUnlocked ?? workingUnlocked;
  final militaryLevel = militaryLevelForUnlocked(nextUnlockedForLevel);
  final nextResearchSlots = researchSlotsForUnlockedTechs(
    player,
    nextUnlockedForLevel,
  );

  final nextProgress = progress.isNotEmpty ? progress : const <String, int>{};

  final treasuryDelta = treasury - player.treasury;
  turnLog.i(
    'research apply turn=$turn playerId=${player.id} '
    'orders=${playerOrders.length} treasuryDelta=$treasuryDelta '
    'completedTechs=${toUnlock.length} inProgressTechs=${nextProgress.length}',
  );

  return (
    state: nextState,
    updatedPlayer: player.copyWith(
      treasury: treasury,
      techUnlocked: nextUnlocked,
      researchProgressByTechId: nextProgress,
      researchSlotAssignments: effectiveBySlot,
      militaryLevel: militaryLevel,
      researchSlots: nextResearchSlots,
    ),
  );
}

/// Research phase resolution. SPEC/program/research-resolution.md.
Game resolveResearchPhase(Game game, Orders orders) {
  final turn = game.worldState.turnState.turnNumber;
  final researchByPlayer = orders.researchOrdersByPlayerId;
  turnLog.i('research phase start turn=$turn');

  // Persisted slot occupancy keeps in-progress techs researching across turns
  // even when no fresh order is submitted for the slot this turn.
  final anyPersistedAssignments = game.players.any(
    (p) => p.researchSlotAssignments?.isNotEmpty ?? false,
  );
  if (researchByPlayer.isEmpty && !anyPersistedAssignments) {
    turnLog.i('research phase end turn=$turn playersWithOrders=0');
    return game;
  }

  final playersWithOrders = researchByPlayer.values
      .where((o) => o.isNotEmpty)
      .length;
  var state = game;
  final extraEvidence = <DossierEvidenceEntry>[];
  // Not Game.mapPlayers: [state] evolves per player during resolution.
  final updatedPlayers = <Player>[];

  for (final p in game.players) {
    final player = state.playerById(p.id)!;
    final playerOrders = researchByPlayer[player.id] ?? const <ResearchOrder>[];
    final hasPersistedAssignments =
        player.researchSlotAssignments?.isNotEmpty ?? false;
    if (playerOrders.isEmpty && !hasPersistedAssignments) {
      updatedPlayers.add(player);
      continue;
    }

    final resolved = _resolveResearchForOnePlayer(
      game: game,
      state: state,
      player: player,
      playerOrders: playerOrders,
      turn: turn,
      extraEvidence: extraEvidence,
    );
    state = resolved.state;
    updatedPlayers.add(resolved.updatedPlayer!);
  }

  turnLog.i(
    'research phase end turn=$turn playersWithOrders=$playersWithOrders',
  );
  final resolvedState = state.copyWith(
    players: updatedPlayers,
    dossierEvidenceEntries: [...state.dossierEvidenceEntries, ...extraEvidence],
  );

  // Tech unlocks this phase may raise a GP's general cap; recompute caps and
  // spawn new generals (0 medals) so each roster matches its cap.
  // SPEC/game/military-generals.md § Count and tech-gated cap.
  return syncGeneralCapsFromTech(resolvedState);
}
