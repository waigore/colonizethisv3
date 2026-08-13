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

void appendProvincePanelEconomicSection(
  List<String> out,
  ProvincePanelWideExpectedCtx ctx,
  AppLocalizations l10n,
) {
  appendProvincePanelSection(out, 'Economic', () {
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
