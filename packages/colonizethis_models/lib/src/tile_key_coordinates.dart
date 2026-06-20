/// Canonical tile-key coordinate parser for `regionId|provinceId|x|y`.
///
/// Lives in the foundational `colonizethis_models` package (Refs #3427) so every
/// domain package (`colonizethis_world`, `colonizethis_orders`,
/// `colonizethis_economy`) can import it through a barrel without the previous
/// world-vs-orders ambiguous-re-export workaround.
({String regionId, String provinceLocalId, int x, int y})?
parseTileKeyCoordinates(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length != 4) return null;
  final x = int.tryParse(parts[2]);
  final y = int.tryParse(parts[3]);
  if (x == null || y == null) return null;
  return (regionId: parts[0], provinceLocalId: parts[1], x: x, y: y);
}
