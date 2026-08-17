import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared province-target resolution for flip/reveal debug commands (Refs #4484).
///
/// [commandLabel] is the command verb embedded in reject prefixes
/// (`flip_province` / `reveal_province`). Message shapes stay command-specific
/// via [ambiguousRetryHint] and optional [regionId] wording.
({Province? province, String? failureMessage}) resolveDebugProvinceTarget({
  required WorldState world,
  required String commandLabel,
  String? fullProvinceId,
  String? regionId,
  String? provinceDisplayName,
  required bool searchAllRegionsByDisplayName,
  required String ambiguousRetryHint,
}) {
  if (fullProvinceId != null) {
    final province = world.tryGetProvince(fullProvinceId);
    if (province == null) {
      return (
        province: null,
        failureMessage:
            'Debug $commandLabel rejected: province "$fullProvinceId" not found.',
      );
    }
    return (province: province, failureMessage: null);
  }

  if (searchAllRegionsByDisplayName) {
    if (provinceDisplayName == null) {
      return (
        province: null,
        failureMessage:
            'Debug $commandLabel rejected: invalid command target.',
      );
    }
    return _matchByDisplayName(
      candidates: world.allProvinces(),
      commandLabel: commandLabel,
      provinceDisplayName: provinceDisplayName,
      regionId: null,
      ambiguousRetryHint: ambiguousRetryHint,
    );
  }

  if (regionId == null || provinceDisplayName == null) {
    return (
      province: null,
      failureMessage:
          'Debug $commandLabel rejected: invalid command target. Use region+name or full province id.',
    );
  }
  final regionData = regionDataForId(world, regionId);
  if (regionData == null) {
    return (
      province: null,
      failureMessage:
          'Debug $commandLabel rejected: unknown region "$regionId".',
    );
  }
  return _matchByDisplayName(
    candidates: regionData.provinces,
    commandLabel: commandLabel,
    provinceDisplayName: provinceDisplayName,
    regionId: regionId,
    ambiguousRetryHint: ambiguousRetryHint,
  );
}

({Province? province, String? failureMessage}) _matchByDisplayName({
  required Iterable<Province> candidates,
  required String commandLabel,
  required String provinceDisplayName,
  required String? regionId,
  required String ambiguousRetryHint,
}) {
  final normalizedDisplayName = provinceDisplayName.trim().toLowerCase();
  final matched = candidates
      .where(
        (p) =>
            (p.displayName ?? '').trim().toLowerCase() == normalizedDisplayName,
      )
      .toList(growable: false);
  if (matched.isEmpty) {
    final regionClause =
        regionId == null ? '' : ' in region "$regionId"';
    return (
      province: null,
      failureMessage:
          'Debug $commandLabel rejected: province "$provinceDisplayName" not found$regionClause.',
    );
  }
  if (matched.length > 1) {
    final candidateIds = matched.map((p) => p.id).toList()..sort();
    final regionClause =
        regionId == null ? '' : ' in region "$regionId"';
    return (
      province: null,
      failureMessage:
          'Debug $commandLabel rejected: province "$provinceDisplayName" is ambiguous$regionClause. '
          'Candidates: ${candidateIds.join(', ')}. Retry with $ambiguousRetryHint.',
    );
  }
  return (province: matched.single, failureMessage: null);
}

/// Counts tiles that newly became `fullyVisible` between [before] and [after]
/// for a single player visibility map.
int countNewlyFullyVisibleTiles({
  required Map<String, String> before,
  required Map<String, String> after,
}) {
  var count = 0;
  for (final MapEntry(key: tileKey, value: level) in after.entries) {
    if (level != VisibilityLevel.fullyVisible.name) continue;
    if (before[tileKey] != VisibilityLevel.fullyVisible.name) {
      count++;
    }
  }
  return count;
}
