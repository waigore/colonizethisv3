/// Tile town / capital designation helpers for the province / sea-zone detail
/// overlay. See SPEC/ui/province-sea-zone-detail-overlay.md § Province overlay
/// content `Tile` (town / capital designation) and `Political / Economic /
/// Naval` (Capital row).
library;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'province_sea_zone_detail_overlay_sections_political.dart';

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

String? capitalHolderDisplayNameForTile(Game game, String tileKey) {
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

String? provinceOverlayTileDesignationLine({
  required AppLocalizations l10n,
  required Game game,
  required String provinceId,
  required String selectedTileKey,
}) {
  final province = findProvinceForSeaZoneOverlay(game, provinceId);
  final provinceName = province?.displayName ?? provinceId;
  final capitalFactionName = capitalHolderDisplayNameForTile(
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
