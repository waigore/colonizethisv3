// coverage:ignore-file
// E2E test fixture; exercised only by integration_test scenarios (which do not
// run in `flutter test test/`). Pulled into the test isolate's import graph by
// `app/integration_test/e2e_test_shared_panel_text_match.dart` (Refs #2336);
// excluded from the app coverage gate using the same convention as
// `app/lib/widgetbook/catalog*.dart`.
// Expected plain-text lines for ProvinceSeaZoneDetailOverlay wide layout (scroll column).
// Mirrors app/lib/features/game/widgets/province_overlay/province_sea_zone_detail_overlay.dart for e2e.
// If drift fails tests, align this file with the overlay widget.

import 'package:colonizethis_data/colonizethis_data.dart'
    show
        CommodityCatalog,
        MapTopology,
        TileMapResult,
        isMilitaryUnit,
        terrainDisplayName;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e_last_panel_snapshot.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_labels.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay/province_panel_pending_orders.dart';
import 'package:colonizethis_app/widgets/commodity_display_name.dart';
import 'province_panel_e2e_expected_lines_labels.dart';
import 'province_panel_e2e_expected_lines_road.dart';

export 'province_panel_e2e_expected_lines_road.dart';

class ProvincePanelWideExpectedCtx {
  ProvincePanelWideExpectedCtx({
    required this.game,
    required this.region,
    required this.provinceId,
    required this.humanPlayerId,
    required this.playerView,
    required this.draftOrders,
    required this.selectedTileKey,
    required this.regionId,
    required this.province,
    required this.military,
    required this.civilian,
    required this.visibleCivilianCount,
    required this.fleetsInPort,
    required this.resourceByTile,
    required this.tileState,
    required this.prospected,
    required this.byResImproved,
    required this.byResImprovable,
    required this.resourceKeysSorted,
    this.topology,
    this.tileMapByRegion,
  });

  final Game game;
  final RegionMapViewData region;
  final String provinceId;
  final String humanPlayerId;
  final PlayerView playerView;
  final Orders draftOrders;
  final String selectedTileKey;
  final String regionId;
  final Province? province;
  final List<Unit> military;
  final List<Unit> civilian;
  final int visibleCivilianCount;
  final List<Fleet> fleetsInPort;
  final Map<String, String> resourceByTile;
  final TileMapState tileState;
  final Set<String> prospected;
  final MapTopology? topology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Map<String, List<({String tileKey, String terrain, String impBase})>>
  byResImproved;
  final Map<String, List<({String tileKey, String terrain})>> byResImprovable;
  final List<String> resourceKeysSorted;
}

ProvincePanelWideExpectedCtx buildProvincePanelWideExpectedCtx(
  CtE2eLastPanelSnapshot snap,
) {
  final game = snap.game;
  final region = snap.region;
  final provinceId = snap.displayId;
  final humanPlayerId = snap.humanPlayerId;
  final playerView = snap.playerView;
  final draftOrders = snap.draftOrders;
  final selectedTileKey = snap.selectedTileKey;

  final regionId = prefixedIdRegionSegment(provinceId) ?? region.regionId;
  final localProvinceId = prefixedIdLocalSegment(provinceId);
  final isFullyUnrevealed =
      region.regionId == regionId &&
      !region.cells.any(
        (c) =>
            c.regionCellId == localProvinceId &&
            c.visibility != TileVisibility.unrevealed,
      );
  if (isFullyUnrevealed) {
    throw StateError(
      'E2E expected a revealed capital province; got fully unrevealed $provinceId',
    );
  }

  final province = findProvince(game, provinceId);
  final regionData = provinceId.startsWith('newWorld')
      ? game.worldState.newWorld
      : game.worldState.oldWorld;
  final units = regionData.units
      .where((u) => u.locationProvinceId == provinceId)
      .toList();
  final military = units.where((u) => isMilitaryUnit(u.type)).toList();
  final civilian = units.where((u) => !isMilitaryUnit(u.type)).toList();
  final visibleCivilianCount = civilian
      .where(
        (u) => foreignCivilianVisibleToPlayer(
          unit: u,
          viewerPlayerId: humanPlayerId,
          view: playerView,
        ),
      )
      .length;
  final fleetsInPort = fleetsInPortAtProvince(game.worldState, provinceId);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[provinceId] ??
      [];
  final resourceByTile = game.worldState.resourceByTileKey;
  final tileState = game.worldState.tileState;
  final prospected = game.worldState.playerProspectedTiles[humanPlayerId] ?? {};

  final byResImproved =
      <String, List<({String tileKey, String terrain, String impBase})>>{};
  final byResImprovable = <String, List<({String tileKey, String terrain})>>{};

  for (final tk in tileKeys) {
    final res = resourceByTile[tk];
    if (tryParseTileKey(tk) == null) continue;
    if (!prospected.contains(tk)) continue;
    final imp = tileState.improvementLevel(tk);
    final visLevel = playerView.visibilityForTile(tk);
    final visibleRes = resourceIdVisibleInPlayerView(playerView, tk, res);

    if (visibleRes == null) continue;

    final terrain = economicTerrainTitleForTile(region, tk) ?? '—';
    if (imp > 0) {
      final impBase = improvementBaseNameForPlayer(
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

  return ProvincePanelWideExpectedCtx(
    game: game,
    region: region,
    provinceId: provinceId,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    draftOrders: draftOrders,
    selectedTileKey: selectedTileKey,
    regionId: regionId,
    province: province,
    military: military,
    civilian: civilian,
    visibleCivilianCount: visibleCivilianCount,
    fleetsInPort: fleetsInPort,
    resourceByTile: resourceByTile,
    tileState: tileState,
    prospected: prospected,
    byResImproved: byResImproved,
    byResImprovable: byResImprovable,
    resourceKeysSorted: resourceKeysSorted,
    topology: snap.topology,
    tileMapByRegion: snap.tileMapByRegion,
  );
}

void appendProvincePanelSection(
  List<String> out,
  String title,
  void Function() body,
) {
  // Section headers render via CtSectionLabel under the dark editorial-
  // monocle theme (Refs #2865 S4), which upper-cases the label per SPEC
  // SPEC/ui/province-sea-zone-detail-overlay.md § Dark-theme section
  // labels. The expected text mirror must therefore upper-case the title
  // before adding it to the snapshot output.
  out.add(title.toUpperCase());
  body();
}
