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

/// Parsed components of a `regionId|provinceLocalId|x|y` tile key.
///
/// See SPEC/game/world-model-identity.md for the canonical tile key shape used
/// across `colonizethis_logic`, `colonizethis_models`, and app UI code.
class ParsedTileKey {
  const ParsedTileKey({
    required this.regionId,
    required this.provinceLocalId,
    required this.x,
    required this.y,
  });

  final String regionId;
  final String provinceLocalId;
  final int x;
  final int y;

  /// Full prefixed province id (`regionId|provinceLocalId`). SPEC/game/world-model-identity.md.
  String get prefixedProvinceId => '$regionId|$provinceLocalId';

  @override
  String toString() =>
      'ParsedTileKey($regionId|$provinceLocalId|$x|$y)';
}

/// Single-pass parse of a tile key into [ParsedTileKey], or `null` when the
/// key is missing, malformed (fewer than four `|`-delimited segments), has
/// empty `regionId` or `provinceLocalId`, or non-integer coordinates.
///
/// Replaces the legacy `final parts = tileKey.split('|'); if (parts.length <
/// 4) ...` idiom with three `indexOf` scans and four `substring` calls (zero
/// `List<String>` allocation per call). Hot paths in
/// `app/lib/features/game/flame/` and overlay/panel code call this on every
/// draft-projected unit or fleet (see #2575 finding §9). SPEC/game/world-model-identity.md.
ParsedTileKey? tryParseTileKey(String? tileKey) {
  if (tileKey == null || tileKey.isEmpty) return null;
  final i1 = tileKey.indexOf('|');
  if (i1 <= 0) return null;
  final i2 = tileKey.indexOf('|', i1 + 1);
  if (i2 <= i1 + 1) return null;
  final i3 = tileKey.indexOf('|', i2 + 1);
  if (i3 <= i2 + 1) return null;
  if (i3 + 1 >= tileKey.length) return null;
  final regionId = tileKey.substring(0, i1);
  final provinceLocalId = tileKey.substring(i1 + 1, i2);
  final x = int.tryParse(tileKey.substring(i2 + 1, i3));
  final y = int.tryParse(tileKey.substring(i3 + 1));
  if (x == null || y == null) return null;
  return ParsedTileKey(
    regionId: regionId,
    provinceLocalId: provinceLocalId,
    x: x,
    y: y,
  );
}

/// True iff [tileKey] parses as a well-formed tile key for the given
/// [regionId]. Mirrors the historical `parts.length >= 4 && parts[0] ==
/// regionId` guard around inline `split('|')` calls in projection/action
/// state code. SPEC/game/world-model-identity.md.
bool isTileKeyInRegion(String tileKey, String regionId) {
  final parsed = tryParseTileKey(tileKey);
  return parsed != null && parsed.regionId == regionId;
}
