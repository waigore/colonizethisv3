/// Relation upsert primitives for diplomacy phase mutations.
/// SPEC/program/diplomacy-resolution.md.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/world/diplomatic_relation_lookup.dart';

/// Finds the relation, passes it (or null) to [updater], and replaces or
/// appends the result.
///
/// **Soft-deprecated for batched/loop use in favour of [RelationUpsertIndex]**
/// (Refs #3562 AC5). It is not annotated `@Deprecated` because it remains the
/// correct primitive for a genuinely *single* isolated upsert, and a hard
/// annotation would wrongly flag those legitimate call sites; instead the
/// acceptable single-call-vs-batched guidance is documented here and at the
/// remaining single-call sites.
///
/// Each call rebuilds the `pairKey → firstIndex` map and copies the whole
/// relations list, so it is O(relations) per call. Use it only for a **single
/// isolated upsert** (one accepted order / one resolver event). For **repeated**
/// upserts in a loop — multiple orders, per-tribe first contact, batched phase
/// mutations — prefer [RelationUpsertIndex], which builds the index once and
/// keeps each upsert amortized O(1); calling [upsertRelation] in a loop silently
/// reintroduces an O(relations²) pattern (Refs #3562 AC5).
List<DiplomacyRelation> upsertRelation(
  List<DiplomacyRelation> relations,
  String factionId1,
  String factionId2,
  DiplomacyRelation Function(DiplomacyRelation?) updater,
) {
  final key = pairKey(factionId1, factionId2);
  final firstIndexByPairKey = <String, int>{};
  for (var i = 0; i < relations.length; i++) {
    final r = relations[i];
    final rk = pairKey(r.factionId1, r.factionId2);
    firstIndexByPairKey.putIfAbsent(rk, () => i);
  }
  final idx = firstIndexByPairKey[key];
  final existing = idx != null ? relations[idx] : null;
  final updated = updater(existing);
  final result = List<DiplomacyRelation>.from(relations);
  if (idx != null) {
    result[idx] = updated;
  } else {
    result.add(updated);
  }
  return result;
}

/// Mutable accumulator for repeated relation upserts in a single phase.
///
/// Builds the `pairKey → firstIndex` map **once** at construction and keeps it
/// current as relations are appended, so each [upsert] is amortized O(1).
/// This replaces calling the standalone [upsertRelation] in a loop, which
/// rebuilt the whole index (and copied the entire list) on every call —
/// O(relations²) across a phase (Refs #3419 step 5).
///
/// Produces results identical to applying [upsertRelation] sequentially over
/// the same starting list and updaters; call [toList] for a defensive copy
/// suitable for `copyWith`.
class RelationUpsertIndex {
  RelationUpsertIndex(List<DiplomacyRelation> relations)
    : _relations = List<DiplomacyRelation>.from(relations) {
    for (var i = 0; i < _relations.length; i++) {
      final r = _relations[i];
      _firstIndexByPairKey.putIfAbsent(
        pairKey(r.factionId1, r.factionId2),
        () => i,
      );
    }
  }

  final List<DiplomacyRelation> _relations;
  final Map<String, int> _firstIndexByPairKey = <String, int>{};

  /// Number of relations currently held.
  int get length => _relations.length;

  /// Finds the relation for the [factionId1]/[factionId2] pair, passes it (or
  /// null) to [updater], and replaces or appends the result in place.
  void upsert(
    String factionId1,
    String factionId2,
    DiplomacyRelation Function(DiplomacyRelation?) updater,
  ) {
    final key = pairKey(factionId1, factionId2);
    final idx = _firstIndexByPairKey[key];
    final existing = idx != null ? _relations[idx] : null;
    final updated = updater(existing);
    if (idx != null) {
      _relations[idx] = updated;
    } else {
      _relations.add(updated);
      _firstIndexByPairKey[key] = _relations.length - 1;
    }
  }

  /// Defensive copy of the accumulated relations for storing on a [Game].
  List<DiplomacyRelation> toList() => List<DiplomacyRelation>.from(_relations);
}
