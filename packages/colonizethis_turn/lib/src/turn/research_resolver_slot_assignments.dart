import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// True when [techId] can occupy [slotIndex] given [slots] research slots.
/// SPEC/program/research-resolution.md § Slot occupancy persistence.
bool isResearchableSlotAssignment(int slotIndex, String techId, int slots) {
  if (slotIndex < 0 || slotIndex >= slots) return false;
  if (techId.isEmpty) return false;
  return techById(techId) != null;
}

/// Builds the effective per-slot occupancy for one resolution pass.
/// SPEC/program/research-resolution.md § Slot occupancy persistence.
Map<int, ResearchSlotAssignment> effectiveResearchSlotAssignments({
  required Player player,
  required List<ResearchOrder> playerOrders,
  required int slots,
}) {
  final effective = <int, ResearchSlotAssignment>{};
  final persisted = player.researchSlotAssignments;
  if (persisted != null) {
    for (final entry in persisted.entries) {
      if (isResearchableSlotAssignment(entry.key, entry.value.techId, slots)) {
        effective[entry.key] = entry.value;
      }
    }
  }
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

bool researchPrerequisitesMet(
  TechDefinition tech,
  Map<String, bool> originalUnlocked,
) {
  for (final pre in tech.prerequisiteIds) {
    if (originalUnlocked[pre] != true) return false;
  }
  return true;
}

bool researchDiscoverySatisfied(
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
