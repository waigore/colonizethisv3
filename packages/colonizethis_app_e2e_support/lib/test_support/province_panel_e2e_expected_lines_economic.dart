part of 'province_panel_e2e_expected_lines.dart';

void _appendProvincePanelEconomicSection(
  List<String> out,
  _ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  _appendProvincePanelSection(out, 'Economic', () {
    out.add(l10n.provinceOverlay_extractionHeading);
    final tileMaps = ctx.tileMapByRegion;
    final topology = ctx.topology;
    final extraction =
        (tileMaps != null && tileMaps.isNotEmpty && topology != null)
        ? projectProvinceExtraction(
            game: ctx.game,
            tileMapByRegion: tileMaps,
            topology: topology,
            provinceId: ctx.provinceId,
          )
        : null;
    if (extraction == null || extraction.byCommodity.isEmpty) {
      out.add('—');
    } else {
      final parts = <String>[];
      for (final commodity in CommodityCatalog.all) {
        final totals = extraction.byCommodity[commodity.id];
        if (totals == null) continue;
        if (totals.effective == 0 && totals.full == 0) continue;
        final name = commodityDisplayName(l10n, commodity.id);
        var segment = totals.effective < totals.full
            ? l10n.provinceOverlay_extractionQuantityPartial(
                totals.effective,
                totals.full,
                name,
              )
            : l10n.provinceOverlay_extractionQuantity(totals.effective, name);
        if (commodity.id == CommodityCatalog.grain.id &&
            extraction.capitalGrainBonus > 0) {
          segment =
              '$segment${l10n.provinceOverlay_extractionCapitalGrainBonus(extraction.capitalGrainBonus)}';
        }
        parts.add(segment);
      }
      out.add(parts.isEmpty ? '—' : parts.join(', '));
    }

    out.add(l10n.provinceOverlay_availableHeading);
    // Available counts require tile maps; e2e snapshot path uses empty when
    // map data is not in the panel snapshot context — emit dash placeholder.
    out.add('—');

    var wroteAny = false;
    for (final resId in ctx.resourceKeysSorted) {
      final improved = ctx.byResImproved[resId] ?? const [];
      for (final row in improved) {
        out.add(resId);
        out.add(
          '${row.terrain}/$resId ${l10n.province_economic_withImprovement(row.impBase)}',
        );
        wroteAny = true;
      }
      final improvable = ctx.byResImprovable[resId] ?? const [];
      for (final row in improvable) {
        out.add(resId);
        out.add(
          '${row.terrain}/$resId ${l10n.province_economic_improvableSuffix}',
        );
        wroteAny = true;
      }
    }
    if (!wroteAny) {
      out.add('—');
    }
    out.add(l10n.provinceOverlay_townProductionHeading);
    out.add('—');
  });
}
