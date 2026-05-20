/// Single-scan helpers for `regionId|localId` composite ids in app UI code.
///
/// For province ids that must be prefixed at validation boundaries, prefer
/// [ProvinceId] in `colonizethis_models`. These helpers mirror legacy
/// `contains('|')` + `split('|')` behavior without extra allocations.

/// Local segment after the first `|`, or [id] when unprefixed.
String prefixedIdLocalSegment(String id) {
  final i = id.indexOf('|');
  return i < 0 ? id : id.substring(i + 1);
}

/// Region segment before the first `|`, or null when unprefixed.
String? prefixedIdRegionSegment(String id) {
  final i = id.indexOf('|');
  return i < 0 ? null : id.substring(0, i);
}

/// True when [id] contains a `|` delimiter.
bool prefixedIdHasDelimiter(String id) => id.indexOf('|') >= 0;
