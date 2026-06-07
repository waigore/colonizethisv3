import 'package:colonizethis_models/colonizethis_models.dart';

/// Canonical sea-zone identity contract.
///
/// Sea-zone ids used for bucket lookups/comparisons must be prefixed
/// (`regionId|localSeaZoneId`).
String canonicalizeSeaZoneId({
  required String regionId,
  required String seaZoneId,
}) {
  if (ProvinceId.isPrefixed(seaZoneId)) {
    final idRegion = ProvinceId.regionIdFrom(seaZoneId);
    if (idRegion != regionId) {
      throw StateError(
        'logic: canonical sea-zone id region mismatch; expected "$regionId", '
        'got "$idRegion" for "$seaZoneId".',
      );
    }
    return seaZoneId;
  }
  return ProvinceId.full(regionId, seaZoneId);
}

/// True only for canonical prefixed sea-zone ids (`regionId|localSeaZoneId`).
bool isCanonicalSeaZoneId(String value) => ProvinceId.isPrefixed(value);

/// Runtime policy guard: local-only sea-zone ids are invalid outside boundary adapters.
void failIfLegacyLocalSeaZoneId(String value, {required String context}) {
  if (isCanonicalSeaZoneId(value)) return;
  throw StateError(
    'logic: $context requires canonical prefixed sea-zone id '
    '(regionId|localSeaZoneId), got legacy local id "$value".',
  );
}
