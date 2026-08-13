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
import 'province_panel_e2e_expected_lines_ctx.dart';
import 'province_panel_e2e_expected_lines_labels.dart';

void appendProvincePanelPoliticalSection(
  List<String> out,
  ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  appendProvincePanelSection(out, 'Political', () {
    out.add('Name: ${ctx.province?.displayName ?? ctx.provinceId}');
    out.add('Owner: ${ownerDisplayName(ctx.game, ctx.province?.ownerId)}');
    out.add(l10n.provinceOverlay_region(regionLabel(l10n, ctx.regionId)));
    out.add(
      isCapitalProvince(ctx.game, ctx.provinceId)
          ? l10n.provinceOverlay_capitalYes
          : l10n.provinceOverlay_capitalNo,
    );
    out.add(
      l10n.provinceOverlay_townDevelopmentOfMax(
        ctx.province?.townDevelopmentLevel ?? kTownDevelopmentLevelMin,
        kTownDevelopmentLevelMax,
      ),
    );
    final level =
        ctx.province?.townDevelopmentLevel ?? kTownDevelopmentLevelMin;
    out.add(switch (level) {
      kTownDevelopmentLevelMax => l10n.provinceOverlay_townDevelopmentGistMax,
      2 => l10n.provinceOverlay_townDevelopmentGistBonusActiveNextAt4,
      3 => l10n.provinceOverlay_townDevelopmentGistNextAt4,
      _ => l10n.provinceOverlay_townDevelopmentGistNextAt2,
    });
  });
}

void appendProvincePanelTileSection(
  List<String> out,
  ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  appendProvincePanelSection(out, 'Tile', () {
    final parsed = tryParseTileKey(ctx.selectedTileKey);
    if (parsed == null || parsed.regionId != ctx.region.regionId) {
      out.add('—');
      return;
    }
    final x = parsed.x;
    final y = parsed.y;
    if (x < 0 || x >= ctx.region.width || y < 0 || y >= ctx.region.height) {
      out.add('—');
      return;
    }
    final cell = ctx.region.cellAt(x, y);
    if (cell.visibility == TileVisibility.unrevealed) {
      throw StateError(
        'E2E tile ${ctx.selectedTileKey} should be revealed for capital',
      );
    }
    final resourceRaw =
        ctx.resourceByTile[ctx.selectedTileKey] ?? cell.resourceId;
    final visLevel = ctx.playerView.visibilityForTile(ctx.selectedTileKey);
    final resourceVisible = resourceIdVisibleInPlayerView(
      ctx.playerView,
      ctx.selectedTileKey,
      resourceRaw,
    );
    final resourceLabel = resourceVisible ?? '—';
    final terrainStr = cell.terrainType != null
        ? terrainDisplayName(cell.terrainType!)
        : economicTerrainTitle(cell.terrainTypeId ?? '—');
    final prospectable = cell.terrainType != null
        ? isProspectableTerrain(cell.terrainType!)
        : isProspectableTerrainId(cell.terrainTypeId);
    final prospectedLabel = !prospectable
        ? '—'
        : (ctx.prospected.contains(ctx.selectedTileKey) ? 'yes' : 'no');
    final impLevel = ctx.tileState.improvementLevel(ctx.selectedTileKey);
    final roadLevel = cell.isSea
        ? null
        : ctx.tileState.roadLevel(ctx.selectedTileKey);
    final improvementLine = improvementLabelForTileDetail(
      impLevel: impLevel,
      visLevel: visLevel,
      rawResourceId: resourceRaw,
      visibleResourceId: resourceVisible,
    );

    out.add('Coordinates: ($x, $y)');
    out.add('Terrain: $terrainStr');
    final designationLine = tileDesignationLine(
      l10n: l10n,
      game: ctx.game,
      provinceId: ctx.provinceId,
      selectedTileKey: ctx.selectedTileKey,
    );
    if (designationLine != null) {
      out.add(designationLine);
    }
    out.add('Resource: ');
    out.add(resourceVisible ?? resourceLabel);
    out.add('Prospected: $prospectedLabel');
    out.add('Improvement: $improvementLine');
    if (roadLevel == null) {
      out.add('Road / railroad: —');
    } else {
      out.add(roadRailTransportLevelPrimaryLine(roadLevel));
      out.add(roadRailSupplementaryLabel(roadLevel));
      if (roadLevel == 1) {
        out.add(kRoadRailPrimitiveVersusRailGloss);
      }
    }
    out.add('Civilian units (province): ${ctx.visibleCivilianCount}');
  });
}
