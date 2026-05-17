// Pipe-delimited strings in colonizethis_map that are not canonical map tile
// keys `regionId|provinceId|x|y`. Tile keys use tile_key_util.dart. GitHub #2087.

/// Local province id from a `portsByProvinceSeaboard` **key** for [regionId].
/// SPEC/ui/town-port-icons.md, GitHub #1770.
String? mapPipeLocalProvinceIdFromPortsSeaboardKey(
  String seaboardKey,
  String regionId,
) {
  final parts = seaboardKey.split('|');
  if (parts.length >= 3) {
    if (parts[0] != regionId) {
      return null;
    }
    return parts[1];
  }
  if (parts.length == 2) {
    return parts[0];
  }
  return null;
}

/// Parses `left|right` when exactly two segments (e.g. topology adjacency pairs).
(String left, String right)? mapPipeTryParseTwoPartPair(String value) {
  final parts = value.split('|');
  if (parts.length == 2) {
    return (parts[0], parts[1]);
  }
  return null;
}

/// Last `|` segment when present; otherwise the whole string (e.g. sea-zone id).
String mapPipeLastSegmentOrWhole(String value) {
  if (!value.contains('|')) {
    return value;
  }
  return value.split('|').last;
}
