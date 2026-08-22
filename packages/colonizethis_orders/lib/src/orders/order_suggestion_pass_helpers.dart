import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';
import 'incremental_candidate_validator.dart';
import 'order_resolution_context.dart';

/// Resolves [OrderResolutionContext] for a suggestion pass, reusing a shared
/// validator's embedded view when available (Refs #2394).
OrderResolutionContext effectiveOrderResolutionContext({
  required PlayerView view,
  required Game game,
  OrderResolutionContext? resolution,
  IncrementalCandidateValidator? sharedCandidateValidator,
}) {
  if (resolution != null) return resolution;
  if (sharedCandidateValidator != null) {
    return (
      view: sharedCandidateValidator.view,
      unitsById: sharedCandidateValidator.unitsById,
      provinceById: sharedCandidateValidator.view.provincesById,
    );
  }
  return orderResolutionContextFromView(view, game);
}

/// Full province ids owned by [playerId] from [view.provincesById].
Set<String> ownedProvinceIdsFromView(PlayerView view, String playerId) {
  return {
    for (final e in view.provincesById.entries)
      if (e.value.ownerId == playerId) e.key,
  };
}

/// Full province ids owned by [playerId] from the memoised [ProvinceOwnerCache].
///
/// Canonical ownership projection for work-tile candidacy, connectivity dev
/// snapshot, and probe-stack paths that must not rescan region province lists
/// or diverge from [ProvinceOwnerCache] (Refs #4258 Slice B).
Set<String> ownedProvinceIdsForPlayer(WorldState world, String playerId) {
  final cache = ProvinceOwnerCache.of(world);
  return {
    for (final p in cache.provincesOwnedBy(playerId))
      ProvinceId.isPrefixed(p.id) ? p.id : ProvinceId.full(p.regionId, p.id),
  };
}

/// Indexes existing orders by entity id → target id set for dedup during
/// suggestion probes.
Map<String, Set<String>> indexExistingTargetsByEntityId<T>(
  List<T>? orders,
  String Function(T order) entityId,
  String Function(T order) target, {
  bool skipEmptyTargets = false,
}) {
  final out = <String, Set<String>>{};
  for (final o in orders ?? const []) {
    final targetId = target(o);
    if (skipEmptyTargets && targetId.isEmpty) continue;
    out.putIfAbsent(entityId(o), () => <String>{}).add(targetId);
  }
  return out;
}

/// Shared probe/emit/dedup tail for suggestion families that enumerate a
/// finite, uncapped candidate set per owned entity (naval move/mission,
/// recruit worker, …). Each [candidate] is skipped when its [dedupKey] is
/// already recorded for its [entityId] in [existingByEntity], then probed via
/// [accept]; accepted orders are appended to [into] (Refs #3714,
/// SPEC/program/order-suggestions.md § Throughput bounds).
///
/// Determinism: preserves the [candidates] iteration order and performs no
/// sorting of its own — callers sort [into] with their family comparator after
/// emission so the observable order matches the prior per-family tail. Dedup is
/// only applied when all of [existingByEntity], [entityId], and [dedupKey] are
/// supplied; otherwise every candidate is probed.
void emitAcceptedCandidates<TOrder>({
  required Iterable<TOrder> candidates,
  required bool Function(TOrder candidate) accept,
  required List<TOrder> into,
  Map<String, Set<String>>? existingByEntity,
  String Function(TOrder candidate)? entityId,
  String Function(TOrder candidate)? dedupKey,
}) {
  final dedupEnabled =
      existingByEntity != null && entityId != null && dedupKey != null;
  for (final candidate in candidates) {
    if (dedupEnabled &&
        (existingByEntity[entityId(candidate)]?.contains(dedupKey(candidate)) ??
            false)) {
      continue;
    }
    if (accept(candidate)) into.add(candidate);
  }
}

/// Deterministic capped probe loop shared by move and army-move suggestion
/// (Refs #3500 Phase 2). Skipped candidates do not count toward [maxProbes].
int runCappedSuggestionProbeLoop<T>({
  required Iterable<T> candidates,
  required bool Function(T candidate) shouldSkip,
  required bool Function(T candidate) probe,
  required void Function(T candidate) onAccepted,
  required int maxAccepted,
  required int maxProbes,
}) {
  var accepted = 0;
  var probeAttempts = 0;
  for (final candidate in candidates) {
    if (shouldSkip(candidate)) continue;
    probeAttempts++;
    if (probe(candidate)) {
      onAccepted(candidate);
      accepted++;
      if (accepted >= maxAccepted) break;
    }
    if (probeAttempts >= maxProbes) break;
  }
  return accepted;
}
