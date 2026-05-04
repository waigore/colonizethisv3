typedef ParsedMapTileKey = ({String regionId, String localId, int x, int y});

typedef ParsedMapTileSuffixXY = ({int x, int y});

ParsedMapTileKey? tryParseMapTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) {
    return null;
  }
  final x = int.tryParse(parts[2]);
  final y = int.tryParse(parts[3]);
  if (x == null || y == null) {
    return null;
  }
  return (regionId: parts[0], localId: parts[1], x: x, y: y);
}

ParsedMapTileSuffixXY? tryParseMapTileKeySuffixXY(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 4) {
    return null;
  }
  final x = int.tryParse(parts[parts.length - 2]);
  final y = int.tryParse(parts[parts.length - 1]);
  if (x == null || y == null) {
    return null;
  }
  return (x: x, y: y);
}

/// Returns [a, b] when [s] splits into exactly two segments (e.g. topology edge ids).
List<String>? trySplitExactlyTwoPipeSegments(String s) {
  final parts = s.split('|');
  if (parts.length != 2) {
    return null;
  }
  return parts;
}

/// Last `|` segment, or [delimited] when there is no delimiter (same as a single-segment split).
String lastPipeSegment(String delimited) {
  final parts = delimited.split('|');
  return parts.last;
}

/// Local province id from a `portsByProvinceSeaboard` map **key** for [regionId].
/// SPEC/ui/town-port-icons.md.
String? tryLocalProvinceIdFromPortsSeaboardKey(
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
