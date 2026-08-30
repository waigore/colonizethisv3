// Tree-node assignment eligibility and seat occupancy helpers (Refs #4498).
// SPEC/ui/tech-tree-widget.md § Description dialog; reuses Slots occupancy.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'technology_panel_research_slots.dart';

/// Why Tree assignment is unavailable for a node dialog.
enum TechTreeAssignBlockReason {
  observeOnly,
  alreadyUnlocked,
  alreadySeated,
  missingPrerequisites,
  discoveryBlocked,
}

/// Snapshot of active-seat occupancy for Tree assign / node In-progress.
class TechTreeSeatOccupancy {
  const TechTreeSeatOccupancy({
    required this.activeSeatCount,
    required this.assignmentBySeat,
    required this.techIdsInSeats,
  });

  final int activeSeatCount;
  final Map<int, ResearchSlotAssignment> assignmentBySeat;
  final Set<String> techIdsInSeats;

  List<int> get emptySeatIndices {
    final empty = <int>[];
    for (var i = 0; i < activeSeatCount; i++) {
      if (!assignmentBySeat.containsKey(i)) empty.add(i);
    }
    return empty;
  }

  int? get lowestEmptySeatIndex {
    final empty = emptySeatIndices;
    return empty.isEmpty ? null : empty.first;
  }

  bool get allSeatsOccupied =>
      activeSeatCount > 0 && emptySeatIndices.isEmpty;
}

TechTreeSeatOccupancy techTreeSeatOccupancy({
  required Player player,
  required Orders currentOrders,
}) {
  final activeSeatCount = player.researchSlots ?? 3;
  final orders =
      currentOrders.researchOrdersByPlayerId[player.id] ??
      const <ResearchOrder>[];
  final bySeat = <int, ResearchSlotAssignment>{};
  for (var i = 0; i < activeSeatCount; i++) {
    final assignment = effectiveTechnologyAssignmentForSlot(
      player: player,
      index: i,
      researchOrdersForPlayer: orders,
    );
    if (assignment != null) {
      bySeat[i] = assignment;
    }
  }
  return TechTreeSeatOccupancy(
    activeSeatCount: activeSeatCount,
    assignmentBySeat: bySeat,
    techIdsInSeats: bySeat.values.map((a) => a.techId).toSet(),
  );
}

/// Result of evaluating Tree dialog assign controls for [tech].
class TechTreeAssignDecision {
  const TechTreeAssignDecision._({
    required this.choosable,
    this.blockReason,
    this.seatedSlotIndex,
    this.missingPrerequisiteNames = const [],
  });

  factory TechTreeAssignDecision.allowed() =>
      const TechTreeAssignDecision._(choosable: true);

  factory TechTreeAssignDecision.blocked({
    required TechTreeAssignBlockReason reason,
    int? seatedSlotIndex,
    List<String> missingPrerequisiteNames = const [],
  }) => TechTreeAssignDecision._(
    choosable: false,
    blockReason: reason,
    seatedSlotIndex: seatedSlotIndex,
    missingPrerequisiteNames: missingPrerequisiteNames,
  );

  final bool choosable;
  final TechTreeAssignBlockReason? blockReason;
  final int? seatedSlotIndex;
  final List<String> missingPrerequisiteNames;
}

TechTreeAssignDecision evaluateTechTreeAssign({
  required Game game,
  required Player player,
  required TechDefinition tech,
  required TechTreeSeatOccupancy occupancy,
  required bool canEdit,
}) {
  if (!canEdit) {
    return TechTreeAssignDecision.blocked(
      reason: TechTreeAssignBlockReason.observeOnly,
    );
  }
  if (player.techUnlocked?[tech.id] == true) {
    return TechTreeAssignDecision.blocked(
      reason: TechTreeAssignBlockReason.alreadyUnlocked,
    );
  }
  for (final entry in occupancy.assignmentBySeat.entries) {
    if (entry.value.techId == tech.id) {
      return TechTreeAssignDecision.blocked(
        reason: TechTreeAssignBlockReason.alreadySeated,
        seatedSlotIndex: entry.key,
      );
    }
  }
  final unlocked = player.techUnlocked ?? const <String, bool>{};
  final missing = tech.prerequisiteIds
      .where((id) => unlocked[id] != true)
      .map(techDisplayName)
      .toList();
  if (missing.isNotEmpty) {
    return TechTreeAssignDecision.blocked(
      reason: TechTreeAssignBlockReason.missingPrerequisites,
      missingPrerequisiteNames: missing,
    );
  }
  final researchable = researchableTechIds(
    unlocked,
    hasDiscoveredResource: (r) =>
        hasRevealedResourceForPlayer(game, player.id, r),
  );
  if (!researchable.contains(tech.id)) {
    return TechTreeAssignDecision.blocked(
      reason: TechTreeAssignBlockReason.discoveryBlocked,
    );
  }
  return TechTreeAssignDecision.allowed();
}

String techTreeAssignReasonMessage(
  AppLocalizations l10n,
  TechTreeAssignDecision decision,
) {
  switch (decision.blockReason) {
    case TechTreeAssignBlockReason.observeOnly:
      return l10n.techTree_assignReasonObserveOnly;
    case TechTreeAssignBlockReason.alreadyUnlocked:
      return l10n.techTree_assignReasonAlreadyKnown;
    case TechTreeAssignBlockReason.alreadySeated:
      final slot = (decision.seatedSlotIndex ?? 0) + 1;
      return l10n.techTree_assignReasonAlreadySeated(slot);
    case TechTreeAssignBlockReason.missingPrerequisites:
      final names = decision.missingPrerequisiteNames.join(', ');
      return l10n.techTree_assignReasonWaitingOn(names);
    case TechTreeAssignBlockReason.discoveryBlocked:
      return l10n.techTree_assignReasonDiscovery;
    case null:
      return '';
  }
}
