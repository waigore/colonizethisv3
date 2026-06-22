/// Tile town / capital designation helpers for the province / sea-zone detail
/// overlay. See SPEC/ui/province-sea-zone-detail-overlay.md § Province overlay
/// content `Tile` (town / capital designation) and `Political / Economic /
/// Naval` (Capital row).

part of 'province_sea_zone_detail_overlay.dart';

/// Whether [provinceId] is the capital province of any faction (player,
/// minor nation, or tribe). Capital status is always-exact political intel
/// (Refs #2865, SPEC § Province overlay content `Political / Economic /
/// Naval`).
@visibleForTesting
bool provinceOverlayIsCapital(Game game, String provinceId) {
  for (final p in game.players) {
    if (p.capitalProvinceId == provinceId) return true;
  }
  for (final m in game.minorNations) {
    if (m.capitalProvinceId == provinceId) return true;
  }
  for (final t in game.tribes) {
    if (t.capitalProvinceId == provinceId) return true;
  }
  return false;
}

/// Display name of the faction (player, minor nation, or tribe) whose
/// `capitalTile` resolves to [tileKey], or null when no faction's capital tile
/// matches. Faction display-name resolution mirrors the Political `Owner`
/// family (player `displayName`; minor/tribe `displayName` falling back to id).
String? _capitalHolderDisplayNameForTile(Game game, String tileKey) {
  for (final p in game.players) {
    if (p.capitalTile?.toTileKey() == tileKey) return p.displayName;
  }
  for (final m in game.minorNations) {
    if (m.capitalTile?.toTileKey() == tileKey) return m.displayName ?? m.id;
  }
  for (final t in game.tribes) {
    if (t.capitalTile?.toTileKey() == tileKey) return t.displayName ?? t.id;
  }
  return null;
}

/// Optional Tile-section designation line for [selectedTileKey] (between the
/// Terrain and Resource rows). Capital takes priority over town; ordinary land
/// tiles return null so no line renders. See SPEC/ui/province-sea-zone-detail-
/// overlay.md § Tile town / capital designation.
@visibleForTesting
String? provinceOverlayTileDesignationLine({
  required AppLocalizations l10n,
  required Game game,
  required String provinceId,
  required String selectedTileKey,
}) {
  final province = _findProvince(game, provinceId);
  final provinceName = province?.displayName ?? provinceId;
  final capitalFactionName = _capitalHolderDisplayNameForTile(
    game,
    selectedTileKey,
  );
  if (capitalFactionName != null) {
    return l10n.provinceOverlay_tileCapitalOf(provinceName, capitalFactionName);
  }
  final townTileKey = province?.townTileKey;
  if (townTileKey != null && townTileKey == selectedTileKey) {
    return l10n.provinceOverlay_tileTownOf(provinceName);
  }
  return null;
}
