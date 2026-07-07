/// Political section assembly and owner/region display helpers.

part of 'province_sea_zone_detail_overlay.dart';

String _ownerName(AppLocalizations l10n, Game game, String? ownerId) {
  if (ownerId == null || ownerId.isEmpty) {
    return l10n.provinceOverlay_ownerUnclaimed;
  }
  for (final p in game.players) {
    if (p.id == ownerId) return p.displayName;
  }
  for (final m in game.minorNations) {
    if (m.id == ownerId) return m.displayName ?? m.id;
  }
  for (final t in game.tribes) {
    if (t.id == ownerId) return t.displayName ?? t.id;
  }
  return ownerId;
}

/// Test-only accessor for the owner display-name resolution (Refs #2865;
/// SPEC § Province overlay content `Political` Owner row — localized
/// `provinceOverlay_ownerUnclaimed` fallback for unowned provinces/tiles).
@visibleForTesting
String provinceOverlayOwnerName(
  AppLocalizations l10n,
  Game game,
  String? ownerId,
) =>
    _ownerName(l10n, game, ownerId);

/// Human-readable region label for the province's `regionId`. Maps the two
/// canonical world regions to their localized tab labels and falls back to
/// the raw id for any other region (Refs #2865, SPEC § Province overlay
/// content `Political / Economic / Naval`).
@visibleForTesting
String provinceOverlayRegionLabel(AppLocalizations l10n, String regionId) {
  return switch (regionId) {
    kRegionOldWorld => l10n.region_oldWorld,
    kRegionNewWorld => l10n.region_newWorld,
    _ => regionId,
  };
}

Widget _buildPoliticalSection({
  required AppLocalizations l10n,
  required String name,
  required String ownerName,
  required String regionLabel,
  required bool isCapital,
  required int townDevelopmentLevel,
}) {
  // Dark-theme tokens (Refs #2865, SPEC § Dark-theme Political section body
  // tokens). Every body row declares TextStyle.color explicitly via the
  // shared `_fgBodyStyle()` helper so the editorial-monocle dark theme owns
  // this surface and the section stops inheriting DefaultTextStyle /
  // Material bodyMedium colours. The helper is shared with the Tile
  // live-data rows (coordinates / terrain / civilian units) and the
  // sea-zone Political display-name row so every live-data body row stays
  // in sync with one token source. Region and Capital are always-exact
  // political intel, shown alongside Name / Owner regardless of fog.
  final bodyStyle = _fgBodyStyle();
  return _buildSection(
    l10n.provinceOverlay_sectionPolitical,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.provinceOverlay_name(name), style: bodyStyle),
        Text(l10n.provinceOverlay_owner(ownerName), style: bodyStyle),
        Text(l10n.provinceOverlay_region(regionLabel), style: bodyStyle),
        Text(
          isCapital
              ? l10n.provinceOverlay_capitalYes
              : l10n.provinceOverlay_capitalNo,
          style: bodyStyle,
        ),
        Text(
          l10n.provinceOverlay_townDevelopment(townDevelopmentLevel),
          style: bodyStyle,
        ),
      ],
    ),
  );
}

Province? _findProvince(Game game, String provinceId) =>
    game.worldState.allProvincesById[provinceId];
