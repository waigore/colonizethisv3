import 'dart:math';

import 'locked_province_assigner_graph.dart';

/// Candidate ranking helpers for [LockedAssignerEngine] (Refs #4349 Slice A).
List<String>? lockedAssignerRankedCandidatesForFaction({
  required String faction,
  required Map<String, String> owners,
  required Set<String> unassigned,
  required Set<String> land,
  required Map<String, Set<String>> neighbours,
  required Map<String, String> mandatory,
  required List<String> growthOrder,
  required Random? seedPickerRandom,
  required void Function(String faction) markBlockedFaction,
}) {
  final needsSeed = !owners.containsValue(faction);
  if (needsSeed) {
    final fixed = mandatory[faction];
    if (fixed != null) {
      if (!(unassigned.contains(fixed) && land.contains(fixed))) {
        markBlockedFaction(faction);
        return null;
      }
      return rankLegalNeighbors(
        legal: [fixed],
        unassigned: unassigned,
        neighbours: neighbours,
        land: land,
      );
    }
    final cand = unassigned
        .where(
          (p) => !lockedAssignerReservedMandatoryForLaterFaction(
            province: p,
            currentFaction: faction,
            growthOrder: growthOrder,
            mandatory: mandatory,
          ),
        )
        .toList()
      ..sort();
    if (seedPickerRandom != null) {
      cand.shuffle(seedPickerRandom);
    }
    if (cand.isEmpty) return null;
    return rankLegalNeighbors(
      legal: cand,
      unassigned: unassigned,
      neighbours: neighbours,
      land: land,
    );
  }
  final legalList = lockedAssignerLegalNeighborSet(
    faction: faction,
    owners: owners,
    unassigned: unassigned,
    land: land,
    neighbours: neighbours,
    growthOrder: growthOrder,
    mandatory: mandatory,
  ).toList()
    ..sort();
  if (legalList.isEmpty) return null;
  return rankLegalNeighbors(
    legal: legalList,
    unassigned: unassigned,
    neighbours: neighbours,
    land: land,
  );
}

bool lockedAssignerReservedMandatoryForLaterFaction({
  required String province,
  required String currentFaction,
  required List<String> growthOrder,
  required Map<String, String> mandatory,
}) {
  final ci = growthOrder.indexOf(currentFaction);
  if (ci < 0) return false;
  for (final e in mandatory.entries) {
    final idx = growthOrder.indexOf(e.key);
    if (idx <= ci) continue;
    if (e.value == province) return true;
  }
  return false;
}

Set<String> lockedAssignerLegalNeighborSet({
  required String faction,
  required Map<String, String> owners,
  required Set<String> unassigned,
  required Set<String> land,
  required Map<String, Set<String>> neighbours,
  required List<String> growthOrder,
  required Map<String, String> mandatory,
}) {
  final out = <String>{};
  for (final e in owners.entries) {
    if (e.value != faction) continue;
    for (final n in neighbours[e.key] ?? const <String>{}) {
      if (!unassigned.contains(n) || !land.contains(n)) continue;
      if (lockedAssignerReservedMandatoryForLaterFaction(
        province: n,
        currentFaction: faction,
        growthOrder: growthOrder,
        mandatory: mandatory,
      )) {
        continue;
      }
      out.add(n);
    }
  }
  return out;
}
