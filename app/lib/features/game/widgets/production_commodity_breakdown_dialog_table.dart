/// Breakdown DataTable body for [ProductionCommodityBreakdownDialog].

part of 'production_commodity_breakdown_dialog.dart';

TextStyle _productionBreakdownHeadingStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
  return base.copyWith(
    color: EditorialMonoclePalette.muted,
    fontWeight: FontWeight.w600,
  );
}

TextStyle _productionBreakdownSectionHeaderStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
  return base.copyWith(
    color: EditorialMonoclePalette.muted,
    fontWeight: FontWeight.w600,
    fontFeatures: const <FontFeature>[FontFeature.enable('smcp')],
  );
}

TextStyle _productionBreakdownCommodityNameStyle(BuildContext context) {
  final TextStyle base =
      Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
  return base.copyWith(color: EditorialMonoclePalette.fg);
}

TextStyle _productionBreakdownDeltaCellStyle(BuildContext context, int value) {
  final TextStyle base =
      Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12);
  final Color? color = CtResourceCell.deltaColor(value);
  return base.copyWith(
    color: color ?? EditorialMonoclePalette.muted,
    fontFamilyFallback: const <String>['SF Mono', 'Menlo', 'monospace'],
    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
  );
}

Widget _productionBreakdownDeltaCell(BuildContext context, int value) {
  return Text(
    ProductionCommodityBreakdownDialog.formatDelta(value),
    maxLines: 1,
    style: _productionBreakdownDeltaCellStyle(context, value),
  );
}

Widget _productionBreakdownSectionHeaderCell(
  BuildContext context,
  String label,
) {
  return DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: EditorialMonoclePalette.accentDim,
          width: 1,
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.only(bottom: CtSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: _productionBreakdownSectionHeaderStyle(context),
      ),
    ),
  );
}

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
          return _buildDataTable(context, widths);
        },
      );
    }

    final Widget scrollableTable = SingleChildScrollView(
      controller: horizontalScrollController,
      scrollDirection: Axis.horizontal,
      child: _buildDataTable(context, null),
    );
    return Scrollbar(
      controller: horizontalScrollController,
      thumbVisibility: true,
      child: scrollableTable,
    );
  }

  static const double _tableColumnSpacing = 24;
  static const double _tableHorizontalMargin = 12;

  DataTable _buildDataTable(
    BuildContext context,
    List<double>? columnContentWidths,
  ) {
    final phaseColCount = EconomyPreviewStockpilePhase.values.length;
    final dividerColor =
        EditorialMonoclePalette.accentDim.withValues(alpha: 0.5);
    var commodityRowIndex = 0;

    Widget sizedCell(int columnIndex, Widget child) {
      if (columnContentWidths == null) return child;
      return SizedBox(width: columnContentWidths[columnIndex], child: child);
    }

    Widget sizedHeader(int columnIndex, Widget child) {
      if (columnContentWidths == null) return child;
      return SizedBox(
        key: ValueKey<String>('prodBreakdownHeaderCol_$columnIndex'),
        width: columnContentWidths[columnIndex],
        child: child,
      );
    }

    List<DataRow> rowsFor(List<Commodity> list) {
      return list.map((c) {
        final total = _rowTotal(c.id);
        final name = c.displayName ?? c.id;
        final rowShade = commodityRowIndex.isEven
            ? Colors.transparent
            : EditorialMonoclePalette.surface.withValues(alpha: 0.4);
        commodityRowIndex += 1;
        return DataRow(
          color: WidgetStatePropertyAll<Color?>(rowShade),
          cells: [
            DataCell(
              sizedCell(
                0,
                Row(
                  children: [
                    ResourceIcon(commodityId: c.id, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _productionBreakdownCommodityNameStyle(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...EconomyPreviewStockpilePhase.values.indexed.map(
              (entry) => DataCell(
                sizedCell(
                  1 + entry.$1,
                  _productionBreakdownDeltaCell(
                    context,
                    _phaseValue(c.id, entry.$2),
                  ),
                ),
              ),
            ),
            DataCell(
              sizedCell(
                phaseColCount + 1,
                _productionBreakdownDeltaCell(context, total),
              ),
            ),
          ],
        );
      }).toList();
    }

    return DataTable(
      headingRowHeight: 40,
      dataRowMinHeight: 32,
      dataRowMaxHeight: 48,
      dividerThickness: 1,
      columnSpacing: _tableColumnSpacing,
      horizontalMargin: _tableHorizontalMargin,
      headingRowColor: WidgetStatePropertyAll<Color?>(
        EditorialMonoclePalette.surfaceLite,
      ),
      border: TableBorder(
        horizontalInside: BorderSide(color: dividerColor),
      ),
      headingTextStyle: _productionBreakdownHeadingStyle(context),
      columns: [
        DataColumn(
          label: sizedHeader(0, Text(l10n.production_breakdown_commodity)),
        ),
        ...EconomyPreviewStockpilePhase.values.indexed.map(
          (entry) => DataColumn(
            label: sizedHeader(
              1 + entry.$1,
              Text(
                ProductionCommodityBreakdownDialog.phaseColumnLabel(
                  l10n,
                  entry.$2,
                ),
                softWrap: true,
              ),
            ),
          ),
        ),
        DataColumn(
          label: sizedHeader(
            phaseColCount + 1,
            Text(l10n.production_breakdown_total),
          ),
        ),
      ],
      rows: [
        for (final (label, commodities) in sections)
          if (commodities.isNotEmpty) ...[
            DataRow(
              cells: [
                DataCell(
                  sizedCell(
                    0,
                    _productionBreakdownSectionHeaderCell(context, label),
                  ),
                ),
                ...List<DataCell>.generate(
                  phaseColCount + 1,
                  (i) => DataCell(
                    sizedCell(1 + i, const SizedBox.shrink()),
                  ),
                ),
              ],
            ),
            ...rowsFor(commodities),
          ],
      ],
    );
  }
}
