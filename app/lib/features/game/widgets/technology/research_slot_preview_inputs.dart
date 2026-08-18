// Occupied-slot preview inputs shared by GAME40001 Slots and the Tree
// node finish-time line (Refs #4511).
//
// SPEC: SPEC/ui/technology-panel.md § Slot turn preview;
// SPEC/ui/tech-tree-widget.md § Description dialog (Finish-time).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'research_slot_finish_estimate.dart';
import 'research_slot_preview.dart';
import 'research_slot_spy_insight.dart';
import 'technology_panel_research_slots.dart';

/// Occupied-seat inputs for [computeResearchSlotsTurnPreview], in slot-index
/// order of discovery (the sequential walk re-sorts).
List<ResearchSlotPreviewInput> occupiedResearchSlotPreviewInputs({
  required Game game,
  required Player player,
  required Orders currentOrders,
}) {
  final progress = player.researchProgressByTechId ?? const <String, int>{};
  final slots = player.researchSlots ?? 3;
  final orders =
      currentOrders.researchOrdersByPlayerId[player.id] ??
      const <ResearchOrder>[];
  final occupied = <ResearchSlotPreviewInput>[];
  for (var index = 0; index < slots; index++) {
    final assignment = effectiveTechnologyAssignmentForSlot(
      player: player,
      index: index,
      researchOrdersForPlayer: orders,
    );
    final techId = assignment?.techId;
    final tech = techId == null ? null : techById(techId);
    if (tech == null || assignment == null) {
      continue;
    }
    final insight = spyInsightForResearchPreview(
      game: game,
      playerId: player.id,
      techId: tech.id,
    );
    occupied.add(
      ResearchSlotPreviewInput(
        slotIndex: index,
        tech: tech,
        committedProgress: progress[techId] ?? 0,
        funding: assignment.funding,
        qualifyingRivalGpCount: insight.count,
        qualifyingRivalDisplayNames: insight.names,
      ),
    );
  }
  return occupied;
}

/// Finish estimate for [techId] when that tech occupies a spending seat.
({ResearchFinishEstimate estimate, int? calendarYear})?
researchFinishForSeatedTech({
  required Game game,
  required Player player,
  required Orders currentOrders,
  required String techId,
}) {
  final inputs = occupiedResearchSlotPreviewInputs(
    game: game,
    player: player,
    currentOrders: currentOrders,
  );
  ResearchSlotPreviewInput? seated;
  for (final input in inputs) {
    if (input.tech.id == techId) {
      seated = input;
      break;
    }
  }
  if (seated == null) {
    return null;
  }
  final preview = computeResearchSlotsTurnPreview(
    player: player,
    occupiedSlots: inputs,
  ).bySlotIndex[seated.slotIndex];
  if (preview == null) {
    return null;
  }
  final estimate = researchFinishEstimate(preview);
  if (estimate == null) {
    return null;
  }
  return (
    estimate: estimate,
    calendarYear: researchFinishCalendarYear(
      estimate: estimate,
      calendar: ResearchFinishCalendar.fromGame(game),
    ),
  );
}
