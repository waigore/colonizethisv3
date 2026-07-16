/// Small pure helpers shared across turn-resolution phases and post-phase
/// emission. Kept dependency-free (no logging, no global scans) so they are
/// safe to call on hot paths. SPEC/program/turn-resolution-phases.md.
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Canonical prefixed province id for [province] (`regionId|localId`).
///
/// Shared by capture-event emission and turn-news digest so both paths key
/// provinces the same way (Refs #4039). Delegates to [toFullProvinceId].
String prefixedProvinceId(Province province) =>
    toFullProvinceId(province.regionId, province.id);

/// True when a province changed hands between two non-empty faction owners.
///
/// Both [before] and [after] must be non-null, non-empty faction ids and must
/// differ. A null/empty owner is uncolonized frontier only, not a capture
/// outcome. SPEC/game/world-model.md § Invariants. Shared by
/// `emitProvinceCapturedEvents` and the news-digest capture lines so the
/// predicate stays identical for both.
bool isProvinceOwnershipCaptured(String? before, String? after) {
  return before != null &&
      before.isNotEmpty &&
      after != null &&
      after.isNotEmpty &&
      before != after;
}

/// Clamps [value] to the inclusive `[0, 1]` range, preserving exact `0.0`/`1.0`
/// boundary semantics (no floating-point rescaling). Used for feeding-coverage
/// ratios in the consumption phase.
double clamp01(double value) {
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}
