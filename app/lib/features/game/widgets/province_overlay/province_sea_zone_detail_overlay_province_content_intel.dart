/// Tile-derived economic intel aggregation for province tab content.

part of 'province_sea_zone_detail_overlay.dart';

({
  Map<String, List<({String tileKey, String terrain, String impBase})>>
  byResImproved,
  Map<String, List<({String tileKey, String terrain})>> byResImprovable,
  List<String> resourceKeysSorted,
}) _aggregateProvinceTileIntel({
  required AppLocalizations l10n,
  required Game game,
  required RegionMapViewData region,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
  required List<String> tileKeys,
  required bool omniscientDetail,
}) {
  final resourceByTile = game.worldState.resourceByTileKey;
  final tileState = game.worldState.tileState;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};

  final byResImproved =
      <String, List<({String tileKey, String terrain, String impBase})>>{};
  final byResImprovable = <String, List<({String tileKey, String terrain})>>{};
  for (final tk in tileKeys) {
    final res = resourceByTile[tk];
    if (tryParseTileKey(tk) == null) continue;
    if (!omniscientDetail && !prospected.contains(tk)) continue;
    final imp = tileState.improvementLevel(tk);
    final visLevel = omniscientDetail
        ? VisibilityLevel.fullyVisible
        : playerView.visibilityForTile(tk);
    if (!omniscientDetail && visLevel == VisibilityLevel.unknown) continue;
    final visibleRes = omniscientDetail
        ? res
        : resourceIdVisibleInPlayerView(playerView, tk, res);
    if (visibleRes == null) continue;
    final terrain = _economicTerrainTitleForTile(region, tk) ?? '—';
    if (imp > 0) {
      final impBase = _improvementBaseNameForPlayer(
        l10n: l10n,
        visLevel: visLevel,
        rawResourceId: res,
        visibleResourceId: visibleRes,
      );
      byResImproved.putIfAbsent(visibleRes, () => []).add((
        tileKey: tk,
        terrain: terrain,
        impBase: impBase,
      ));
    } else if (res != null && imp < 4) {
      byResImprovable.putIfAbsent(visibleRes, () => []).add((
        tileKey: tk,
        terrain: terrain,
      ));
    }
  }

  for (final list in byResImproved.values) {
    list.sort((a, b) => a.tileKey.compareTo(b.tileKey));
  }
  for (final list in byResImprovable.values) {
    list.sort((a, b) => a.tileKey.compareTo(b.tileKey));
  }

  final resourceKeysSorted = {
    ...byResImproved.keys,
    ...byResImprovable.keys,
  }.toList()..sort();

  return (
    byResImproved: byResImproved,
    byResImprovable: byResImprovable,
    resourceKeysSorted: resourceKeysSorted,
  );
}
