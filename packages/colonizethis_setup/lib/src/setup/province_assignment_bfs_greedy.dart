import 'dart:collection';
import 'dart:math';

import 'province_assignment.dart' show provinceTouchesFaction;

int greedyAssignRemainingTerritories({
  required Set<String> available,
  required Map<String, String> owners,
  required Map<String, Queue<String>> queues,
  required Map<String, int> assignedCount,
  required List<String> factionIds,
  required Map<String, Set<String>> neighbours,
  required Map<String, int>? landmassIds,
  required Map<String, int>? factionLandmassIds,
  required int total,
  required Random? neighborShuffleRandom,
  required int totalAssigned,
}) {
  var nextTotal = totalAssigned;
  if (available.isEmpty || nextTotal >= total) return nextTotal;

  final sortedRemaining = available.toList()..sort();
  if (neighborShuffleRandom != null) {
    sortedRemaining.shuffle(neighborShuffleRandom);
  }
  final remaining = Queue<String>()..addAll(sortedRemaining);
  while (remaining.isNotEmpty && nextTotal < total) {
    final provinceId = remaining.removeFirst();
    if (!available.remove(provinceId)) continue;

    final chosenFactionId = greedyPickFactionForProvince(
      provinceId: provinceId,
      factionIds: factionIds,
      factionLandmassIds: factionLandmassIds,
      landmassIds: landmassIds,
      owners: owners,
      neighbours: neighbours,
      assignedCount: assignedCount,
    );

    owners[provinceId] = chosenFactionId;
    queues[chosenFactionId]!.add(provinceId);
    assignedCount[chosenFactionId] = assignedCount[chosenFactionId]! + 1;
    nextTotal++;
  }
  return nextTotal;
}

String greedyPickFactionForProvince({
  required String provinceId,
  required List<String> factionIds,
  required Map<String, int>? factionLandmassIds,
  required Map<String, int>? landmassIds,
  required Map<String, String> owners,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> assignedCount,
}) {
  if (factionLandmassIds == null) {
    final sortedFactionIds = factionIds.toList()
      ..sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));
    return sortedFactionIds.first;
  }
  final provinceLandmass = landmassIds?[provinceId];
  var minCount = 999999;
  String? bestFaction;
  for (final fid in factionIds) {
    final allowedLandmass = factionLandmassIds[fid];
    if (allowedLandmass != null && allowedLandmass != provinceLandmass) {
      continue;
    }
    if (!provinceTouchesFaction(provinceId, fid, owners, neighbours)) {
      continue;
    }
    if (assignedCount[fid]! < minCount) {
      minCount = assignedCount[fid]!;
      bestFaction = fid;
    }
  }
  if (bestFaction != null) return bestFaction;
  for (final fid in factionIds) {
    final allowedLandmass = factionLandmassIds[fid];
    if (allowedLandmass != null && allowedLandmass != provinceLandmass) {
      continue;
    }
    if (assignedCount[fid]! < minCount) {
      minCount = assignedCount[fid]!;
      bestFaction = fid;
    }
  }
  if (bestFaction == null) {
    throw StateError(
      'assignTerritoriesByBfsGrowth: no faction can claim province $provinceId '
      'under factionLandmassIds constraints',
    );
  }
  return bestFaction;
}
