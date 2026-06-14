// Shared pure helpers for faction ownership collection and "Faction Setup"
// table rendering used by the init orchestrator and ownership assignment.
// SPEC/program/game-setup-pipeline.md (step 7 faction setup tables, ownership).

import 'package:colonizethis_models/colonizethis_models.dart';

/// Province ids owned by [factionId] within [provinces], preserving the source
/// iteration order. When [sorted] (the default) the ids are returned in
/// ascending order, matching the setup-table and ownership collection contracts.
List<String> ownedProvinceIdsForFaction(
  Iterable<Province> provinces,
  String factionId, {
  bool sorted = true,
}) {
  final owned = <String>[
    for (final pr in provinces)
      if (pr.ownerId == factionId) pr.id,
  ];
  if (sorted) owned.sort();
  return owned;
}

/// Provinces owned by [factionId] within [provinces]. When [sorted] (the
/// default) the provinces are ordered by ascending id, matching the province
/// naming collection contract; pass `sorted: false` to preserve the source
/// iteration order (used by Great Power naming, which assigns names in the
/// order provinces appear in the region list).
List<Province> ownedProvincesForFaction(
  Iterable<Province> provinces,
  String factionId, {
  bool sorted = true,
}) {
  final owned = <Province>[
    for (final pr in provinces)
      if (pr.ownerId == factionId) pr,
  ];
  if (sorted) owned.sort((a, b) => a.id.compareTo(b.id));
  return owned;
}

/// One faction row for the "Faction Setup" markdown table. [capitalProvinceId]
/// renders as an em dash when null, and [ownedProvinceIds] are comma-joined.
String factionSetupTableRow({
  required String displayLabel,
  required String factionId,
  required String typeLabel,
  required String? capitalProvinceId,
  required List<String> ownedProvinceIds,
}) {
  final capital = capitalProvinceId ?? '—';
  return '| $displayLabel ($factionId) | $typeLabel | $capital '
      '| ${ownedProvinceIds.join(", ")} |';
}
