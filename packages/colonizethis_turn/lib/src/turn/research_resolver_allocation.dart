import 'package:colonizethis_data/colonizethis_data.dart';
import 'turn_logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_debt_rules.dart';
import 'economy_tech_effects.dart';
import 'research_resolver_slot_assignments.dart';
import 'research_resolver_unlock_side_effects.dart';
import 'research_rules.dart';
import 'spy_resolver.dart';

/// Mutable per-player accumulator for one research-phase allocation pass.
///
/// Bundles the immutable inputs ([game], [player], [slots], [originalUnlocked],
/// [maxDebt]) with the state mutated while applying each [ResearchOrder]
/// ([treasury] and [progress]).
class ResearchAllocationContext {
  ResearchAllocationContext({
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

void applyResearchOrderIfValid(
  ResearchAllocationContext ctx,
  ResearchOrder order,
) {
  if (order.slotIndex < 0 || order.slotIndex >= ctx.slots) return;
  final techId = order.techId;
  if (techId.isEmpty) return;

  final tech = techById(techId);
  if (tech == null) return;
  if (ctx.originalUnlocked[techId] == true) return;
  if (!researchPrerequisitesMet(tech, ctx.originalUnlocked)) return;
  if (!researchDiscoverySatisfied(ctx.game, ctx.player.id, tech)) return;

  final funding = fundingStats(order.funding);
  if (funding.cost <= 0) return;
  final nextTreasury = ctx.treasury - funding.cost;
  if (nextTreasury < -ctx.maxDebt) return;

  final points = applySpyResearchBoostToPoints(
    basePoints: effectiveResearchPointsForTechAllocation(
      ctx.player,
      tech,
      funding.points,
    ),
    qualifyingRivalGpCount: spyResearchBoostGpCountForTech(
      game: ctx.game,
      playerId: ctx.player.id,
      techId: techId,
    ),
  );
  if (points <= 0) return;

  ctx.treasury = nextTreasury;
  ctx.progress[techId] = (ctx.progress[techId] ?? 0) + points;
}

({Game state, Player? updatedPlayer}) resolveResearchForOnePlayer({
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

  final effectiveBySlot = effectiveResearchSlotAssignments(
    player: player,
    playerOrders: playerOrders,
    slots: slots,
  );
  final occupiedTechIds = <String>{
    for (final a in effectiveBySlot.values) a.techId,
  };
  progress.removeWhere((techId, _) => !occupiedTechIds.contains(techId));

  final allocation = ResearchAllocationContext(
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
    applyResearchOrderIfValid(
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
  if (toUnlock.isNotEmpty) {
    final completed = toUnlock.toSet();
    effectiveBySlot.removeWhere((_, a) => completed.contains(a.techId));
  }

  var nextState = state;
  final sideFx = applyResearchUnlockSideEffects(
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
