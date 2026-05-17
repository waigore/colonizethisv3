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
