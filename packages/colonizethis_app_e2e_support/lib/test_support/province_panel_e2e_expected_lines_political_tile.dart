part of 'province_panel_e2e_expected_lines.dart';

void _appendProvincePanelPoliticalSection(
  List<String> out,
  _ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  _appendProvincePanelSection(out, 'Political', () {
    out.add('Name: ${ctx.province?.displayName ?? ctx.provinceId}');
    out.add('Owner: ${_ownerName(ctx.game, ctx.province?.ownerId)}');
    out.add(l10n.provinceOverlay_region(_regionLabel(l10n, ctx.regionId)));
    out.add(
      _isCapitalProvince(ctx.game, ctx.provinceId)
          ? l10n.provinceOverlay_capitalYes
          : l10n.provinceOverlay_capitalNo,
    );
    out.add(
      l10n.provinceOverlay_townDevelopment(
        ctx.province?.townDevelopmentLevel ?? kTownDevelopmentLevelMin,
      ),
    );
  });
}

void _appendProvincePanelTileSection(
  List<String> out,
  _ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  _appendProvincePanelSection(out, 'Tile', () {
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
        : _economicTerrainTitle(cell.terrainTypeId ?? '—');
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
    final improvementLine = _improvementLabelForTileDetail(
      impLevel: impLevel,
      visLevel: visLevel,
      rawResourceId: resourceRaw,
      visibleResourceId: resourceVisible,
    );

    out.add('Coordinates: ($x, $y)');
    out.add('Terrain: $terrainStr');
    final designationLine = _tileDesignationLine(
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
      out.add(_roadRailTransportLevelPrimaryLine(roadLevel));
      out.add(_roadRailSupplementaryLabel(roadLevel));
      if (roadLevel == 1) {
        out.add(_kRoadRailPrimitiveVersusRailGloss);
      }
    }
    out.add('Civilian units (province): ${ctx.visibleCivilianCount}');
  });
}
