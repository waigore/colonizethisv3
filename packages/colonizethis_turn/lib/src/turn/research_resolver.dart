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

  final bySlot = <int, ResearchOrder>{};
  for (final order in playerOrders) {
    bySlot[order.slotIndex] = order;
  }
  final ordersPerSlot = bySlot.values.toList();

  final assignedNonEmptyTechIds = <String>{};
  for (final order in ordersPerSlot) {
    if (order.slotIndex < 0 || order.slotIndex >= slots) continue;
    if (order.techId.isEmpty) continue;
    assignedNonEmptyTechIds.add(order.techId);
  }
  progress.removeWhere(
    (techId, _) => !assignedNonEmptyTechIds.contains(techId),
  );

  final allocation = _ResearchAllocationContext(
    game: game,
    player: player,
    slots: slots,
    originalUnlocked: originalUnlocked,
    progress: progress,
    maxDebt: maxDebt,
    treasury: player.treasury,
  );
  for (final order in ordersPerSlot) {
    _applyResearchOrderIfValid(allocation, order);
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

  if (researchByPlayer.isEmpty) {
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
    if (playerOrders.isEmpty) {
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
