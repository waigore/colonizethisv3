/// Breakdown DataTable body for [ProductionCommodityBreakdownDialog].

part of 'production_commodity_breakdown_dialog.dart';

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

  static const double _tableColumnSpacing = 24;
  static const double _tableHorizontalMargin = 12;

  int _phaseValue(String commodityId, EconomyPreviewStockpilePhase phase) {
    return phaseDeltas[phase]?[commodityId] ?? 0;
  }

  int _rowTotal(String commodityId) {
    var t = 0;
    for (final p in EconomyPreviewStockpilePhase.values) {
      t += _phaseValue(commodityId, p);
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
            columnSpacing: _tableColumnSpacing,
            horizontalMargin: _tableHorizontalMargin,
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
