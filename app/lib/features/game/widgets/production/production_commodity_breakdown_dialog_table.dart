// Breakdown DataTable body for [ProductionCommodityBreakdownDialog].

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'production_commodity_breakdown_dialog_layout.dart';
import 'production_commodity_breakdown_dialog_table_data.dart';

/// Viewport-adaptive breakdown table for the production commodity dialog.
class ProductionBreakdownTableBody extends StatelessWidget {
  const ProductionBreakdownTableBody({
    super.key,
    required this.l10n,
    required this.sections,
    required this.phaseDeltas,
    required this.isWideViewport,
    required this.horizontalScrollController,
  });

  final AppLocalizations l10n;
  final List<(String, List<Commodity>)> sections;
  final Map<EconomyPreviewStockpilePhase, Map<String, int>> phaseDeltas;
  final bool isWideViewport;
  final ScrollController horizontalScrollController;

  static const double tableColumnSpacing = 24;
  static const double tableHorizontalMargin = 12;

  int phaseValue(String commodityId, EconomyPreviewStockpilePhase phase) {
    return phaseDeltas[phase]?[commodityId] ?? 0;
  }

  int rowTotal(String commodityId) {
    var t = 0;
    for (final p in EconomyPreviewStockpilePhase.values) {
      t += phaseValue(commodityId, p);
    }
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final phaseColCount = EconomyPreviewStockpilePhase.values.length;

    if (isWideViewport) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final widths = productionBreakdownWideColumnContentWidths(
            availableWidth: constraints.maxWidth,
            phaseColumnCount: phaseColCount,
            columnSpacing: tableColumnSpacing,
            horizontalMargin: tableHorizontalMargin,
          );
          return buildProductionBreakdownDataTable(context, widths);
        },
      );
    }

    final Widget scrollableTable = SingleChildScrollView(
      controller: horizontalScrollController,
      scrollDirection: Axis.horizontal,
      child: buildProductionBreakdownDataTable(context, null),
    );
    return Scrollbar(
      controller: horizontalScrollController,
      thumbVisibility: true,
      child: scrollableTable,
    );
  }
}
