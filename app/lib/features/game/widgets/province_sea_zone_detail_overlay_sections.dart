/// Shared section chrome and political helpers for
/// [ProvinceSeaZoneDetailOverlay].

part of 'province_sea_zone_detail_overlay.dart';

class _OverlayContent {
  _OverlayContent({
    required this.tabLabels,
    required this.tabViews,
    required this.sections,
  });
  final List<String> tabLabels;
  final List<Widget> tabViews;
  final Widget sections;
}

String? _economicTerrainTitleForTile(RegionMapViewData region, String tk) {
  final parsed = tryParseTileKey(tk);
  if (parsed == null || parsed.regionId != region.regionId) return null;
  final x = parsed.x;
  final y = parsed.y;
  if (x < 0 || y < 0 || x >= region.width || y >= region.height) {
    return null;
  }
  final cell = region.cellAt(x, y);
  // R13.4/R13.5 (#3573): known terrain types resolve through the canonical
  // title-cased display-name helper (never the raw enum `.name`); only the
  // unknown-id string fallback uses the underscore transform.
  final terrainType = cell.terrainType;
  if (terrainType != null) {
    return terrainDisplayName(terrainType);
  }
  final raw = cell.terrainTypeId ?? '—';
  return _economicTerrainTitle(raw);
}

/// Title-cases an unknown terrain-id fallback string. Splits on underscores
/// **and** camelCase boundaries so a multi-word id such as `hardwoodForest`
/// renders as `Hardwood Forest` — never `HardwoodForest` (#3573 R13.5). Known
/// terrain enums bypass this and use [terrainDisplayName] directly.
String _economicTerrainTitle(String raw) {
  if (raw.isEmpty || raw == '—') return raw;
  final spaced = raw
      .replaceAll('_', ' ')
      .replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (_) => ' ');
  return spaced
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

Widget _economicHoverRow({
  required String tileKey,
  required void Function(String?)? onHighlightTile,
  required Widget child,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => onHighlightTile?.call(tileKey),
    onExit: (_) => onHighlightTile?.call(null),
    child: Padding(
      padding: const EdgeInsets.only(left: CtSpacing.m / 2, top: CtSpacing.xs),
      child: child,
    ),
  );
}

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

String _improvementNameForResource(AppLocalizations l10n, String? resourceId) {
  if (resourceId == null) return l10n.provinceOverlay_improvementGeneric;
  switch (resourceId) {
    case 'grain':
      return l10n.provinceOverlay_improvementFarm;
    case 'meat':
    case 'horses':
      return l10n.provinceOverlay_improvementRanch;
    case 'wool':
      return l10n.provinceOverlay_improvementPasture;
    case 'timber':
      return l10n.provinceOverlay_improvementLumberCamp;
    case 'sugarCane':
    case 'tobacco':
    case 'cotton':
    case 'spices':
      return l10n.provinceOverlay_improvementPlantation;
    case 'furs':
      return l10n.provinceOverlay_improvementFurPost;
    case 'iron':
    case 'copper':
    case 'tin':
    case 'coal':
    case 'silver':
    case 'gold':
    case 'gems':
    case 'diamonds':
      return l10n.provinceOverlay_improvementMine;
    default:
      return l10n.provinceOverlay_improvementGeneric;
  }
}

/// Test-only accessor for the resource → improvement-type name mapping
/// (Refs #2865; SPEC § Province overlay content `Tile` improvement label).
@visibleForTesting
String provinceOverlayImprovementNameForResource(
  AppLocalizations l10n,
  String? resourceId,
) =>
    _improvementNameForResource(l10n, resourceId);

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

String _improvementBaseNameForPlayer({
  required AppLocalizations l10n,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (visibleResourceId != null) {
    return _improvementNameForResource(l10n, visibleResourceId);
  }
  if (rawResourceId != null &&
      kProspectRequiredResourceIds.contains(rawResourceId)) {
    return l10n.provinceOverlay_improvementMine;
  }
  if (rawResourceId != null) {
    return _improvementNameForResource(l10n, rawResourceId);
  }
  return l10n.provinceOverlay_improvementGeneric;
}

String _improvementLabelForTileDetail({
  required AppLocalizations l10n,
  required int impLevel,
  required VisibilityLevel visLevel,
  required String? rawResourceId,
  required String? visibleResourceId,
}) {
  if (impLevel <= 0) {
    return '—';
  }
  final base = _improvementBaseNameForPlayer(
    l10n: l10n,
    visLevel: visLevel,
    rawResourceId: rawResourceId,
    visibleResourceId: visibleResourceId,
  );
  return '$base L$impLevel';
}

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

// Section header band shared by every province / sea-zone tab body and the
// wide-layout `sections` column. Renders the canonical CtSectionLabel
// (Refs #2859 R9) so the title inherits the dark editorial-monocle
// small-caps + `--accent-dim` underline contract; see
// SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme section labels.
//
// When [title] is empty (e.g. the narrow-layout obfuscated tab body that
// already has its label rendered by `CtTabStrip`), the header band is
// omitted entirely so the obfuscated body does not paint an extra
// underline beneath the tab strip.
Widget _buildSection(String title, Widget child) {
  return Padding(
    padding: const EdgeInsets.only(bottom: CtSpacing.ml),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title.isNotEmpty) ...[
          CtSectionLabel(title),
          SizedBox(height: CtSpacing.m / 2),
        ],
        child,
      ],
    ),
  );
}

class _ObfuscatedSection extends StatelessWidget {
  const _ObfuscatedSection({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return _buildSection('', _obfuscatedBodyText(l10n.provinceOverlay_unknown));
  }
}
